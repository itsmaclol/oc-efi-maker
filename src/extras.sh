extras() {
    check_folder_structure() {
        local userpath="$1"

        if [ -d "$userpath" ]; then
            echo "" > /dev/null
        else
            echo "Base directory '$userpath' does not exist."
            exit 1
        fi

        local folders=("BOOT" "OC" "OC/ACPI")
        local kexts_dir="$userpath/OC/Kexts"
        local drivers_dir="$userpath/OC/Drivers"

        for folder in "${folders[@]}"; do
            if [ ! -d "$userpath/$folder" ]; then
                echo "Directory '$userpath/$folder' does not exist."
                exit 1
            fi
        done

        if [ -d "$kexts_dir" ] && [ "$(find "$kexts_dir" -name '*.kext' -print -quit)" ]; then
            echo "" > /dev/null
        else
            echo "No Kexts found in '$kexts_dir'."
            exit 1
        fi

        if [ -d "$drivers_dir" ] && [ "$(find "$drivers_dir" -name '*.efi' -print -quit)" ]; then
            echo "" > /dev/null
        else
            echo "No Drivers found in '$drivers_dir'."
            exit 1
        fi
        check_file() {
            if [ -e "$1" ]; then
                echo "" > /dev/null
            else
                echo "File '$1' does not exist."
                exit 1
            fi
        }
        check_file "$userpath/OC/config.plist"
    }
    efipath() {
        echo ""
        echo "################################################################"
        echo "Where is your EFI folder?"
        echo "################################################################"
        read -r -p "Enter EFI folder path: " efipath
        if [ -z "$efipath" ]; then
            error "Invalid Path"
            efipath
        fi
        check_folder_structure "$efipath"
    }
    oc_type() {
        echo ""
        echo "################################################################"
        echo "What type of OpenCore do you have?"
        echo "1. Release"
        echo "2. Debug"
        echo "################################################################"
        read -r -p "Pick a number 1-2: " oc_type
        case $oc_type in
            1 )
                oc_type="RELEASE"
            ;;
            2 )
                oc_type="DEBUG"
            ;;
            * )
                error "Invalid Choice"
                oc_type
            ;;
        esac
    }
    oc_version() {
        echo ""
        echo "################################################################"
        echo "What version of OpenCore do you have?"
        echo "################################################################"
        read -r -p "Enter OpenCore Version (ex 0.9.5): " oc_ver
        if [[ "$oc_ver" =~ ^0\.[0-9]+\.[0-9]+$ ]]; then
            if [[ "$oc_ver" < "0.5.7" ]]; then
                error "OpenCore version must be 0.5.7 or higher for boot picker to work. Please update opencore."
                exit 1
            else
                oc_ver="$oc_ver"
            fi    
        else
            error "Invalid Version"
            oc_version
        fi
    }
    addplist() {
        python3 "$dir"/temp/plisteditor.py -s add "$1" --type "$2" --path "$efipath"OC//config.plist
    }

    setplist() {
        python3 "$dir"/temp/plisteditor.py -s set "$1" --type "$2" --value "$3" --path "$efipath"/OC/config.plist
    }

    deleteplist() {
        python3 "$dir"/temp/plisteditor.py -s delete "$1" --path "$efipath"/OC/config.plist
    }

    changeplist() {
        python3 "$dir"/temp/plisteditor.py -s change "$1" --new_type "$2" --path "$efipath"/OC/config.plist
    }

    opencanopy() {
        info "Downloading OpenCanopy.efi for OpenCore $oc_ver $oc_type..."
        opencore_url="https://github.com/acidanthera/OpenCorePkg/releases/download/$oc_ver/OpenCore-$oc_ver-$oc_type.zip"
        response=$(curl -s -o /dev/null -w "%{http_code}" "$opencore_url")
        if [ "$response" -eq 404 ]; then
            error "The OpenCore URL could not be downloaded, this may be of an invalid opencore version, or a missing internet connection."
            exit 1
        fi
        opencore_name="$dir/OpenCore-$oc_ver-$oc_type.zip"
        download_file "$opencore_url" "$opencore_name"
        unzip -q "$dir"/OpenCore-"$oc_ver"-"$oc_type".zip -d "$dir"/OpenCore-"$oc_ver"-"$oc_type"
        mv "$dir"/OpenCore-"$oc_ver"-"$oc_type"/X64/EFI/OC/Drivers/OpenCanopy.efi "$efipath"/OC/Drivers/OpenCanopy.efi
        git clone -q https://github.com/corpnewt/OCSnapshot "$dir"/temp/OCSnapshot
        python3 "$dir"/temp/OCSnapshot/OCSnapshot.py -i "$efipath"/OC/config.plist -s "$efipath"/OC &> /dev/null
        info "Downloading necessary OCBinaryData for themes..."
        git clone -q https://github.com/acidanthera/OcBinaryData.git "$dir"/temp/OcBinaryData
        rm -rf "$efipath"/OC/Resources
        mv "$dir"/temp/OcBinaryData/Resources "$efipath"/OC/Resources
        setplist Misc.Boot.PickerMode string External
        setplist Misc.Boot.PickerAttributes int 17
        pickervariant() {
            echo "################################################################"
            echo "What picker variant would you like?"
            echo "1. Acidanthera\Syrah — Normal icon set."
            echo "2. Acidanthera\GoldenGate — Modern icon set."
            echo "3. Acidanthera\Chardonnay — Vintage icon set."
            echo "################################################################"
            read -r -p "Pick a number 1-2: " picker_variant
            case $picker_variant in
                1 )
                    picker_variant="Acidanthera\Syrah"
                ;;
                2 )
                    picker_variant="Acidanthera\GoldenGate"
                ;;
                3 )
                    picker_variant="Acidanthera\Chardonnay"
                ;;
                * )
                    error "Invalid Choice"
                    pickervariant
                ;;
            esac
        }
        pickervariant
        setplist Misc.Boot.PickerVariant string "$picker_variant"
        info "Theme $picker_variant has been enabled."
        info "Done!"
        exit 1
    }
    audiodevice() {
        echo ""
        echo "################################################################" 
        echo "Please enter the Device path (PciRoot) of your audio controller"
        echo "Run /path/to/gfxutil -f HDEF to find it"
        echo "An example of a device path is PciRoot(0x0)/Pci(0x1f,0x3)"
        echo "################################################################"
        read -r -p "Enter Device Path: " audiodevice
        if [[ "$audiodevice" =~ ^PciRoot\(0x[0-9a-fA-F]+\)/Pci\(0x[0-9a-fA-F]+,0x[0-9a-fA-F]+\)$ ]]; then
            audiodevice="$audiodevice"
        else
            error "$audiodevice is not a valid device path"
            audiodevice
        fi

    }
    bootchime() {
        info "Downloading AudioDxe.efi for OpenCore $oc_ver $oc_type..."
        opencore_url="https://github.com/acidanthera/OpenCorePkg/releases/download/$oc_ver/OpenCore-$oc_ver-$oc_type.zip"
        response=$(curl -s -o /dev/null -w "%{http_code}" "$opencore_url")
        if [ "$response" -eq 404 ]; then
            error "The OpenCore URL could not be downloaded, this may be of an invalid opencore version, or a missing internet connection."
            exit 1
        fi
        opencore_name="$dir/OpenCore-$oc_ver-$oc_type.zip"
        download_file "$opencore_url" "$opencore_name"
        unzip -q "$dir"/OpenCore-"$oc_ver"-"$oc_type".zip -d "$dir"/OpenCore-"$oc_ver"-"$oc_type"
        mv "$dir"/OpenCore-"$oc_ver"-"$oc_type"/X64/EFI/OC/Drivers/AudioDxe.efi "$efipath"/OC/Drivers/AudioDxe.efi
        git clone -q https://github.com/corpnewt/OCSnapshot "$dir"/temp/OCSnapshot
        python3 "$dir"/temp/OCSnapshot/OCSnapshot.py -i "$efipath"/config.plist -s "$efipath"EFI/OC &> /dev/null
        info "Downloading OCBinaryData..."
        git clone -q https://github.com/acidanthera/OcBinaryData.git "$dir"/temp/OcBinaryData
        rm -rf "$efipath"/OC/Resources
        mv "$dir"/temp/OcBinaryData/Resources "$efipath"/OC/Resources
        setplist NVRAM.Add.7C436110-AB2A-4BBB-A880-FE41995C9F82.SystemAudioVolume data 0x46
        setplist UEFI.Audio.AudioCodec int 0
        setplist UEFI.Audio.AudioDevice string "$audiodevice"
        setplist UEFI.Audio.AudioOutMask int -1
        setplist UEFI.Audio.AudioSupport bool True
        setplist UEFI.Audio.DisconnectHda bool False
        setplist UEFI.Audio.MaximumGain int -15
        setplist UEFI.Audio.MinimumAssistGain int -30
        setplist UEFI.Audio.MinimumAudibleGain int -55
        setplist UEFI.Audio.PlayChime string Enabled
        setplist UEFI.Audio.ResetTrafficClass bool False
        setplist UEFI.Audio.SetupDelay int 0
        warning "Some codecs many need extra time for setup, we recommend setting UEFI:Audio:SetupDelay to 500 milliseconds (0.5 seconds) if you have issues"
        sleep 5
        info "Done!"
        info "Bootchime has been enabled."
        exit 1
    }
    kexts() {
        echo ""
        echo "################################################################"
        echo "What kexts would you like to install?"
        echo "1. CpuTscSync"
        echo "2. RealtekCardReader"
        echo "3. RestrictEvents"
        echo "4. CtlnaAHCIPort"
        echo "5. SATA-Unsupported"
        echo "6. HoRNDIS"
        echo "################################################################"
        read -r -p "Pick your kexts (ex 1 2): " kexts_choice
        for option in $kexts_choice ; do
        if [[ $option =~ ^[1-6]$ ]]; then
            case $option in
                1 )
                    CPUTSCSYNC_RELEASE_NUMBER=$(curl -s "$CPUTSCSYNC_URL" | jq -r '.tag_name')
                    CPUTSCSYNC_RELEASE_URL=$(curl -s "$CPUTSCSYNC_URL" | jq -r '.assets[] | select(.name | match("CpuTscSync-[0-9]\\.[0-9]\\.[0-9]-RELEASE")) | .browser_download_url')
                    if [ -z "$CPUTSCSYNC_RELEASE_URL" ]; then
                        error "CpuTscSync Release URL not found, is GitHub rate-limiting you?"
                        exit 1
                    fi
                    download_file "$CPUTSCSYNC_RELEASE_URL" "$dir"/temp/CpuTscSync.zip
                    info "Downloaded CpuTscSync $CPUTSCSYNC_RELEASE_NUMBER"
                    unzip -q "$dir"/temp/CpuTscSync.zip -d "$dir"/temp/CpuTscSync
                    mv "$dir"/temp/CpuTscSync/CpuTscSync.kext "$efipath"/OC/Kexts/CpuTscSync.kext
                ;;
                2 )
                    REALTEKCARDREADER_RELEASE_NUMBER=$(curl -s "$REALTEKCARDREADER_URL" | jq -r '.tag_name')
                    REALTEKCARDREADER_RELEASE_URL=$(curl -s "$REALTEKCARDREADER_URL" | jq -r '.assets[] | select(.name | contains("RealtekCardReader_") and contains("_RELEASE.zip")) | .browser_download_url')
                    if [ -z "$REALTEKCARDREADER_RELEASE_URL" ]; then
                        error "RealtekCardReader Release URL not found, is GitHub rate-limiting you?"
                        exit 1
                    fi
                    download_file "$REALTEKCARDREADER_RELEASE_URL" "$dir"/temp/RealtekCardReader.zip
                    info "Downloaded RealtekCardReader $REALTEKCARDREADER_RELEASE_NUMBER" 
                    unzip -q "$dir"/temp/RealtekCardReader.zip -d "$dir"/temp/RealtekCardReader
                    mv "$dir"/temp/RealtekCardReader/RealtekCardReader.kext "$efipath"/OC/Kexts/RealtekCardReader.kext
                    REALTEKCARDREADERFRIEND_RELEASE_URL=$(curl -s "$REALTEKCARDREADERFRIEND_URL" | jq -r '.assets[] | select(.name | contains("RealtekCardReaderFriend_") and contains("_RELEASE.zip")) | .browser_download_url')
                    REALTEKCARDREADERFRIEND_RELEASE_NUMBER=$(curl -s "$REALTEKCARDREADERFRIEND_URL" | jq -r '.tag_name')
                    if [ -z "$REALTEKCARDREADERFRIEND_RELEASE_URL" ]; then
                        error "RealtekCardReaderFriend Release URL not found, is GitHub rate-limiting you?"
                        exit 1
                    fi
                    download_file "$REALTEKCARDREADERFRIEND_RELEASE_URL" "$dir"/temp/RealtekCardReaderFriend.zip
                    info "Downloaded RealtekCardReaderFriend $REALTEKCARDREADERFRIEND_RELEASE_NUMBER"
                    unzip -q "$dir"/temp/RealtekCardReaderFriend.zip -d "$dir"/temp/RealtekCardReaderFriend
                    mv "$dir"/temp/RealtekCardReaderFriend/RealtekCardReaderFriend.kext "$efipath"/OC/Kexts/RealtekCardReaderFriend.kext
                ;;
                3 )
                    RESTRICTEVENTS_RELEASE_NUMBER=$(curl -s "$RESTRICTEVENTS_URL" | jq -r '.tag_name')
                    RESTRICTEVENTS_RELEASE_URL=$(curl -s "$RESTRICTEVENTS_URL" | jq -r '.assets[] | select(.name | match("RestrictEvents-[0-9]\\.[0-9]\\.[0-9]-RELEASE")) | .browser_download_url')
                    if [ -z "$RESTRICTEVENTS_RELEASE_URL" ]; then
                        error "RestrictEvents Release URL not found, is GitHub rate-limiting you?"
                        exit 1
                    fi
                    info "Downloaded RestrictEvents $RESTRICTEVENTS_RELEASE_NUMBER"
                    download_file "$RESTRICTEVENTS_RELEASE_URL" "$dir"/temp/RestrictEvents.zip
                    unzip -q "$dir"/temp/RestrictEvents.zip -d "$dir"/temp/RestrictEvents
                    mv "$dir"/temp/RestrictEvents/RestrictEvents.kext "$efipath"/OC/Kexts/RestrictEvents.kext
                ;;
                4 )
                    download_file "$CTLNAAHCIPORT_URL" "$dir"/temp/CtlnaAHCIPort.kext.zip
                    info "Downloaded CtlnaAHCIPort"
                    unzip -q "$dir"/temp/CtlnaAHCIPort.kext.zip -d "$dir"/temp/CtlnaAHCIPort
                    mv "$dir"/temp/CtlnaAHCIPort/CtlnaAHCIPort.kext "$efipath"/OC/Kexts/CtlnaAHCIPort.kext
                ;;
                5 )
                    download_file "$SATA_UNSUPPORTED_URL" "$dir"/temp/SATA-Unsupported.kext.zip
                    info "Downloaded SATA-Unsupported"
                    unzip -q "$dir"/temp/SATA-Unsupported.kext.zip -d "$dir"/temp/SATA-Unsupported
                    mv "$dir"/temp/SATA-Unsupported/SATA-Unsupported.kext "$efipath"/OC/Kexts/SATA-Unsupported.kext                
                ;;
                6 )
                    download_file "$HORNDIS_URL" "$dir"/temp/HoRNDIS.kext.zip
                    info "Downloaded HoRNDIS"
                    unzip -q "$dir"/temp/HoRNDIS.kext.zip -d "$dir"/temp/HoRNDIS
                    mv "$dir"/temp/HoRNDIS/HoRNDIS.kext "$efipath"/OC/Kexts/HoRNDIS.kext
                ;;
            esac
        else    
            error "Invalid option: $option"
            kexts
        fi
        done
        git clone -q https://github.com/corpnewt/OCSnapshot "$dir"/temp/OCSnapshot
        python3 "$dir"/temp/OCSnapshot/OCSnapshot.py -i "$efipath"/OC/config.plist -s "$efipath"/OC &> /dev/null
        info "Done!"
        exit 1
    }
    menu() {
        echo "################################################################"
        echo "Welcome to the extras menu."
        echo "1. Enable OpenCanopy GUI boot picker"
        echo "2. Enable Boot Chime"
        echo "3. Install extra kexts"
        echo "################################################################"
        read -r -p "Pick a number 1-3: " extras_choice
        case $extras_choice in
            1 )
                oc_version
                oc_type
                efipath
                opencanopy
            ;;
            2 )
                oc_version
                oc_type
                efipath
                audiodevice
                bootchime

            ;;
            3 )
                efipath
                kexts
            ;;
            * )
                error "Invalid Choice"
                menu
            ;;
        esac
    }
    menu
}
