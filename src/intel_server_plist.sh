haswell_broadwell_e_server_config_setup(){
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
    hpmachine(){
        echo "################################################################"
        echo "Do you have a HP System?"
        echo "################################################################"
        read -r -p "y/n: " hp_choice
        case $hp_choice in
            y|Y|YES|yes|Yes )
                set_plist Kernel.Quirks.LapicKernelPanic bool True
            ;;
            n|N|NO|no|No )
                echo "" > /dev/null
            ;;
            * )
                error "Invalid Choice"
                hpmachine
            esac
    }
    set_plist Kernel.Emulate.Cpuid1Data data "c3060300 00000000 00000000 00000000"
    set_plist Kernel.Emulate.Cpuid1Mask data "ffffffff 00000000 00000000 00000000"
    set_plist Kernel.Quirks.AppleXcpmCfgLock bool True
    set_plist Kernel.Quirks.AppleXcpmExtraMsrs bool True
    set_plist Kernel.Quirks.PanicNoKextDump bool True
    set_plist Kernel.Quirks.PowerTimeoutKernelPanic bool True
    case $os_choice in
        4|5 ) 
            set_plist Kernel.Quirks.XhciPortLimit bool False
        ;;
    esac
    
    # gpu args go here
    set_plist NVRAM.Delete.LegacyOverwrite bool True
    smbiosname=iMacPro1,1
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
    hpmachine
    vtd
    warning "Please disable the following options in the BIOS.\nFast Boot\nSecure Boot\nSerial/COM Port\nParallel Port\nVT-d\nCompatibility Support Module (CSM)\nThunderbolt (For intital install)\nIntel SGX\nIntel Platform Trust\nCFG Lock"
    warning "Please enable the following options in the BIOS.\nVT-x\nAbove 4G Decoding/Hyper Threading (If experiencing issues, ensure "MMIOH Base" is set to 12 TB or lower)\nExecute Disable Bit\nEHCI/XHCI Hand-off\nOS type: Windows 8.1/10 UEFI Mode (might be Other OS)\nSATA Mode: AHCI"
}

skylake_cascade_server_config_setup(){
    set_plist Booter.Quirks.DevirtualiseMmio bool True
    set_plist Booter.Quirks.EnableWriteUnprotector bool False
    set_plist Booter.Quirks.RebuildAppleMemoryMap bool True
    virtuamap(){
        echo "################################################################"
        echo "Do you have an ASUS system and is your BIOS version v3006 or higher?"
        echo "################################################################"
        read -r -p "y/n: " virtuamap_choice
        case $virtuamap_choice in
            y|Y|YES|Yes|yes )
                set_plist Booter.Quirks.SetupVirtualMap bool True
            ;;
            n|N|NO|No|no )
                echo "" > /dev/null
            ;;
            * )
                error "Invalid Choice"
                virtuamap
            esac
    }
    virtuamap
    #gumi note: me when virtua fighter reference
    set_plist Booter.Quirks.SyncRuntimePermissions bool True
    set_plist Kernel.Quirks.AppleXcpmCfgLock bool True
    set_plist Kernel.Quirks.DisableIoMapper bool True
    hpserver(){
        echo "################################################################"
        echo "Do you have a HP System?"
        echo "################################################################"
        read -r -p "y/n: " hpserver_choice
        case $hpserver_choice in
            y|Y|YES|Yes|yes )
                set_plist Kernel.Quirks.LapicKernelPanic bool True
            ;;
            n|N|NO|No|no )
                echo "" > /dev/null
            ;;
            * )
                error "Invalid Choice"
                hpserver
            esac
    }
    set_plist Kernel.Quirks.PanicNoKextDump bool True
    set_plist Kernel.Quirks.PowerTimeoutKernelPanic bool True
    case $os_choice in
        4|5 ) 
            set_plist Kernel.Quirks.XhciPortLimit bool False
        ;;
    esac
    
    # gpu args go here
    smbiosname=iMacPro1,1
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
    hpserver
    warning "Please disable the following options in the BIOS.\nFast Boot\nSecure Boot\nSerial/COM Port\nParallel Port\nVT-d\nCompatibility Support Module (CSM)\nThunderbolt (For intital install)\nIntel SGX\nIntel Platform Trust\nCFG Lock"
    warning "Please enable the following options in the BIOS.\nVT-x\nAbove 4G Decoding/Hyper Threading (If experiencing issues, ensure "MMIOH Base" is set to 12 TB or lower)\nExecute Disable Bit\nEHCI/XHCI Hand-off\nOS type: Windows 8.1/10 UEFI Mode (might be Other OS)\nSATA Mode: AHCI"
}