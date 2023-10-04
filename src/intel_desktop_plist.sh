haswell_broadwell_desktop_config_setup() {
    info "Configuring config.plist for Haswell/Broadwell Desktop..."
    add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0)" dict
    add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).AAPL,ig-platform-id" data
    aapl_plat_id() {
        echo "################################################################"
        echo "Now, we need to pick a AAPL,ig-platform-id."
        echo "Pick the one closest to your hardware."
        echo "1. 0300220D - Used when the Desktop Haswell iGPU is used to drive a display"
        echo "2. 04001204 - Used when the Desktop Haswell iGPU is only used for computing tasks and doesn't drive a display"
        echo "3. 07002216 - Used when the Desktop Broadwell iGPU is used to drive a display"
        echo "################################################################"
        read -r -p "Pick a number 1-3: " aapl_plat_id
        case $aapl_plat_id in
            1 )
                plat_id="0300220D"
            ;;
            2 )
                plat_id="04001204"
            ;;
            3 )
                plat_id="07002216"
            ;;
            * )
                error "Invalid Choice"
                aapl_plat_id
            ;;
        esac
    }
    aapl_plat_id
    set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).AAPL,ig-platform-id" data "$plat_id"
    hd4400() {
        echo "################################################################"
        echo "Do you have a HD4400?"
        echo "################################################################"
        read -r -p "y/n: " hd4400_choice
        case $hd4400_choice in
            y|Y|YES|Yes|yes )   
                add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).device-id" data
                set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).device-id" data 12040000
            ;;
            n|N|NO|No|no )
                echo "" > /dev/null
            ;;
            * )
                error "Invalid Choice"
                hd4400
            ;;
        esac
    }
    hd4400
    dmvt() {
        echo "################################################################"
        echo "Can you put your DMVT iGPU allocated memory to more than 64mb in bios?"
        echo "################################################################"
        read -r -p "y/n: " dmvt_choice
        case $dmvt_choice in
            y|Y|YES|Yes|yes )
                echo "" > /dev/null
            ;;
            n|N|NO|No|no )
                add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-patch-enable" data
                add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-stolenmem" data
                add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-fbmem" data
                set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-patch-enable" data 01000000
                set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-stolenmem" data 00003001
                set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-fbmem" data 00009000
            ;;
            * )
                error "Invalid Choice"
                dmvt
            ;;
        esac
    }
    dmvt
    set_plist Kernel.Quirks.AppleCpuPmCfgLock bool True
    set_plist Kernel.Quirks.AppleXcpmCfgLock bool True
    hpdesktop() {
        echo "################################################################"
        echo "Do you have a HP System?"
        echo "################################################################"
        read -r -p "y/n: " hpdesktop_choice
        case $hpdesktop_choice in
            Y|y|YES|Yes|yes )
                set_plist Kernel.Quirks.LapicKernelPanic bool True
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
    vtd() {
        echo "################################################################"
        echo "Is VT-D enabled in BIOS?"
        echo "################################################################"
        read -r -p "y/n: " vtd_choice
        case $vtd_choice in
            y|Y|YES|yes|Yes )
                set_plist Kernel.Quirks.DisableIoMapper bool True
            ;;
            N|n|NO|No|no )
                echo "" > /dev/null
            ;;
            * )
                error "Invalid Choice"
                vtd
        esac
    }
    vtd
    set_plist Kernel.Quirks.PanicNoKextDump bool True
    set_plist Kernel.Quirks.PowerTimeoutKernelPanic bool True
    case $os_choice in
        4|5 ) 
             set_plist Kernel.Quirks.XhciPortLimit False
        ;;
    esac
    
    #gumi note: add gpu-specific boot args later
    platforminfo(){
        echo "################################################################"
        echo "Now, we need to pick an SMBIOS."
        echo "Pick the closest one to your hardware"
        echo "1. iMac14,4 - Haswell with only iGPU"
        echo "2. iMac15,1 - Haswell with dGPU"
        echo "3. iMac16,2 - Broadwell with only iGPU"
        echo "4. iMac17,1 - Broadwell with dGPU"
        echo "################################################################"
        read -r -p "Pick a number 1-4: " smbios_choice
        case $smbios_choice in
             1 )
               case $os_choice in
                    1|2 )
                         error "This SMBIOS is not supported in macOS Monterey or higher! Please pick another."
                         platforminfo
                    ;;
                    * )
                       smbiosname="iMac14,4"
                    ;;
                esac
            ;;
            2 )
                case $os_choice in
                        1|2 )
                            error "This SMBIOS is not supported in macOS Monterey or higher! Please pick another."
                            platforminfo
                        ;;
                        * )
                            smbiosname="iMac15,1"
                        ;;
                esac
            ;;
            3 )
               smbiosname="iMac16,2"
            ;;
            4 )
               smbiosname="iMac17,1"
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
    set_plist UEFI.Quirks.IgnoreInvalidFlexRatio bool True
    case $hpdesktop_choice in
        y|Yes|YES|Y|yes )
            set_plist UEFI.Quirks.UnblockFsConnect bool True
        ;;
    esac
    warning "Please disable the following options in the BIOS.\nFast Boot\nSecure Boot\nSerial/COM Port\nParallel Port\nVT-d\n Compatibility Support Module (CSM)\nThunderbolt (For intial install)\nIntel SGX\nIntel Platform Trust"
    warning "Please enable the following options in the BIOS.\nVT-x\nAbove 4G Decoding\nHyper-Threading\nExecute Disable Bit\nEHCI-XHCI Hand-off\n OS Type (Other OS) Windows 8.1/10 UEFI Mode\nDVMT Pre-Allocated(iGPU Memory) 64MB or higher\nSATA Mode: AHCI\nCFG Lock"
}

skylake_desktop_config_setup() {
    info "Configuring config.plist for Skylake desktop..."
    add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0)" dict
    add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).AAPL,ig-platform-id" data
    aapl_plat_id() {
        echo "################################################################"
        echo "Now, we need to pick a AAPL,ig-platform-id."
        echo "Pick the one closest to your hardware."
        echo "1. 00001219 - Used when the Desktop Skylake iGPU is used to drive a display"
        echo "2. 01001219 - Used when the Desktop Skylake iGPU is only used for computing tasks and doesn't drive a display"
        echo "################################################################"
        read -r -p "Pick a int 1-2: " aapl_plat_id
        case $aapl_plat_id in
            1 )
                plat_id="00001219"
            ;;
            2 )
                plat_id="01001219"
            ;;
            * )
                error "Invalid Choice"
                aapl_plat_id
            ;;
        esac
    }
    ventura_aapl_plat_id() {
        echo "################################################################"
        echo "Now, we need to pick a AAPL,ig-platform-id."
        echo "Since this is a skylake machine and you want to install macOS Ventura on it, we are going to be picking a kaby lake ig-platform-id."
        echo "1. 00001259 - Used when the Desktop Kaby Lake iGPU is used to drive a display"
        echo "2. 03001259 - Used when the Desktop Kaby Lake iGPU is only used for computing tasks and doesn't drive a display"
        echo "################################################################"
        read -r -p "Pick a number 1-2: " ventura_aapl_plat_id
        case $ventura_aapl_plat_id in
            1 )
                plat_id="00001259"
            ;;
            2 )
                plat_id="03001259"
            ;;
            * )
                error "Invalid Choice"
                ventura_aapl_plat_id
            ;;
        esac
    }
    P530() {
        echo "################################################################"
        echo "Do you have a Intel HD P530?"
        echo "################################################################"
        read -r -p "y/n: " p530_choice
        case $p530_choice in
            y|Y|YES|Yes|yes )
                add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).device-id" data
                set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).device-id" data 1B190000
            ;;
            n|N|NO|No|no )
                echo "" > /dev/null
            ;;
            * )
                error "Invalid Choice"
                P530
            ;;
        esac
    }
    case $os_choice in
        1 )
            ventura_aapl_plat_id
        ;;
        2|3|4|5 )
            aapl_plat_id
            P530
        ;;
    esac
    set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).AAPL,ig-platform-id" data "$plat_id"
    dmvt() {
        echo "################################################################"
        echo "Can you put your DMVT iGPU allocated memory to more than 64mb in bios?"
        echo "################################################################"
        read -r -p "y/n: " dmvt_choice
        case $dmvt_choice in
            y|Y|YES|Yes|yes )
                echo "" > /dev/null
            ;;
            n|N|NO|No|no )
                add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-patch-enable" data
                add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-stolenmem" data
                add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-fbmem" data
                set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-patch-enable" data 01000000
                set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-stolenmem" data 00003001
                set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-fbmem" data 00009000
            ;;
            * )
                error "Invalid Choice"
                dmvt
            ;;
        esac
    }
    dmvt
    cfglock() {
        echo "################################################################"
        echo "Is CFG-Lock enabled in BIOS?"
        echo "################################################################"
        read -r -p "y/n: " cfg_choice
        case $cfg_choice in
            y|Y|YES|yes|Yes )
                set_plist Kernel.Quirks.AppleXcpmCfgLock bool True
            ;;
            N|n|NO|No|no )
                echo "" > /dev/null
            ;;
            * )
                error "Invalid Choice"
                cfglock
            ;;
        esac
    }
    cfglock
    vtd() {
        echo "################################################################"
        echo "Is VT-D enabled in BIOS?"
        echo "################################################################"
        read -r -p "y/n: " vtd_choice
        case $vtd_choice in
            y|Y|YES|yes|Yes )
                set_plist Kernel.Quirks.DisableIoMapper bool True
            ;;
            N|n|NO|No|no )
                echo "" > /dev/null
            ;;
            * )
                error "Invalid Choice"
                vtd
            ;;
        esac
    }
    vtd
    hpdesktop() {
        echo "################################################################"
        echo "Do you have a HP System?"
        echo "################################################################"
        read -r -p "y/n: " hpdesktop_choice
        case $hpdesktop_choice in
            Y|y|YES|Yes|yes )
                set_plist Kernel.Quirks.LapicKernelPanic bool True
            ;;
            n|N|NO|No|no )
                echo "" > /dev/null
            ;;
            * )
                error "Invalid Choice"
                hpdesktop
            ;;
        esac
    }
    hpdesktop
    set_plist Kernel.Quirks.PanicNoKextDump bool True
    set_plist Kernel.Quirks.PowerTimeoutKernelPanic bool True
    case $os_choice in
        4|5 )
            set_plist Kernel.Quirks.XhciPortLimit False
        ;;
    esac
    
    ventura_platforminfo() {
        echo "################################################################"
        echo "Now, we need to pick an SMBIOS."
        echo "Pick the closest one to your hardware."
        echo "1. iMac18,1 - Kaby Lake with only iGPU"
        echo "2. iMac18,3 - Kaby Lake with dGPU"
        echo "################################################################"
        read -r -p "Pick a number 1-2: " ventura_smbios_choice
        case $ventura_smbios_choice in
            1 )
                smbiosname="iMac18,1"
            ;;
            2 )
                smbiosname="iMac18,3"
            ;;
            * )
                error "Invalid Choice"
                ventura_platforminfo
            ;;
        esac
    }
    case $os_choice in
        1 )
            ventura_platforminfo
        ;;
        2|3|4|5 )
            smbiosname="iMac17,1"
        ;;
    esac
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
    set_plist UEFI.Quirks.IgnoreInvalidFlexRatio bool True
    case $hpdesktop_choice in
        y|Yes|YES|Y|yes )
            set_plist UEFI.Quirks.UnblockFsConnect bool True
        ;;
    esac
    warning "Please disable the following options in the BIOS.\nFast Boot\nSecure Boot\nSerial/COM Port\nParallel Port\nVT-d\n Compatibility Support Module (CSM)\nThunderbolt (For intial install)\nIntel SGX\nIntel Platform Trust"
    warning "Please enable the following options in the BIOS.\nVT-x\nAbove 4G Decoding\nHyper-Threading\nExecute Disable Bit\nEHCI-XHCI Hand-off\n OS Type (Other OS) Windows 8.1/10 UEFI Mode\nDVMT Pre-Allocated(iGPU Memory) 64MB or higher\nSATA Mode: AHCI\nCFG Lock"
}

kabylake_desktop_config_setup(){
    info "Configuring config.plist for Kaby Lake desktop..."
    add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0)" dict
    add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).AAPL,ig-platform-id" data
    aapl_plat_id() {
        echo "################################################################"
        echo "Now, we need to pick a AAPL,ig-platform-id."
        echo "Pick the one closest to your hardware."
        echo "1. 00001219 - Used when the Desktop Kaby Lake iGPU is used to drive a display"
        echo "2. 03001259 - Used when the Desktop Kaby Lake iGPU is only used for computing tasks and doesn't drive a display"
        echo "################################################################"
        read -r -p "Pick a number 1-2: " aapl_plat_id
        case $aapl_plat_id in
            1 )
                plat_id="00001219"
            ;;
            2 )
                plat_id="03001259"
            ;;
            * )
                error "Invalid Choice"
                aapl_plat_id
            ;;
        esac
    }
    aapl_plat_id
    set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).AAPL,ig-platform-id" data "$plat_id"
    dmvt() {
        echo "################################################################"
        echo "Can you put your DMVT iGPU allocated memory to more than 64mb in bios?"
        echo "################################################################"
        read -r -p "y/n: " dmvt_choice
        case $dmvt_choice in
            y|Y|YES|Yes|yes )
                echo "" > /dev/null
            ;;
            n|N|NO|No|no )
                add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-patch-enable" data
                add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-stolenmem" data
                set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-patch-enable" data 01000000
                set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-stolenmem" data 00003001
            ;;
            * )
                error "Invalid Choice"
                dmvt
            ;;
        esac
    }
    dmvt
    cfglock(){
        echo "################################################################"
        echo "Is CFG-Lock enabled in BIOS?"
        echo "################################################################"
        read -r -p "y/n: " cfg_choice
        case $cfg_choice in
            y|Y|YES|yes|Yes )
                set_plist Kernel.Quirks.AppleXcpmCfgLock bool True
            ;;
            N|n|NO|No|no )
                echo "" > /dev/null
            ;;
            * )
                error "Invalid Choice"
                cfglock
        esac
    }
    cfglock
    vtd() {
        echo "################################################################"
        echo "Is VT-D enabled in BIOS?"
        echo "################################################################"
        read -r -p "y/n: " vtd_choice
        case $vtd_choice in
            y|Y|YES|yes|Yes )
                set_plist Kernel.Quirks.DisableIoMapper bool True
            ;;
            N|n|NO|No|no )
                echo "" > /dev/null
            ;;
            * )
                error "Invalid Choice"
                vtd
        esac
    }
    vtd
    hpdesktop() {
        echo "################################################################"
        echo "Do you have a HP System?"
        echo "################################################################"
        read -r -p "y/n: " hpdesktop_choice
        case $hpdesktop_choice in
            Y|y|YES|Yes|yes )
                set_plist Kernel.Quirks.LapicKernelPanic bool True
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
    set_plist Kernel.Quirks.PanicNoKextDump bool True
    set_plist Kernel.Quirks.PowerTimeoutKernelPanic bool True
    case $os_choice in
        4|5 ) 
             set_plist Kernel.Quirks.XhciPortLimit False
        ;;
    esac
    
    # gpu args go here
    platforminfo(){
        echo "################################################################"
        echo "Now, we need to pick an SMBIOS."
        echo "Pick the closest one to your hardware"
        echo "1. iMac18,1 - Used for computers utilizing the iGPU for displaying"
        echo "2. iMac18,3 - Used for computers using a dGPU for displaying, and an iGPU for computing tasks only"
        echo "################################################################"
        read -r -p "Choose a number between 1-2: " smbios_choice
        case $smbios_choice in
            1 )
               smbiosname=iMac18,1
            ;;
            2 )
               smbiosname=iMac18,3
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
    case $hpdesktop_choice in
        y|Yes|YES|Y|yes )
            set_plist UEFI.Quirks.UnblockFsConnect bool True
        ;;
    esac
    warning "Please disable the following options in the BIOS.\nFast Boot\nSecure Boot\nSerial/COM Port\nParallel Port\nVT-d\nCompatibility Support Module (CSM)\nThunderbolt (For intital install)\nIntel SGX\nIntel Platform Trust\nCFG Lock"
    warning "Please enable the following options in the BIOS.\nVT-x\nAbove 4G Decoding\nHyper-Threading\nExecute Disable Bit\nEHCI/XHCI Hand-off\nOS type: Windows 8.1/10 UEFI Mode (might be Other OS)\nDVMT Pre-Allocated(iGPU Memory): 64MB or higher\nSATA Mode: AHCI"
}

coffeelake_desktop_config_setup() {
    info "Configuring config.plist for Coffee Lake desktop..."
    add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0)" dict
    add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).AAPL,ig-platform-id" data
    set_plist Booter.Quirks.DevirtualiseMmio bool True
    set_plist Booter.Quirks.EnableWriteUnprotector bool False
    z390() {
        echo "################################################################"
        echo "Do you have a Z390 Motherboard?"
        echo "################################################################"
        read -r -p "y/n: " z390_choice
        case $z390_choice in
            y|Y|YES|Yes|yes )
                set_plist Booter.Quirks.ProtectUefiServices bool True
            ;;
            n|N|NO|No|no )
                echo "" > /dev/null
            ;;
            * )
                error "Invalid Choice"
                z390
            esac
    }
    z390
    set_plist Booter.Quirks.RebuildAppleMemoryMap bool True
    resizegpu(){
        echo "################################################################"
        echo "Does your firmware support Resizeable BAR?"
        echo "################################################################"
        read -r -p "y/n: " resizegpu_choice
        case $resizegpu_choice in
            Y|y|YES|Yes|yes )
                set_plist Booter.Quirks.ResizeAppleGpuBars int 0
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
    set_plist Booter.Quirks.SyncRuntimePermissions bool True
    aapl_plat_id () {
        echo "################################################################"
        echo "Now, we need to pick a AAPL,ig-platform-id."
        echo "Pick the one closest to your hardware."
        echo "1. 07009B3E - Used when the Desktop Coffee Lake iGPU is used to drive a display"
        echo "2. 00009B3E - Alternative to 07009B3E if it doesn't work"
        echo "3. 0300913E - Used when the Desktop Coffee Lake iGPU is only used for computing tasks and doesn't drive a display"
        echo "################################################################"
        read -r -p "Pick a number 1-2: " aapl_plat_id
        case $aapl_plat_id in
            1 )
                plat_id="00009B3E"
            ;;
            2 )
                plat_id="00009B3E"
            ;;
            3 )
                plat_id="0300913E"
            ;;
            * )
                error "Invalid Choice"
                aapl_plat_id
            ;;
        esac
    }
    aapl_plat_id
    set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).AAPL,ig-platform-id" data "$plat_id"
    dmvt() {
        echo "################################################################"
        echo "Can you put your DMVT iGPU allocated memory to more than 64mb in bios?"
        echo "################################################################"
        read -r -p "y/n: " dmvt_choice
        case $dmvt_choice in
            y|Y|YES|Yes|yes )
                echo "" > /dev/null
            ;;
            n|N|NO|No|no )
                add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-patch-enable" data
                add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-stolenmem" data
                set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-patch-enable" data 01000000
                set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-stolenmem" data 00003001
            ;;
            * )
                error "Invalid Choice"
                dmvt
            ;;
        esac
    }
    dmvt
    cfglock(){
        echo "################################################################"
        echo "Is CFG-Lock enabled in BIOS?"
        echo "################################################################"
        read -r -p "y/n: " cfg_choice
        case $cfg_choice in
            y|Y|YES|yes|Yes )
                set_plist Kernel.Quirks.AppleXcpmCfgLock bool True
            ;;
            N|n|NO|No|no )
                echo "" > /dev/null
            ;;
            * )
                error "Invalid Choice"
                cfglock
        esac
    }
    cfglock
    vtd() {
        echo "################################################################"
        echo "Is VT-D enabled in BIOS?"
        echo "################################################################"
        read -r -p "y/n: " vtd_choice
        case $vtd_choice in
            y|Y|YES|yes|Yes )
                set_plist Kernel.Quirks.DisableIoMapper bool True
            ;;
            N|n|NO|No|no )
                echo "" > /dev/null
            ;;
            * )
                error "Invalid Choice"
                vtd
        esac
    }
    vtd
    hpdesktop() {
        echo "################################################################"
        echo "Do you have a HP System?"
        echo "################################################################"
        read -r -p "y/n: " hpdesktop_choice
        case $hpdesktop_choice in
            Y|y|YES|Yes|yes )
                set_plist Kernel.Quirks.LapicKernelPanic bool True
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
    set_plist Kernel.Quirks.PanicNoKextDump bool True
    set_plist Kernel.Quirks.PowerTimeoutKernelPanic bool True
    case $os_choice in
        4|5 ) 
             set_plist Kernel.Quirks.XhciPortLimit False
        ;;
    esac
    
    # gpu args go here
    smbiosname=iMac19,1
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
    set_plist UEFI.Quirks.IgnoreInvalidFlexRatio bool True
    case $hpdesktop_choice in
        y|Yes|YES|Y|yes )
            set_plist UEFI.Quirks.UnblockFsConnect bool True
        ;;
    esac
    warning "Please disable the following options in the BIOS.\nFast Boot\nSecure Boot\nSerial/COM Port\nParallel Port\nVT-d\nCompatibility Support Module (CSM)\nThunderbolt (For intital install)\nIntel SGX\nIntel Platform Trust\nCFG Lock"
    warning "Please enable the following options in the BIOS.\nVT-x\nAbove 4G Decoding\nHyper-Threading\nExecute Disable Bit\nEHCI/XHCI Hand-off\nOS type: Windows 8.1/10 UEFI Mode (might be Other OS)\nDVMT Pre-Allocated(iGPU Memory): 64MB or higher\nSATA Mode: AHCI"
}

cometlake_desktop_config_setup(){
    info "Configuring config.plist for Comet Lake desktop..."
    add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0)" dict
    add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).AAPL,ig-platform-id" data
    set_plist Booter.Quirks.DevirtualiseMmio bool True
    set_plist Booter.Quirks.EnableWriteUnprotector bool False
    set_plist Booter.Quirks.ProtectUefiServices bool True
    set_plist Booter.Quirks.RebuildAppleMemoryMap bool True
    resizegpu(){
        echo "################################################################"
        echo "Does your firmware support Resizeable BAR?"
        echo "################################################################"
        read -r -p "y/n: " resizegpu_choice
        case $resizegpu_choice in
            Y|y|YES|Yes|yes )
                set_plist Booter.Quirks.ResizeAppleGpuBars int 0
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
    set_plist Booter.Quirks.SyncRuntimePermissions bool True
    aapl_plat_id() {
        echo "################################################################"
        echo "Now, we need to pick a AAPL,ig-platform-id."
        echo "Pick the one closest to your hardware."
        echo "1. 07009B3E - Used when the Desktop Comet Lake iGPU is used to drive a display"
        echo "2. 00009B3E - Alternative to 07009B3E if it doesn't work"
        echo "3. 0300C89B - Used when the Desktop Comet Lake iGPU is only used for computing tasks and doesn't drive a display"
        echo "################################################################"
        read -r -p "Pick a number 1-2: " aapl_plat_id
        case $aapl_plat_id in
            1 )
                plat_id="00009B3E"
            ;;
            2 )
                plat_id="00009B3E"
            ;;
            3 )
                plat_id="0300C89B"
            ;;
            * )
                error "Invalid Choice"
                aapl_plat_id
            ;;
        esac
    }
    aapl_plat_id
    set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).AAPL,ig-platform-id" data "$plat_id"
    dmvt() {
        echo "################################################################"
        echo "Can you put your DMVT iGPU allocated memory to more than 64mb in bios?"
        echo "################################################################"
        read -r -p "y/n: " dmvt_choice
        case $dmvt_choice in
            y|Y|YES|Yes|yes )
                echo "" > /dev/null
            ;;
            n|N|NO|No|no )
                add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-patch-enable" data
                add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-stolenmem" data
                set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-patch-enable" data 01000000
                set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-stolenmem" data 00003001
            ;;
            * )
                error "Invalid Choice"
                dmvt
            ;;
        esac
    }
    dmvt
    # Mac note: Do Kernel Patches for I225-V
    cfglock(){
        echo "################################################################"
        echo "Is CFG-Lock enabled in BIOS?"
        echo "################################################################"
        read -r -p "y/n: " cfg_choice
        case $cfg_choice in
            y|Y|YES|yes|Yes )
                set_plist Kernel.Quirks.AppleXcpmCfgLock bool True
            ;;
            N|n|NO|No|no )
                echo "" > /dev/null
            ;;
            * )
                error "Invalid Choice"
                cfglock
        esac
    }
    cfglock
    vtd() {
        echo "################################################################"
        echo "Is VT-D enabled in BIOS?"
        echo "################################################################"
        read -r -p "y/n: " vtd_choice
        case $vtd_choice in
            y|Y|YES|yes|Yes )
                set_plist Kernel.Quirks.DisableIoMapper bool True
            ;;
            N|n|NO|No|no )
                echo "" > /dev/null
            ;;
            * )
                error "Invalid Choice"
                vtd
        esac
    }
    vtd
    hpdesktop() {
        echo "################################################################"
        echo "Do you have a HP System?"
        echo "################################################################"
        read -r -p "y/n: " hpdesktop_choice
        case $hpdesktop_choice in
            Y|y|YES|Yes|yes )
                set_plist Kernel.Quirks.LapicKernelPanic bool True
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
    set_plist Kernel.Quirks.PanicNoKextDump bool True
    set_plist Kernel.Quirks.PowerTimeoutKernelPanic bool True
    case $os_choice in
        4|5 ) 
             set_plist Kernel.Quirks.XhciPortLimit bool False
        ;;
    esac
    
    #mac note: idk why this shit isnt working ffs
    #set_plist NVRAM.Add.7C436110-AB2A-4BBB-A880-FE41995C9F82.LegacySchema.WriteFlash bool True
    # gpu and network args go here
    platforminfo(){
        echo "################################################################"
        echo "Now, we need to pick an SMBIOS."
        echo "Pick the closest one to your hardware"
        echo "1. iMac20,1 - i7-10700K and lower (ie. 8 cores and lower)"
        echo "2. iMac20,2 - i9-10850K and higher (ie. 10 cores)"
        echo "################################################################"
        read -r -p "Choose a number between 1-2: " smbios_choice
        case $smbios_choice in
            1 )
               smbiosname=iMac20,1
            ;;
            2 )
               smbiosname=iMac20,2
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
    case $hpdesktop_choice in
        y|Yes|YES|Y|yes )
            set_plist UEFI.Quirks.UnblockFsConnect bool True
        ;;
    esac
    warning "Please disable the following options in the BIOS.\nFast Boot\nSecure Boot\nSerial/COM Port\nParallel Port\nVT-d\nCompatibility Support Module (CSM)\nThunderbolt (For intital install)\nIntel SGX\nIntel Platform Trust\nCFG Lock"
    warning "Please enable the following options in the BIOS.\nVT-x\nAbove 4G Decoding\nHyper-Threading\nExecute Disable Bit\nEHCI/XHCI Hand-off\nOS type: Windows 8.1/10 UEFI Mode (might be Other OS)\nDVMT Pre-Allocated(iGPU Memory): 64MB or higher\nSATA Mode: AHCI"
    #gumi note: mayb add smth pertaining to 2020+ bios regarding Above4G
}