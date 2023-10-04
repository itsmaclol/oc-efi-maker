ice_lake_laptop_config_setup() {
    info "Configuring config.plist for Ice Lake Laptop..."
    chromebook() {
        echo "################################################################"
        echo "Is this laptop a chromebook?"
        echo "################################################################"
        read -r -p "y/n: " chromebook_choice
        case $chromebook_choice in
            y|Y|Yes|yes|YES )
                set_plist Booter.Quirks.ProtectMemoryRegions bool True
            ;;
            n|N|NO|No|no )
                echo "" > /dev/null
            ;;
            * )
                error "Invalid Choice" 
                chromebook
            ;;
        esac
    }
    chromebook
    set_plist Booter.Quirks.DevirtualiseMmio bool True
    set_plist Booter.Quirks.EnableWriteUnprotector bool False
    set_plist Booter.Quirks.ProtectUefiServices bool True
    set_plist Booter.Quirks.RebuildAppleMemoryMap bool True
    set_plist Booter.Quirks.SetupVirtualMap bool False
    set_plist Booter.Quirks.SyncRuntimePermissions bool True
    add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0)" dict
    add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).AAPL,ig-platform-id" data
    set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).AAPL,ig-platform-id" data 0000528A
    dmvt() {
        echo "################################################################"
        echo "Can you set your DVMT-prealloc to 256MB or higher?"
        echo "################################################################"
        read -r -p "y/n: " dvmt_prealloc
        case $dvmt_prealloc in
            n|N|NO|No|no )
                add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-patch-enable" int
                add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-stolenmem" data
                add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-fbmem" data
                set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-patch-enable" int 1
                set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-stolenmem" data 00003001
                set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-fbmem" data 00009000
            ;;
            y|Y|YES|Yes|yes )
                echo "" > /dev/null
            ;;  
            * )
                error "Invalid Choice"
                dmvt
        esac
    }
    dmvt
    cfglock() {
        echo "################################################################"
        echo "Is CFG-Lock enabled in BIOS?"
        echo "################################################################"
        read -r -p "y/n: " cfglock_choice
        case $cfglock_choice in
            y|Y|YES|Yes|yes )
                set_plist Kernel.Quirks.AppleXcpmCfgLock bool True
            ;;
            n|N|NO|No|no )
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
            n|N|NO|No|no )
                echo "" > /dev/null
            ;;
        esac
    }
    vtd
    hplaptop() {
        echo "################################################################"
        echo "Is your laptop a HP laptop?"
        echo "################################################################"
        read -r -p "y/n: " hplaptop_choice
        case $hplaptop_choice in
            Y|y|YES|Yes|yes )
                set_plist Kernel.Quirks.LapicKernelPanic bool True
            ;;
            n|N|NO|No|no )
                echo "" > /dev/null
            ;;
            * )
                error "Invalid Choice"
                hplaptop
            ;;
        esac
    }
    hplaptop
    set_plist Kernel.Quirks.PanicNoKextDump bool True
    set_plist Kernel.Quirks.PowerTimeoutKernelPanic bool True
    case $os_choice in
        4|5 )
            set_plist Kernel.Quirks.XhciPortLimit bool True
        ;;
    esac
    append_plist NVRAM.Add.7C436110-AB2A-4BBB-A880-FE41995C9F82.boot-args string " -igfxcdc -igfxdvmt -igfxdbeo"
    platforminfo() {
        echo "################################################################"
        echo "Now, we need to pick an SMBIOS."
        echo "1. MacBookAir9,1 - CPU: Dual/Quad Core 12W GPU: G4/G7 Display Size: 13inch "
        echo "2. MacBookPro16,2 - CPU: Quad Core 28W GPU: G4/G7 Display Size:13inch "
        echo "################################################################"
        read -r -p "Pick a number 1-2: " smbios_choice
        case $smbios_choice in
            1 )
                smbiosname="MacBookAir9,1"
            ;;
            2 )
                smbiosname="MacBookPro16,2"
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
    set_plist UEFI.Quirks.ReleaseUsbOwnership bool True
    case $hplaptop_choice in
        y|Yes|YES|Y|yes )
            set_plist UEFI.Quirks.UnblockFsConnect bool True
        ;;
    esac
}

coffelakeplus_cometlake_laptop_config_setup() {
    info "Configuring config.plist for CoffeeLakePlus/Comet Lake Laptop..."
    add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0)" dict
    add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).AAPL,ig-platform-id" data
    chromebook() {
        echo "################################################################"
        echo "Is this laptop a chromebook?"
        echo "################################################################"
        read -r -p "y/n: " chromebook_choice
        case $chromebook_choice in
            y|Y|Yes|yes|YES )
                set_plist Booter.Quirks.ProtectMemoryRegions bool True
            ;;
            n|N|No|NO )
                echo "" >> /dev/null
            ;;
            * )
                chromebook
            ;;
        esac
    }
    chromebook
    set_plist Booter.Quirks.DevirtualiseMmio bool True
    set_plist Booter.Quirks.EnableWriteUnprotector bool False
    set_plist Booter.Quirks.ProtectUefiServices bool True
    set_plist Booter.Quirks.RebuildAppleMemoryMap bool True
    set_plist Booter.Quirks.SyncRuntimePermissions bool True
    aapl() {
        echo "################################################################"
        echo "Now, we need to pick an AAPL,ig-platform-id, pick the one closest to your GPU"
        echo "1. 0900A53E - Laptop - Recommended value for UHD 630"
        echo "2. 00009B3E - Laptop - Recommended value for UHD 620"
        echo "3. 07009B3E - NUC - Recommended value for UHD 620/630"
        echo "4. 0000A53E - NUC - Recommended value for UHD 655"
        echo "################################################################"
        read -r -p "Pick a number 1-4: " aapl_id_choice
        case $aapl_id_choice in
            1 )
                plat_id="0900A53E"
            ;;
            2 )
                plat_id="00009B3E"
            ;;
            3 )
                plat_id="07009B3E"
            ;;
            4 )
                plat_id="0000A53E"
            ;;
            * )
                error "Invalid Choice"
                aapl
        esac
    }
    aapl
    set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).AAPL,ig-platform-id" data "$plat_id"
    warning "If your GPU is a UHD630 and your device-id of it in Windows is anything else than 0x3E9B, you need to create an entry under DeviceProperties:PciRoot(0x0)/Pci(0x2,0x0)
 named device-id as data, with the value: 9B3E0000"
    sleep 5
    uhd620() {
        echo "################################################################"
        echo "Is your GPU a UHD620?"
        echo "################################################################"
        read -r -p "y/n: " uhd620_choice
        case $uhd620_choice in
            y|Y|YES|Yes|yes )
                add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).device-id" data
                set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).device-id" data 9B3E0000
            ;;
            n|N|NO|No|no ) 
                echo "" >> /dev/null
            ;;
            * )
                error "Invalid Choice"
                uhd620
        esac
    }
    uhd620
    dmvt() {
        echo "################################################################"
        echo "Can you set your DVMT-prealloc to 256MB or higher?"
        echo "################################################################"
        read -r -p "y/n: " dvmt_prealloc
        case $dvmt_prealloc in 
            y|Y|Yes|yes|YES )
                echo "" > /dev/null
            ;;
            n|N|NO|No|no )
                add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-patch-enable" data
                set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-patch-enable" data 01000000
                add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-stolenmem" data
                set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-stolenmem" data 00003001
                add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-fbmem" data
                add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-fbmem" data 00009000
            ;;
            * )
                error "Invalid Choice"
                dmvt
        esac
    }
    dmvt
    cfglock() {
        echo "################################################################"
        echo "Is CFG-Lock enabled in BIOS?"
        echo "################################################################"
        read -r -p "y/n: " cfglock_choice
        case $cfglock_choice in
            y|Y|YES|Yes|yes )
                set_plist Kernel.Quirks.AppleXcpmCfgLock bool True
            ;;
            n|N|NO|No|no )
                echo "" >> /dev/null
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
            n|N|NO|No|no )
                echo >> /dev/null
                ;;
            * )
                error "Invalid Choice"
                vtd
        esac
    }
    vtd
    hplaptop() {
        echo "################################################################"
        echo "Is your laptop a HP laptop?"
        echo "################################################################"
        read -r -p "y/n: " hplaptop_choice
        case $hplaptop_choice in
            Y|y|YES|Yes|yes )
                set_plist Kernel.Quirks.LapicKernelPanic bool True
            ;;
            n|N|NO|No|no )
                echo "" > /dev/null
            ;;
            * )
                error "Invalid Choice"
                hplaptop
        esac
    }
    hplaptop
    set_plist Kernel.Quirks.PanicNoKextDump bool True
    set_plist Kernel.Quirks.PowerTimeoutKernelPanic bool True
    case $os_choice in
        4|5 )
            set_plist Kernel.Quirks.XhciPortLimit bool True
        ;;
    esac
    
    platforminfo() {
        echo "################################################################"
        echo "Now, for an SMBIOS, pick the one closest to your hardware."
        echo "1. MacBookPro16,1	- CPU: Hexa/Octa Core 45W - GPU: UHD 630 + dGPU: 5300/5500M - Display: 15inch"
        echo "2. MacBookPro16,3	- CPU: Quad Core 15W - GPU: Iris 645 - Display: 13inch"
        echo "3. MacBookPro16,4	- CPU: Hexa/Octa Core 45W - GPU: UHD 630 + dGPU: 5600M - Display: 15inch"
        echo "4. MacBookPro16,5	- NUC Systems - GPU: HD 6000/Iris Pro 6200 - Display N/A"
        echo "################################################################"
        read -r -p "Pick a number 1-4: " smbios_choice
        case $smbios_choice in
            1 )
                smbiosname="MacBookPro16,1"
            ;;
            2 )
                smbiosname="MacBookPro16,3"
            ;;
            3 )
                smbiosname="MacBookPro16,4"
            ;;
            4 )
                smbiosname="Macmini8,1"
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
    set_plist UEFI.Quirks.ReleaseUsbOwnership bool True
    case $hplaptop_choice in
        y|Yes|YES|Y|yes )
            set_plist UEFI.Quirks.UnblockFsConnect bool True
        ;;
    esac
}

coffee_whiskeylake_laptop_config_setup() {
    info "Configuring config.plist for Coffee Lake Plus/Whiskey Lake..."
    add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0)" dict
    add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).AAPL,ig-platform-id" data
    chromebook() {
        echo "################################################################"
        echo "Is this laptop a chromebook?"
        echo "################################################################"
        read -r -p "y/n: " chromebook_choice
        case $chromebook_choice in
            y|Y|Yes|yes|YES )
                set_plist Booter.Quirks.ProtectMemoryRegions bool True
            ;;
            n|N|No|NO )
                echo "" >> /dev/null
            ;;
            * )
                chromebook
            ;;
        esac
    }
    chromebook
    set_plist Booter.Quirks.EnableWriteUnprotector bool False
    set_plist Booter.Quirks.RebuildAppleMemoryMap bool True
    set_plist Booter.Quirks.SyncRuntimePermissions bool True
    aapl_plat_id() {
        echo "################################################################"
        echo "We're going to need to pick an AAPL,ig-platform-id."
        echo "Pick the one closest to your hardware"
        echo "1. 0900A53E - Laptop - Recommended value for UHD 630"
        echo "2. 00009B3E - Laptop - Recommended value for UHD 620"
        echo "3. 07009B3E - NUC - Recommended value for UHD 620/630"
        echo "4. 0000A53E - NUC Recommended value for UHD 655"
        echo "################################################################"
        read -r -p "Pick a number 1-4: " aapl_plat_id
        case $aapl_plat_id in
            1 )
                plat_id="0900A53E"
            ;;
            2 )
                plat_id="00009B3E"
            ;;
            3 )
                plat_id="07009B3E"
            ;;
            4 )
                plat_id="0000A53E"
            ;;
            * )
                error "Invalid Choice"
                aapl_plat_id
            ;;
        esac
    }
    aapl_plat_id
    set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).AAPL,ig-platform-id" data "$plat_id"
    warning "If your GPU is a UHD630 and your device-id of it in windows is anything else than 0x3E9B, you need to create an entry under DeviceProperties:PciRoot(0x0)/Pci(0x2,0x0)
 named device-id as data, with the value: 9B3E0000"
    uhd620() {
        echo "################################################################"
        echo "Is your GPU a UHD 620?"
        echo "################################################################"
        read -r -p "y/n: " uhd620_choice
        case $uhd620_choice in
            y|Y|yes|YES|Yes )
                add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).device-id" data
                set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).device-id" data 9B3E0000
            ;;
            * )
                error "Invalid Choice"
                uhd620
            ;;
        esac
    }
    uhd620 
    dmvt() {
    echo "################################################################"
    echo "Can you set your DVMT-prealloc to 256MB or higher?"
    echo "################################################################"
    read -r -p "y/n: " dvmt_prealloc
    case $dvmt_prealloc in
        n|N|NO|No|no )
            add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-patch-enable" data
            set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-patch-enable" data 01000000
            add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-stolenmem" data
            set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-stolenmem" data 00003001
            add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-fbmem" data
            add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-fbmem" data 00009000
        ;;
        y|Y|YES|Yes|yes )
            echo "" > /dev/null
        ;;
    esac
    }
    dmvt
    cfglock() {
        echo "################################################################"
        echo "Is CFG-Lock enabled in BIOS?"
        echo "################################################################"
        read -r -p "y/n: " cfglock_choice
        case $cfglock_choice in
            y|Y|YES|Yes|yes )
                set_plist Kernel.Quirks.AppleXcpmCfgLock bool True
            ;;
            n|N|NO|No|no )
                echo "" >> /dev/null
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
            n|N|NO|No|no )
                echo >> /dev/null
                ;;
            * )
                error "Invalid Choice"
                vtd
        esac
    }
    vtd
    hplaptop() {
        echo "################################################################"
        echo "Is your laptop a HP laptop?"
        echo "################################################################"
        read -r -p "y/n: " hplaptop_choice
        case $hplaptop_choice in
            Y|y|YES|Yes|yes )
                set_plist Kernel.Quirks.LapicKernelPanic bool True
            ;;
            n|N|NO|No|no )
                echo "" > /dev/null
            ;;
            * )
                error "Invalid Choice"
                hplaptop
        esac
    }
    hplaptop
    set_plist Kernel.Quirks.PanicNoKextDump bool True
    set_plist Kernel.Quirks.PowerTimeoutKernelPanic bool True
    case $os_choice in
        4|5 )
            set_plist Kernel.Quirks.XhciPortLimit bool True
        ;;
    esac
    
    platforminfo() {
        echo "################################################################"
        echo "Now, for an SMBIOS, pick the one closest to your hardware."
        echo "1. MacBookPro15,1	- CPU: Hexa Core 45W - GPU: UHD 630 + dGPU: Radeon Pro 555X/560X - Display: 15inch"
        echo "2. MacBookPro15,2	- CPU: Quad Core 15W - GPU: Iris 655 - Display: 13inch"
        echo "3. MacBookPro15,3 - CPU: Hexa Core 45W - GPU: UHD 630 + dGPU: Vega 16/20 - Display: 15inch"
        echo "4. MacBookPro15,4	- CPU: Quad Core 15W - GPU: Iris 645 - Display: 13inch"
        echo "5. Macmini8,1	- NUC Systems - GPU: HD 6000/Iris Pro 6200 - Display: N/A"
        echo "################################################################"
        read -r -p "Pick a number 1-5: " smbios_choice
        case $smbios_choice in
            1 )
                smbiosname="MacBookPro15,1"
            ;;
            2 )
                smbiosname="MacBookPro15,2"
            ;;
            3 )
                smbiosname="MacBookPro15,3"
            ;;
            4 )
                smbiosname="MacBookPro15,4"
            ;;
            5 )
                smbiosname="Macmini8,1"
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
    set_plist UEFI.Quirks.ReleaseUsbOwnership bool True
    case $hplaptop_choice in
        y|Yes|YES|Y|yes )
            set_plist UEFI.Quirks.UnblockFsConnect bool True
        ;;
    esac  
}

kabylake_laptop_config_setup() {
    info "Configuring config.plist for Kaby Lake Laptop..."
    add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0)" dict
    add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).AAPL,ig-platform-id" data 
    aapl_plat_id() {
        echo "################################################################"
        echo "We're going to need to pick a AAPL,ig-platform-id closest to your specifications."
        echo "1. 00001B59 - Laptop - Recommended for HD 615, HD 620, HD 630, HD 640 and HD 650"
        echo "2. 00001659 - Laptop - Alternative value to 00001B59 if you have acceleration issues, and recommended for all HD and UHD 620 NUCs"
        echo "3. 0000C087 - Laptop - Recommended for Amber Lake's UHD 617 and Kaby Lake-R's UHD 620"
        echo "4. 00001E59 - NUC - Recommended for HD 615"
        echo "5. 00001B59 - NUC - Recommended for HD 630"
        echo "6. 02002659 - NUC - Recommended for HD 640/650"
        echo "################################################################"
        read -r -p "Pick a number 1-6: " aapl_plat_id
        case $aapl_plat_id in
            1 )
                plat_id="00001B59"
            ;;
            2 )
                plat_id="00001659"
            ;;
            3 )
                plat_id="0000C087"
            ;;
            4 )
                plat_id="00001E59"
            ;;
            5 )
                plat_id="00001B59"
            ;;
            6 )
                plat_id="02002659"
            ;;
            * )
                error "Invalid Choice"
                aapl_plat_id
        esac
        }
    aapl_plat_id
    set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).AAPL,ig-platform-id" data "$plat_id"
    uhd620() {
        echo "################################################################"
        echo "Is your GPU a UHD 620?"
        echo "################################################################"
        read -r -p "y/n: " uhd620_choice
        case $uhd620_choice in
            y|Y|yes|YES|Yes )
                add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).device-id" data
                set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).device-id" data 16590000
            ;;
            n|N|NO|No|no )
                echo "" >> /dev/null
            ;;
            * )
                error "Invalid Choice"
                uhd620
            ;;
        esac
    }
    uhd620
    dmvt() {
    echo "################################################################"
    echo "Can you set your DVMT-prealloc to 256MB or higher?"
    echo "################################################################"
    read -r -p "y/n: " dvmt_prealloc
    case $dvmt_prealloc in
        n|N|NO|No|no )
            add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-patch-enable" data
            add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-stolenmem" data
            add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-fbmem" data
            set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-patch-enable" data 01000000
            set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-stolenmem" data 00003001
            set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-fbmem" data 00009000
        ;;
        y|Y|YES|Yes|yes )
            echo "" > /dev/null
        ;;
    esac
    }
    dmvt
    cfglock() {
        echo "################################################################"
        echo "Is CFG-Lock enabled in BIOS?"
        echo "################################################################"
        read -r -p "y/n: " cfglock_choice
        case $cfglock_choice in
            y|Y|YES|Yes|yes )
                set_plist Kernel.Quirks.AppleXcpmCfgLock bool True
            ;;
            n|N|NO|No|no )
                echo "" >> /dev/null
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
            n|N|NO|No|no )
                echo >> /dev/null
                ;;
            * )
                error "Invalid Choice"
                vtd
        esac
    }
    vtd
    hplaptop() {
        echo "################################################################"
        echo "Is your laptop a HP laptop?"
        echo "################################################################"
        read -r -p "y/n: " hplaptop_choice
        case $hplaptop_choice in
            Y|y|YES|Yes|yes )
                set_plist Kernel.Quirks.LapicKernelPanic bool True
            ;;
            n|N|NO|No|no )
                echo "" > /dev/null
            ;;
            * )
                error "Invalid Choice"
                hplaptop
        esac
    }
    hplaptop
    set_plist Kernel.Quirks.PanicNoKextDump bool True
    set_plist Kernel.Quirks.PowerTimeoutKernelPanic bool True
    case $os_choice in
        4|5 )
            set_plist Kernel.Quirks.XhciPortLimit bool True
        ;;
    esac
    
    platforminfo() {
        echo "################################################################"
        echo "Now, we need to pick an SMBIOS, choose the one closest to your hardware."
        echo "1. MacBookPro14,1	- CPU: Dual Core 15W(Low End) - GPU: Iris Plus 640 13inch"
        echo "2. MacBookPro14,2	- CPU: Dual Core 15W(High End) - GPU: Iris Plus 650 13 inch"
        echo "3. MacBookPro14,3	- CPU: Quad Core 45W - iGPU: HD 630 + dGPU: Radeon Pro 555X/560X 15inch"
        echo "4. iMac18,1 - NUC Systems - GPU: Iris Plus 640"
        echo "################################################################"
        read -r -p "Pick a number 1-4: " smbios_choice
        case $smbios_choice in
            1 )
                smbiosname="MacBookPro14,1"
            ;;
            2 )
                smbiosname="MacBookPro14,2"
            ;;
            3 )
                smbiosname="MacBookPro14,3"
            ;;
            4 )
                smbiosname="iMac18,1"
            ;;
            * )
                error "Invalid Choice"
                platforminfo
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
    set_plist UEFI.Quirks.ReleaseUsbOwnership bool True
    case $hplaptop_choice in
        y|Yes|YES|Y|yes )
            set_plist UEFI.Quirks.UnblockFsConnect bool True
        ;;
    esac
}

skylake_laptop_config_setup() {
    case $os_choice in
        1 )
            warning "You have chosen macOS Ventura for a SkyLake Laptop. The script will attempt to spoof it to a kaby lake system for you to have a working system. This script may not do the spoofing correctly and your system may end up with no graphic acceleration. Do you want to continue?"
            read -r -p "y/n: " spoof_choice
            case $spoof_choice in
                y|Y|YES|Yes|yes )
                    echo "" > /dev/null
                ;;
                n|N|NO|No|no )
                    error "Exiting..."
                    exit 1
                ;;
            esac
        ;;
        * )
            echo "" > /dev/null
        ;;
    esac
    info "Configuring config.plist for Skylake Laptop..."
    add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0)" dict
    add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).AAPL,ig-platform-id" data 
    aapl_plat_id() {
        echo "################################################################"
        echo "Now, we need to pick an AAPL,ig-platform-id."
        echo "1. 00001619 - Laptop - Recommended value for HD 515, HD 520, HD 530, HD 540, HD 550 and P530"
        echo "2. 00001E19 - Laptop - Alternative for HD 515 if you have issues with the above entry"
        echo "3. 00001B19 - Laptop - Recommended value for HD 510"
        echo "4. 00001E19 - NUC - Recommended for HD 515"
        echo "5. 02001619 - NUC - Recommended for HD 520/530"
        echo "6. 02002619 - NUC - Recommended for HD 540/550"
        echo "7. 05003B19 - NUC - Recommended for HD 580"
        echo "################################################################"
        read -r -p "Pick a number 1-7: " aapl_plat_id
        case $aapl_plat_id in 
            1 )
                plat_id="00001619"
            ;;
            2 )
                plat_id="00001E19"
            ;;
            3 )
                plat_id="00001B19"
            ;;
            4 )
                plat_id="00001E19"
            ;;
            5 )
                plat_id="02001619"
            ;;
            6 )
                plat_id="02002619"
            ;;
            7 )
                plat_id="05003B19"
            ;;
            * )
                error "Invalid Choice"
                aapl_plat_id
            ;;
        esac
        warning "For HD 550 and P530 (and potentially all HD P-series iGPUs), you may need to use device-id=16190000"
        sleep 10
    }
    ventura_aapl_plat_id() {
        echo "################################################################"
        echo "Since you want to spoof your GPU and SMBIOS to install Ventura"
        echo "We're going to need to pick a AAPL,ig-platform-id closest to your specifications."
        echo "1. 00001B59 - Laptop - Recommended for HD 615, HD 620, HD 630, HD 640 and HD 650"
        echo "2. 00001659 - Laptop - Alternative value to 00001B59 if you have acceleration issues, and recommended for all HD and UHD 620 NUCs"
        echo "3. 0000C087 - Laptop - Recommended for Amber Lake's UHD 617 and Kaby Lake-R's UHD 620"
        echo "4. 00001E59 - NUC - Recommended for HD 615"
        echo "5. 00001B59 - NUC - Recommended for HD 630"
        echo "6. 02002659 - NUC - Recommended for HD 640/650"
        echo "################################################################"
        read -r -p "Pick a number 1-6: " aapl_plat_id
        case $aapl_plat_id in
            1 )
                plat_id="00001B59"
            ;;
            2 )
                plat_id="00001659"
            ;;
            3 )
                plat_id="0000C087"
            ;;
            4 )
                plat_id="00001E59"
            ;;
            5 )
                plat_id="00001B59"
            ;;
            6 )
                plat_id="02002659"
            ;;
            * )
                error "Invalid Choice"
                ventura_aapl_plat_id
        esac
        }
        hd510() {
            echo "################################################################"
            echo "Do you have a HD 510?"
            echo "################################################################"
            read -r -p "y/n: " hd510_choice
            case $hd510_choice in
                y|Y|yes|YES|Yes )
                    add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).device-id" data
                    set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).device-id" data 02190000
                ;;
                * )
                    error "Invalid Choice"
                    hd510
                ;;
            esac
        }
        hd520() {
            echo "################################################################"
            echo "Is your GPU a HD 520?"
            echo "################################################################"
            read -r -p "y/n: " hd520_choice
            case $hd520_choice in
                y|Y|yes|YES|Yes )
                    add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).device-id" data
                    set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).device-id" data 16590000
                ;;
                * )
                    error "Invalid Choice"
                    hd520
                ;;
            esac
         }
        case $os_choice in
        1 )
            ventura_aapl_plat_id
            hd520
        ;;
        2|3|4|5 )
            aapl_plat_id
            hd510
        ;;
        esac
    set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).AAPL,ig-platform-id" data "$plat_id"

    dmvt() {
    echo "################################################################"
    echo "Can you set your DVMT-prealloc to 256MB or higher?"
    echo "################################################################"
    read -r -p "y/n: " dvmt_prealloc
    case $dvmt_prealloc in
        n|N|NO|No|no )
            add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-patch-enable" data
            add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-stolenmem" data
            add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-fbmem" data
            set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-patch-enable" data 01000000
            set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-stolenmem" data 00003001
            set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-fbmem" data 00009000
        ;;
        y|Y|YES|Yes|yes )
            echo "" > /dev/null
        ;;
        * )
            error "Invalid Choice"
            dmvt
    esac
    }
    dmvt
    cfglock() {
        echo "################################################################"
        echo "Is CFG-Lock enabled in BIOS?"
        echo "################################################################"
        read -r -p "y/n: " cfglock_choice
        case $cfglock_choice in
            y|Y|YES|Yes|yes )
                set_plist Kernel.Quirks.AppleXcpmCfgLock bool True
            ;;
            n|N|NO|No|no )
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
    hplaptop() {
        echo "################################################################"
        echo "Is your laptop a HP laptop?"
        echo "################################################################"
        read -r -p "y/n: " hplaptop_choice
        case $hplaptop_choice in
            Y|y|YES|Yes|yes )
                set_plist Kernel.Quirks.LapicKernelPanic bool True
            ;;
            n|N|NO|No|no )
                echo "" > /dev/null
            ;;
            * )
                error "Invalid Choice"
                hplaptop
        esac
    }
    hplaptop
    set_plist Kernel.Quirks.PanicNoKextDump bool True
    set_plist Kernel.Quirks.PowerTimeoutKernelPanic bool True
    case $os_choice in
        4|5 )
            set_plist Kernel.Quirks.XhciPortLimit bool True
        ;;
    esac
    
    platforminfo_setup() {
        echo "################################################################"
        echo "Now, we need to pick an SMBIOS."
        echo "1. MacBook9,1	- CPU: Dual Core 7W(Low End) - GPU: HD 515 12inch"
        echo "2. MacBookPro13,1 - CPU: Dual Core 15W(Low End) - GPU: Iris 540 13inch"
        echo "3. MacBookPro13,2 - CPU: Dual Core 15W(High End) - GPU: Iris 550 13inch"
        echo "4. MacBookPro13,3	- CPU: Quad Core 45W - iGPU: HD 530 + dGPU: Radeon Pro 450/455 15inch"
        echo "5. iMac17,1 - NUC Systems - iGPU: HD 530 + R9 290"
        echo "################################################################"
        read -r -p "Pick a number 1-5: " smbios_choice
        case $smbios_choice in
            1 )
                smbiosname="MacBook9,1"
            ;;
            2 )
                smbiosname="MacBookPro13,1"
            ;;
            3 )
                smbiosname="MacBookPro13,2"
            ;;
            4 )
                smbiosname="MacBookPro13,3"
            ;;
            5 )
                smbiosname="iMac17,1"
            ;;
            * )
                error "Invalid Choice"
                platforminfo_setup
        esac
    }

    platforminfo_setup_ventura() {
        echo "################################################################"
        echo "Now, we need to pick a Kaby Lake SMBIOS, even though this is a Skylake machine."
        echo "Pick the closest one to your hardware."
        echo "1. MacBookPro14,1	- CPU: Dual Core 15W(Low End) - GPU: Iris Plus 640 13inch"
        echo "2. MacBookPro14,2	- CPU: Dual Core 15W(High End) - GPU: Iris Plus 650 13 inch"
        echo "3. MacBookPro14,3	- CPU: Quad Core 45W - iGPU: HD 630 + dGPU: Radeon Pro 555X/560X 15inch"
        echo "4. iMac18,1 - NUC Systems - GPU: Iris Plus 640"
        echo "################################################################"
        read -r -p "Pick a number 1-4: " smbios_choice
        case $smbios_choice in
            1 )
                smbiosname="MacBookPro14,1"
            ;;
            2 )
                smbiosname="MacBookPro14,2"
            ;;
            3 )
                smbiosname="MacBookPro14,3"
            ;;
            4 )
                smbiosname="iMac18,1"
            ;;
            * )
                error "Invalid Choice"
                platforminfo_setup_ventura
        esac
    }
    case $os_choice in
        1 )
            platforminfo_setup_ventura
        ;;
        2|3|4|5 )
            platforminfo_setup
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
    set_plist UEFI.Quirks.ReleaseUsbOwnership bool True
    case $hplaptop_choice in
        y|Yes|YES|Y|yes )
            set_plist UEFI.Quirks.UnblockFsConnect bool True
        ;;
    esac
}

broadwell_laptop_config_setup() {
    info "Configuring config.plist for Broadwell Laptop..."
    add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0)" dict
    add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).AAPL,ig-platform-id" data 
    aapl_plat_id() {
        echo "################################################################"
        echo "Now, we need to pick an AAPL,ig-platform-id."
        echo "1. 06002616 - Laptop - Recommended value for Broadwell laptops"
        echo "2. 02001616 - NUC - Recommended value for Broadwell NUCs"
        echo "################################################################"
        read -r -p "Pick a number 1-2: " aapl_plat_id
        case $aapl_plat_id in
            1 )
                plat_id="06002616"
            ;;
            2 )
                plat_id="02001616"
            ;;
            * )
                error "Invalid Choice"
                aapl_plat_id
            ;;
        esac
    }
    aapl_plat_id
    set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).AAPL,ig-platform-id" data "$plat_id"
    hd5600() {
        echo "################################################################"
        echo "Do you have a hd5600?"
        echo "################################################################"
        read -r -p "y/n: " hd5600_choice
        case $hd5600_choice in
            y|Y|YES|Yes|yes )
                add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).device-id" data
                set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).device-id" data 26160000
            ;;
            n|N|NO|No|no )
                echo "" > /dev/null
            ;;
            * )
                error "Invalid Choice"
                hd5600
        esac
    }
    hd5600
    dmvt() {
    echo "################################################################"
    echo "Can you set your DVMT-prealloc to 96MB or higher?"
    echo "################################################################"
    read -r -p "y/n: " dvmt_prealloc
    case $dvmt_prealloc in
        n|N|NO|No|no )
            add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-patch-enable" data
            add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-stolenmem" data
            add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-fbmem" data
            set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-patch-enable" data 01000000
            set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-stolenmem" data 00003001
            set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-fbmem" data 00009000
        ;;
        y|Y|YES|Yes|yes )
            echo "" > /dev/null
        ;;
        * )
            error "Invalid Choice"
            dmvt
    esac
    }
    dmvt
    set_plist Kernel.Quirks.AppleCpuPmCfgLock bool True
    set_plist Kernel.Quirks.AppleXcpmCfgLock bool True
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
    hplaptop() {
        echo "################################################################"
        echo "Is your laptop a HP laptop?"
        echo "################################################################"
        read -r -p "y/n: " hplaptop_choice
        case $hplaptop_choice in
            Y|y|YES|Yes|yes )
                set_plist Kernel.Quirks.LapicKernelPanic bool True
            ;;
            n|N|NO|No|no )
                echo "" > /dev/null
            ;;
            * )
                error "Invalid Choice"
                hplaptop
        esac
    }
    hplaptop
    set_plist Kernel.Quirks.PanicNoKextDump bool True
    set_plist Kernel.Quirks.PowerTimeoutKernelPanic bool True
    case $os_choice in
        4|5 )
            set_plist Kernel.Quirks.XhciPortLimit bool True
        ;;
    esac
    
    platforminfo() {
        echo "################################################################"
        echo "Now, we need to pick an SMBIOS."
        echo "Pick the one closest to your hardware."
        echo "1. MacBook8,1 - CPU: Dual Core 7W(Low End) - GPU: HD 5300 - Display: 12inch"
        echo "2. MacBookAir7,1 - CPU: Dual Core 15W	- GPU: HD 6000 - Display: 11inch"
        echo "3. MacBookAir7,2 - CPU: Dual Core 15W	- GPU: HD 6000 - Display: 13inch"
        echo "4. MacBookPro12,1	- CPU: Dual Core 28W(High End) - GPU: Iris 6100	- Display: 13inch"
        echo "5. MacBookPro11,2 - CPU: Quad Core 45W - GPU: Iris Pro 5200 - Display: 15inch"
        echo "6. MacBookPro11,3 - CPU: Quad Core 45W - GPU: Iris Pro 5200 + dGPU: GT 750M - Display: 15inch"
        echo "7. MacBookPro11,4 - CPU: Quad Core 45W - GPU: Iris Pro 5200 - Display: 15inch"
        echo "8. MacBookPro11,5 - CPU: Quad Core 45W - GPU: Iris Pro 5200 + dGPU: R9 M370X - Display: 15inch"
        echo "9. iMac16,1 - NUC Systems - GPU: HD 6000/Iris Pro 6200 - Display: N/A"
        echo "################################################################"
        read -r -p "Pick a int 1-9: " smbios_choice
        case $smbios_choice in
            1 )
                case $os_choice in
                    1|2 )
                        error "MacBook8,1 was dropped in macOS Monterey and higher, please pick another SMBIOS."
                        platforminfo
                    ;;
                    * )
                        smbiosname="MacBook8,1"
                    ;;
                esac
                
            ;;
            2 )
                smbiosname="MacBookAir7,1"
            ;;
            3 )
                smbiosname="MacBookAir7,2"
            ;;
            4 )
                smbiosname="MacBookPro12,1"
            ;;
            5 )
                smbiosname="MacBookPro11,2"
            ;;
            6 )
                smbiosname="MacBookPro11,3"
            ;;
            7 )
                smbiosname="MacBookPro11,4"
            ;;
            8 )
                smbiosname="MacBookPro11,5"
            ;;
            9 )
                smbiosname="iMac16,1"
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
    set_plist UEFI.Quirks.ReleaseUsbOwnership bool True
    set_plist UEFI.Quirks.IgnoreInvalidFlexRatio bool True
    case $hplaptop_choice in
        y|Yes|YES|Y|yes )
            set_plist UEFI.Quirks.UnblockFsConnect bool True
        ;;
    esac
    warning "You must enable CFG-Lock in BIOS."
}

haswell_laptop_config_setup() {
    info "Configuring config.plist for Haswell laptop..."
    add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0)" dict
    add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).AAPL,ig-platform-id" data 
    aapl_plat_id() {
        echo "################################################################"
        echo "Now, we need to pick a AAPL,ig-platform-id."
        echo "Pick the one closest to your hardware."
        echo "1. 0500260A - Laptop - To be used usually with HD 5000, HD 5100 and HD 5200"
        echo "2. 0600260A - Laptop - To be used usually with HD 4200, HD 4400 and HD 4600 (requires device-id patching, will ask later)"
        echo "3. 0300220D - NUC - To be used usually with all Haswell NUCs, HD 4200/4400/4600 (must use device-id patching, will ask later)"
        echo "################################################################"
        read -r -p "Pick a number 1-3: " aapl_plat_id
        case $aapl_plat_id in
            1 )
                plat_id="0500260A"
            ;;
            2 )
                plat_id="0600260A"
            ;;
            3 )
                plat_id="0300220D"
            ;;
            * )
                error "Invalid Choice"
                aapl_plat_id
        esac
    }
    aapl_plat_id
    set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).AAPL,ig-platform-id" data "$plat_id"
    hd4xxx() {
        echo "################################################################"
        echo "Do you have a HD4200, HD4400 or HD4600?"
        echo "################################################################"
        read -r -p "y/n: " hd4xxx_choice
        case $hd4xxx_choice in
            Y|y|YES|Yes|yes )
                add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).device-id" data
                set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).device-id" data 12040000
            ;;
            N|n|NO|No|no )
                echo "" > /dev/null
            ;;
            * )
                error "Invalid Choice"
                hd4xxx
            ;;
        esac
    }
    hd4xxx
    add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-patch-enable" data
    set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-patch-enable" data 01000000
    add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-cursormem" data
    set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-cursormem" data 00009000
    set_plist Kernel.Quirks.AppleCpuPmCfgLock bool True
    set_plist Kernel.Quirks.AppleXcpmCfgLock bool True
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
    hplaptop() {
        echo "################################################################"
        echo "Is your laptop a HP laptop?"
        echo "################################################################"
        read -r -p "y/n: " hplaptop_choice
        case $hplaptop_choice in
            Y|y|YES|Yes|yes )
                set_plist Kernel.Quirks.LapicKernelPanic bool True
            ;;
            n|N|No|NO|no )
                echo "" > /dev/null
            ;;
            * )
                error "Invalid Choice"
                hplaptop
        esac
    }
    hplaptop
    set_plist Kernel.Quirks.PanicNoKextDump bool True
    set_plist Kernel.Quirks.PowerTimeoutKernelPanic bool True
    case $os_choice in
        4|5 )
            set_plist Kernel.Quirks.XhciPortLimit True
        ;;
    esac
    
    platforminfo() {
        echo "################################################################"
        echo "Now, we need to pick an SMBIOS."
        echo "Pick the closest one to your hardware"
        echo "1. MacBookAir6,1 - CPU: Dual Core 15W	- GPU: HD 5000 - Display: 11inch"
        echo "2. MacBookAir6,2 - CPU: Dual Core 15W	- GPU: HD 5000 - Display: 13inch"
        echo "3. MacBookPro11,1 - CPU: Dual Core 28W - GPU: Iris 5100 - Display: 13inch"
        echo "4. MacBookPro11,2 - CPU: Quad Core 45W - GPU: Iris Pro 5200 - Display: 15inch"
        echo "5. MacBookPro11,3 - CPU: Quad Core 45W - GPU: Iris Pro 5200 + dGPU: GT 750M - Display: 15inch"
        echo "6. MacBookPro11,4 - CPU: Quad Core 45W - GPU: Iris Pro 5200 - Display: 15inch"
        echo "7. MacBookPro11,5 - CPU: Quad Core 45W - GPU: Iris Pro 5200 + dGPU: R9 M370X - Display: 15inch"
        echo "8. Macmini7,1 - CPU: NUC Systems - GPU: HD 5000/Iris 5100	- Display: N/A"
        echo "################################################################"
        read -r -p "Pick a number 1-8: " smbios_choice
        case $smbios_choice in
            1 )
                case $os_choice in
                    1|2 )
                        error "This SMBIOS is not supported in macOS Monterey or higher! Please pick another."
                        platforminfo
                    ;;
                    * )
                        smbiosname="MacBookAir6,1"
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
                        smbiosname="MacBookAir6,2"
                    ;;
                esac
            ;;
            3 )
                case $os_choice in
                    1|2 )
                        error "This SMBIOS is not supported in macOS Monterey or higher! Please pick another."
                        platforminfo
                    ;;
                    * )
                        smbiosname="MacBookPro11,1"
                    ;;
                esac
            ;;
            4 )
                case $os_choice in
                    1|2 )
                        error "This SMBIOS is not supported in macOS Monterey or higher! Please pick another."
                        platforminfo
                    ;;
                    * )
                        smbiosname="MacBookPro11,2"
                    ;;
                esac
            ;;
            5 )
                case $os_choice in
                    1|2 )
                        error "This SMBIOS is not supported in macOS Monterey or higher! Please pick another."
                        platforminfo
                    ;;
                    * )
                        smbiosname="MacBookPro11,3"
                    ;;
                esac
            ;;
            6 )
                smbiosname="MacBookPro11,4"
            ;;
            7 )
                smbiosname="MacBookPro11,5"
            ;;
            8 )
                smbiosname="Macmini7,1"
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
    set_plist UEFI.Quirks.ReleaseUsbOwnership bool True
    set_plist UEFI.Quirks.IgnoreInvalidFlexRatio bool True
    case $hplaptop_choice in
        y|Yes|YES|Y|yes )
            set_plist UEFI.Quirks.UnblockFsConnect bool True
        ;;
    esac
    warning "You must enable CFG-Lock in BIOS."
}