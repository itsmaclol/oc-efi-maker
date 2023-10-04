amd1516_desktop_config_setup(){
    info "Configuring config.plist for AMD 15h/16h desktop..."
    set_plist Kernel.Emulate.DummyPowerManagement bool True
    amdkernelpatches
    set_plist Kernel.Quirks.PanicNoKextDump bool True
    set_plist Kernel.Quirks.PowerTimeoutKernelPanic bool True
    set_plist Kernel.Quirks.ProvideCurrentCpuInfo bool True
    case $os_choice in
        4|5 ) 
            set_plist Kernel.Quirks.XhciPortLimit bool False
        ;;
    esac
    
    #gpu args and what not go here
    platforminfo(){
        echo "################################################################"
        echo "Now, we need to pick an SMBIOS."
        echo "Pick the closest one to your hardware"
        echo "1. MacPro7,1 - AMD Polaris and newer"
        echo "2. iMacPro1,1 - NVIDIA Maxwell and Pascal or AMD Polaris and newer"
        echo "3. iMac14,2 - NVIDIA Maxwell and Pascal"
        echo "4. MacPro6,1 - AMD GCN GPUs (supported HD and R5/R7/R9 series)"
        echo "################################################################"
        read -r -p "Choose a number between 1-4: " smbios_choice
        case $smbios_choice in
            1 )
                case $os_choice in
                    5 )
                        error "This SMBIOS is only supported in macOS Catalina and higher! Please pick another."
                        platforminfo
                    ;;
                    * )
                        smbiosname=MacPro7,1
                    ;;
                esac
            ;;
            2 )
                smbiosname=iMacPro1,1
            ;;
            3 )
                smbiosname=iMac14,2
            ;;
            4 )
                smbiosname=MacPro6,1
            ;;
            * )
                error "Invalid Choice"
                platforminfo
            ;;
        esac
    }
    platforminfo
    macserial
    case $os_choice in
        4 )
            set_plist UEFI.APFS.MinVersion int 1412101001000000
            set_plist UEFI.APFS.MinDate int 20200306
        ;;
        5 )
            set_plist UEFI.APFS.MinVersion int 945275007000000
            set_plist UEFI.APFS.MinDate int 20190820
        ;;
    esac
    hpdesktop(){
        echo "################################################################"
        echo "Do you have a HP System?"
        echo "################################################################"
        read -r -p "y/n: " hpdesktop_choice
        case $hpdesktop_choice in
            Y|y|YES|Yes|yes )
                set_plist UEFI.Quirks.UnblockFsConnect bool True
            ;;
            n|N|NO|No|no )
               echo "" > /dev/null
            ;;
            * )
                error "Invalid Choice"
               hpdesktop
            esac
    }
    hpdesktop
    warning "Please disable the following options in the BIOS.\nFast Boot\nSecure Boot\nSerial/COM Port\nParallel Port\nVT-d\nCompatibility Support Module (CSM)\nIOMMU"
    warning "Please enable the following options in the BIOS.\nAbove 4G Decoding\nEHCI/XHCI Hand-off\nOS type: Windows 8.1/10 UEFI Mode (might be Other OS)\nSATA Mode: AHCI"
}

amd1719_desktop_config_setup(){
    info "Configuring config.plist for AMD 17h/19h desktop..."
    trx40(){
        echo "################################################################"
        echo "Do you have a TRx40 system?"
        echo "################################################################"
        read -r -p "y/n: " trx40_choice
        case $trx40_choice in
            Y|y|YES|Yes|yes )
                echo "" > /dev/null
            ;;
            n|N|NO|No|no )
                set_plist Booter.Quirks.DevirtualizeMmio bool True
            ;;
            * )
                error "Invalid Choice"
                trx40
            esac
    }
    trx40
    set_plist Booter.Quirks.RebuildAppleMemoryMap bool True
    resizegpu(){
        echo "################################################################"
        echo "Does your GPU support Resizeable BAR?"
        echo "################################################################"
        read -r -p "y/n: " resizegpu_choice
        case $resizegpu_choice in
            Y|y|YES|Yes|yes )
                set_plist Booter.Quirks.ResizeAppleGpuBars int 1
            ;;
            n|N|NO|No|no )
                set_plist Booter.Quirks.ResizeAppleGpuBars int -1
            ;;
            * )
                error "Invalid Choice"
                resizegpu
            esac
    }
    resizegpu
    set_plist Booter.Quirks.SetupVirtualMap bool True
    set_plist Booter.Quirks.SyncRuntimePermissions bool True
    set_plist Kernel.Emulate.DummyPowerManagement bool True
    amdkernelpatches
    set_plist Kernel.Quirks.PanicNoKextDump bool True
    set_plist Kernel.Quirks.PowerTimeoutKernelPanic bool True
    set_plist Kernel.Quirks.ProvideCurrentCpuInfo bool True
    case $os_choice in
        4|5 ) 
            set_plist Kernel.Quirks.XhciPortLimit bool False
        ;;
    esac
    
    # gpu args go here
    platforminfo(){
        echo "################################################################"
        echo "Now, we need to pick an SMBIOS."
        echo "Pick the closest one to your hardware"
        echo "1. MacPro7,1 - AMD Polaris and newer"
        echo "2. iMacPro1,1 - NVIDIA Maxwell and Pascal or AMD Polaris and newer"
        echo "3. iMac14,2 - NVIDIA Maxwell and Pascal"
        echo "4. MacPro6,1 - AMD GCN GPUs (supported HD and R5/R7/R9 series)"
        echo "################################################################"
        read -r -p "Choose a number between 1-4: " smbios_choice
        case $smbios_choice in
            1 )
                case $os_choice in
                    5 )
                        error "This SMBIOS is only supported in macOS Catalina and higher! Please pick another."
                        platforminfo
                    ;;
                    * )
                        smbiosname=MacPro7,1
                    ;;
                esac
            ;;
            2 )
               smbiosname=iMacPro1,1
            ;;
            3 )
                smbiosname=iMac14,2
            ;;
            4 )
                smbiosname=MacPro6,1
            ;;
            * )
                error "Invalid Choice"
                platforminfo
            ;;
        esac
    }
    platforminfo
    macserial
    case $os_choice in
        4 )
            set_plist UEFI.APFS.MinVersion int 1412101001000000
            set_plist UEFI.APFS.MinDate int 20200306
        ;;
        5 )
            set_plist UEFI.APFS.MinVersion int 945275007000000
            set_plist UEFI.APFS.MinDate int 20190820
        ;;
    esac
    hpdesktop(){
        echo "################################################################"
        echo "Do you have a HP System?"
        echo "################################################################"
        read -r -p "y/n: " hpdesktop_choice
        case $hpdesktop_choice in
            Y|y|YES|Yes|yes )
                set_plist UEFI.Quirks.UnblockFsConnect bool True
            ;;
            n|N|NO|No|no )
                echo "" > /dev/null
            ;;            * )
                error "Invalid Choice"
                hpdesktop
            esac
    }
    hpdesktop
    warning "Please disable the following options in the BIOS.\nFast Boot\nSecure Boot\nSerial/COM Port\nParallel Port\nVT-d\nCompatibility Support Module (CSM)\nIOMMU"
    warning "Please enable the following options in the BIOS.\nAbove 4G Decoding\nEHCI/XHCI Hand-off\nOS type: Windows 8.1/10 UEFI Mode (might be Other OS)\nSATA Mode: AHCI"
}