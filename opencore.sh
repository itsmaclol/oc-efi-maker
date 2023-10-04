#!/usr/bin/env bash
os=$(uname)
realdir="${0%/*}"
dir="$realdir/output"
src="$realdir/src"
rm -rf "$dir"
rm -rf "$dir/temp"
mkdir "$dir"
mkdir "$dir"/temp
source ./src/vars.sh
source ./src/funcs.sh
source ./src/extras.sh
source ./src/amdkernelpatches.sh
source ./src/intel_desktop_plist.sh
source ./src/intel_laptop_plist.sh
source ./src/amd_desktop_plist.sh
source ./src/intel_server_plist.sh

clear

case $os in
    Darwin )
        if [ "$(uname -m | head -c2)" = "iP" ]; then
            error "This script is not meant to be used on an iDevice. Please use a Mac/Hackintosh to use this script."
            exit 1
        fi

        if ! command -v "brew" > /dev/null; then
            warning "Homebrew is not installed. Would you like to install it? (y/n)"
            read -r -p "y/n: " install_brew
            case $install_brew in
                y|Y|YES|Yes|yes )
                    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
                ;;
                n|N|No|NO|no )
                    error "Brew is needed to install dependencies"
                    exit 1
                ;;
            esac
        fi
        ;;
    Linux )
        get_distribution
        get_package_manager
    ;;
    * )
        error "Unsupported OS."
        exit 1
esac

dependencies() {
    dependencies=("jq" "curl" "python3" "unzip" "git" "aria2")
    missing_dependencies=()

    for dep in "${dependencies[@]}"; do
        if [[ "$dep" == "aria2" ]]; then
            # aria2c complications 
            if ! command -v "aria2c" > /dev/null; then
                missing_dependencies+=("$dep")
            fi
        else
            if ! command -v "$dep" > /dev/null; then
                missing_dependencies+=("$dep")
            fi
        fi
    done

    if [[ ${#missing_dependencies[@]} -gt 0 ]]; then
        info "Dependencies are missing, would you like to install them?"
        read -r -p "y/n: " install_deps
        case $install_deps in
            y|Y|Yes|YES|yes )
                if [[ "$(uname)" == "Darwin" && -x "$(command -v brew)" ]]; then
                    # Install the missing dependencies using brew
                    brew install "${missing_dependencies[@]}"
                    info "Dependencies installed, please rerun this script."
                    exit 1
                elif [[ "$(uname)" == "Linux" ]]; then
                    case $PACKAGE_MANAGER in
                        "pacman" )
                            # Install dependencies using pacman
                            sudo pacman -Syu "${missing_dependencies[@]}" --noconfirm
                        ;;
                        "apt-get" )
                            # apt
                            sudo apt-get update
                            sudo apt-get install "${missing_dependencies[@]}" -y
                        ;;
                        "yum"|"dnf" )
                            # yum/dnf, same thing tbh
                            sudo dnf update
                            sudo dnf install "${missing_dependencies[@]}" -y
                        ;;
                        "apk" )
                            # apk for alpine
                            sudo apk update
                            sudo apk add "${missing_dependencies[@]}"
                        ;;
                        "zypper" )
                            # and zypper for openSUSE
                            sudo zypper refresh
                            sudo zypper --non-interactive install "${missing_dependencies[@]}"
                        ;;
                    esac
                    info "Dependencies installed, please rerun this script."
                    exit 1
                else
                    error "Unsupported operating system. You need to install ${missing_dependencies[*]} manually."
                    exit 1
                fi
            ;;
            * )
                error "${missing_dependencies[*]} is/are needed for the script to work as intended."
                exit 1
            ;;
        esac
    fi
}

download_file() {
    aria2c -x16 -s16 -j16 "$1" -o "$2" &> /dev/null
}

case $1 in
    "--ignore-internet-check" )
        dependencies
    ;;
    "--ignore-dependencies" )
        internet_check
    ;;
    "--ignore-deps-internet-check" )
        echo "" > /dev/null
    ;;
    "-h"|"--help" )
        help_page
    ;;
    "--extras" )
        download_file "$PLISTEDITOR_URL" "$dir"/temp/plisteditor.py
        extras
    ;;
    "" )
        internet_check
        dependencies
    ;;
    * )
        error "Invalid arg $1"
        exit 1
    ;;  
esac
download_file "$PLISTEDITOR_URL" "$dir"/temp/plisteditor.py
echo "################################################################"
echo "Welcome to OC-EFI-Maker."
echo "Made with <3 by Mac"
echo "################################################################"
echo ""


opencore() {
    echo "################################################################"
    echo "Please pick the version of OpenCore you would like to download."
    echo "1. Release"
    echo "2. Debug"
    echo "################################################################"
    read -r -p "Pick a number 1 or 2: " oc_choice

    OC_RELEASE_NUMBER=$(curl -s "$OC_URL" | jq -r '.tag_name')
    RELEASE_URL=$(curl -s "$OC_URL" | jq -r '.assets[] | select(.name | match("OpenCore-[0-9]\\.[0-9]\\.[0-9]-RELEASE")) | .browser_download_url')
    DEBUG_URL=$(curl -s "$OC_URL" | jq -r '.assets[] | select(.name | match("OpenCore-[0-9]\\.[0-9]\\.[0-9]-DEBUG")) | .browser_download_url')

    if [ -z "$RELEASE_URL" ] && [ -z "$DEBUG_URL" ]; then
        error "No RELEASE or DEBUG version found in the assets, is GitHub rate-limiting you?"
        exit 1
    fi

    case $oc_choice in
        1 )
            DOWNLOAD_URL="$RELEASE_URL"
            rldb="Release"
        ;;
        2 )
            DOWNLOAD_URL="$DEBUG_URL"
            rldb="Debug"
        ;;
        * )
            error "Invalid Choice"
            opencore
    esac
    download_file "$DOWNLOAD_URL" "$dir"/temp/OpenCore.zip
    unzip -q "$dir"/temp/OpenCore.zip -d "$dir"/temp/OpenCore
    info "Downloaded OpenCore $rldb $OC_RELEASE_NUMBER"
}
opencore 

macos_choice(){
    echo ""
    echo "################################################################"
    echo "Next, for the macOS Version."
    echo "1: macOS 13 Ventura"
    echo "2: macOS 12 Monterey"
    echo "3: macOS 11 Big Sur"
    echo "4: macOS 10.15 Catalina"
    echo "5: macOS 10.14 Mojave"
    echo "Info: For any macOS lower than this, you will need to follow the guide yourself."
    echo "################################################################"
    read -r -p "Pick a number 1-5: " os_choice
    mkdir -p "$dir"/EFI/com.apple.recovery.boot
    case $os_choice in
        1 )
            os_name="Ventura"  
            info "Downloading macOS Ventura, please wait..."
            python3 "$dir"/temp/OpenCore/Utilities/macrecovery/macrecovery.py -b Mac-4B682C642B45593E -m 00000000000000000 download -o "$dir"/com.apple.recovery.boot
        ;;
        2 )
            os_name="Monterey"
            info "Downloading macOS Monterey, please wait..."
            #python3 "$dir"/temp/OpenCore/Utilities/macrecovery/macrecovery.py -b Mac-FFE5EF870D7BA81A -m 00000000000000000 download -o "$dir"/com.apple.recovery.boot
        ;;
        3 )
            os_name="BigSur"
            info "Downloading macOS Big Sur, please wait..."
            python3 "$dir"/temp/OpenCore/Utilities/macrecovery/macrecovery.py -b Mac-42FD25EABCABB274 -m 00000000000000000 download -o "$dir"/com.apple.recovery.boot
        ;;
        4 )
            os_name="Catalina"
            info "Downloading macOS Catalina, please wait..."
            python3 "$dir"/temp/OpenCore/Utilities/macrecovery/macrecovery.py -b Mac-00BE6ED71E35EB86 -m 00000000000000000 download -o "$dir"/com.apple.recovery.boot
        ;;
        5 )
            os_name="Mojave"
            info "Downloading macOS Mojave, please wait..."
            python3 "$dir"/temp/OpenCore/Utilities/macrecovery/macrecovery.py -b Mac-7BA5B2DFE22DDD8C -m 00000000000KXPG00 download -o "$dir"/com.apple.recovery.boot
        ;;
        * )
            error "Invalid Choice"
            macos_choice
    esac
}
macos_choice

info "Setting up EFI Folder Structure..."
mkdir -p "$dir"/EFI/EFI
mv "$dir"/temp/OpenCore/X64/EFI "$dir"/EFI
efi="$dir"/EFI/EFI/OC
find "$efi"/Drivers ! -name "OpenRuntime.efi" -type f -exec rm -f {} +
find "$efi"/Tools ! -name "OpenShell.efi" -type f -exec rm -f {} +
mv "$dir"/temp/OpenCore/Docs/Sample.plist "$efi"/config.plist

download_file https://github.com/acidanthera/OcBinaryData/raw/master/Drivers/HfsPlus.efi "$efi"/Drivers/HfsPlus.efi
info "Downloaded HfsPlus.efi"
LILU_RELEASE_URL=$(curl -s "$LILU_URL" | jq -r '.assets[] | select(.name | match("Lilu-[0-9]\\.[0-9]\\.[0-9]-RELEASE")) | .browser_download_url')
if [ -z "$LILU_RELEASE_URL" ]; then
    error "Lilu release URL not found, is GitHub rate-limiting you?"
    exit 1
fi
LILU_RELEASE_NUMBER=$(curl -s "$LILU_URL" | jq -r '.tag_name')
download_file "$LILU_RELEASE_URL" "$dir"/temp/Lilu.zip
info "Downloaded Lilu $LILU_RELEASE_NUMBER"
unzip -q "$dir"/temp/Lilu.zip -d "$dir"/temp/Lilu
mv "$dir"/temp/Lilu/Lilu.kext "$efi"/Kexts/Lilu.kext


VIRTUALSMC_RELEASE_URL=$(curl -s "$VIRTUALSMC_URL" | jq -r '.assets[] | select(.name | match("VirtualSMC-[0-9]\\.[0-9]\\.[0-9]-RELEASE")) | .browser_download_url')
if [ -z "$VIRTUALSMC_RELEASE_URL" ]; then
    error "VirtualSMC release URL not found, is GitHub rate-limiting you?"
    exit 1
fi
VIRTUALSMC_RELEASE_NUMBER=$(curl -s "$VIRTUALSMC_URL" | jq -r '.tag_name')
download_file "$VIRTUALSMC_RELEASE_URL" "$dir"/temp/VirtualSMC.zip
info "Downloaded VirtualSMC $VIRTUALSMC_RELEASE_NUMBER"
unzip -q "$dir"/temp/VirtualSMC.zip -d "$dir"/temp/VirtualSMC
mv "$dir"/temp/VirtualSMC/Kexts/VirtualSMC.kext "$efi"/Kexts/VirtualSMC.kext

APPLEALC_RELEASE_URL=$(curl -s "$APPLEALC_URL" | jq -r '.assets[] | select(.name | match("AppleALC-[0-9]\\.[0-9]\\.[0-9]-RELEASE")) | .browser_download_url')
if [ -z "$APPLEALC_RELEASE_URL" ]; then
    error "AppleALC release URL not found, is GitHub rate-limiting you?"
    exit 1
fi
APPLEALC_RELEASE_NUMBER=$(curl -s "$APPLEALC_URL" | jq -r '.tag_name')
download_file "$APPLEALC_RELEASE_URL" "$dir"/temp/AppleALC.zip
info "Downloaded AppleALC $APPLEALC_RELEASE_NUMBER..."
unzip -q "$dir"/temp/AppleALC.zip -d "$dir"/temp/AppleALC
mv "$dir"/temp/AppleALC/AppleALC.kext "$efi"/Kexts/AppleALC.kext

WHATEVERGREEN_RELEASE_URL=$(curl -s "$WHATEVERGREEN_URL" | jq -r '.assets[] | select(.name | match("WhateverGreen-[0-9]\\.[0-9]\\.[0-9]-RELEASE")) | .browser_download_url')
if [ -z "$WHATEVERGREEN_RELEASE_URL" ]; then
    error "AppleALC release URL not found, is GitHub rate-limiting you?"
    exit 1
fi
WHATEVERGREEN_RELEASE_NUMBER=$(curl -s "$WHATEVERGREEN_URL" | jq -r '.tag_name')
download_file "$WHATEVERGREEN_RELEASE_URL" "$dir"/temp/WhateverGreen.zip
info "Downloaded WhateverGreen $WHATEVERGREEN_RELEASE_NUMBER..."
unzip -q "$dir"/temp/WhateverGreen.zip -d "$dir"/temp/WhateverGreen
mv "$dir"/temp/WhateverGreen/WhateverGreen.kext "$efi"/Kexts/WhateverGreen.kext

pc() {
    echo ""
    echo "################################################################"
    echo "Now, we're going to need some info before we continue."
    echo "Is this hackintosh a Laptop or a Desktop?"
    echo "1. Desktop"
    echo "2. Laptop"
    echo "################################################################"
    read -r -p "Pick a number 1 or 2: " pc_choice 
    case $pc_choice in
        1 )
            echo "" > /dev/null
        ;;
        2 ) 
            echo "" > /dev/null
        ;;
        * )
            error "Invalid choice."
            pc
        ;;
    esac
}
pc

amdcpu() {
    echo ""
    echo "################################################################"
    echo "Do you have an AMD CPU?"
    echo "################################################################"
    read -r -p "y/n: " amd_cpu
    case $amd_cpu in
        y|Y|Yes|YES|yes )
            amd_cpu=True
        ;;
        n|N|No|NO|no )
            amd_cpu=False
        ;;
        * )
            error "Invalid Choice"
            amdcpu
        ;;
    esac
}

case $pc_choice in
    1 )
        amdcpu
    ;;
    2 )
        echo "" > /dev/null
    ;;
esac

vsmcplugins() {
    echo ""
    echo "################################################################"
    echo "Do you want VirtualSMC Plugins?"
    echo "################################################################"
    read -r -p "y/n: " vsmc_plugins
    case $vsmc_plugins in
    y|Y|Yes|YES|yes )
        vsmcplugins=True
        case $amd_cpu in
            True )
                SMCAMDPROCESSOR_RELEASE_NUMBER=$(curl -s "$SMCAMDPROCESSOR_URL" | jq -r '.tag_name')
                SMCAMDPROCESSOR_RELEASE_URL=$(curl -s "$SMCAMDPROCESSOR_URL" | jq -r '.assets[] | select(.name | contains("SMCAMDProcessor") and contains(".kext.zip")) | .browser_download_url')
                if [ -z "$SMCAMDPROCESSOR_RELEASE_URL" ]; then
                    error "SMCAMDProcessor release URL not found, is GitHub rate-limiting you?"
                    exit 1
                fi
                download_file "$SMCAMDPROCESSOR_RELEASE_URL" "$dir"/temp/SMCAMDProcessor.zip
                info "Downloaded SMCAMDProcessor $SMCAMDPROCESSOR_RELEASE_NUMBER"
                unzip -q "$dir"/temp/SMCAMDProcessor.zip -d "$dir"/temp/SMCAMDProcessor
                mv "$dir"/temp/SMCAMDProcessor/SMCAMDProcessor.kext "$efi"/Kexts/SMCAMDProcessor.kext
            ;;  
            False )
                mv "$dir"/temp/VirtualSMC/Kexts/SMCProcessor.kext "$efi"/Kexts/SMCProcessor.kext
            ;;
        esac
        mv "$dir"/temp/VirtualSMC/Kexts/SMCSuperIO.kext "$efi"/Kexts/SMCSuperIO.kext
        case $pc_choice in
            1 )
                echo "" > /dev/null
            ;;
            2 ) 
                mv "$dir"/temp/VirtualSMC/Kexts/SMCBatteryManager.kext "$efi"/Kexts/SMCBatteryManager.kext
            ;;
            * )
                error "Invalid choice"
                pc
            ;;
        esac
    ;;
    n|N|No|NO|no )
        vsmcplugins=False
    ;;
    * )
        error "Invalid Choice"
        vsmcplugins
    ;;
esac

}
vsmcplugins

atiradeonplugins() {
    echo ""
    echo "################################################################"
    echo "Do you have a Radeon/ATI Graphics card?"
    echo "################################################################"
    read -r -p "y/n: " ati_radeon_plugins
    case $ati_radeon_plugins in
        y|Y|Yes|YES|yes )
            RADEONSENSOR_RELEASE_URL=$(curl -s "$RADEONSENSOR_URL" | jq -r '.assets[] | select(.name | match("RadeonSensor-[0-9]\\.[0-9]\\.[0-9]-RELEASE")) | .browser_download_url')
            SMCRADEONGPU_RELEASE_URL=$(curl -s "$RADEONSENSOR_URL" | jq -r '.assets[] | select(.name | match("SMCRadeonGPU-[0-9]\\.[0-9]\\.[0-9]-RELEASE")) | .browser_download_url')
            RADEONSENSOR_RELEASE_NUMBER=$(curl -s "$RADEONSENSOR" | jq -r '.tag_name')
            if [ -z "$RADEONSENSOR_RELEASE_URL" ]; then
                error "RadeonSensor release URL not found, is GitHub rate-limiting you?"
                exit 1
            fi
            download_file "$RADEONSENSOR_RELEASE_URL" "$dir"/temp/RadeonSensor.zip
            info "Downloaded RadeonSensor $RADEONSENSOR_RELEASE_NUMBER"
            if [ -z "$SMCRADEONGPU_RELEASE_URL" ]; then
                error "SMCRadeonGPU release URL not found, is GitHub rate-limiting you?"
                exit 1
            fi
            download_file "$SMCRADEONGPU_RELEASE_URL" "$dir"/temp/SMCRadeonGPU.zip
            info "Downloaded SMCRadeonGPU $RADEONSENSOR_RELEASE_NUMBER"
            unzip -q "$dir"/temp/RadeonSensor.zip -d "$dir"/temp/RadeonSensor
            unzip -q "$dir"/temp/SMCRadeonGPU.zip -d "$dir"/temp/SMCRadeonGPU
            mv "$dir"/temp/RadeonSensor/RadeonSensor.kext "$efi"/Kexts/RadeonSensor.kext
            mv "$dir"/temp/SMCRadeonGPU/SMCRadeonGPU.kext "$efi"/Kexts/SMCRadeonGPU.kext
        ;;
        n|N|No|NO|no )
            echo "" > /dev/null
        ;;
        * )
            error "Invalid Choice"
            atiradeonplugins
        ;;
    esac
}

case $vsmcplugins in
    True )
        atiradeonplugins
    ;;
esac

ethernet() {
    echo "################################################################"
    echo "Next, we're going to need to ask you about hardware."
    echo "Let's begin with Ethernet."
    echo "1. IntelMausi (Intel's 82578, 82579, I217, I218 and I219 NICs are officially supported)"
    echo "2. AppleIGB (Required for I211 NICs running on macOS Monterey and above, requires macOS 12 and higher)"
    echo "3. SmallTreeIntel82576 (Required for I211 NICs running on macOS versions up to Big Sur, based off of the SmallTree kext but patched to support I211)"
    echo "4. AtherosE2200Ethernet (Required for Atheros and Killer NICs) Note: Atheros Killer E2500 models are actually Realtek based, for these systems please use RealtekRTL8111 instead"
    echo "5. RealtekRTL8111 (For Realtek's Gigabit Ethernet) NOTE: Sometimes the latest version of the kext might not work properly with your Ethernet. If you see this issue, try older versions."
    echo "6. LucyRTL8125Ethernet (For Realtek's 2.5Gb Ethernet) Requires macOS 10.15 or newer"
    echo "7. No Ethernet"
    echo "################################################################"
    read -r -p "Pick a number 1-7: " eth_choice
    case $eth_choice in
        1 )
            INTEL_MAUSI_RELEASE_URL=$(curl -s "$INTEL_MAUSI_URL" | jq -r '.assets[] | select(.name | match("IntelMausi-[0-9]\\.[0-9]\\.[0-9]-RELEASE")) | .browser_download_url')
            INTEL_MAUSI_RELEASE_NUMBER=$(curl -s "$INTEL_MAUSI_URL" | jq -r '.tag_name')
            if [ -z "$INTEL_MAUSI_RELEASE_URL" ]; then
                error "IntelMausi release URL not found, is GitHub rate-limiting you?"
                exit 1
            fi
            download_file "$INTEL_MAUSI_RELEASE_URL" "$dir"/temp/IntelMausi.zip
            info "Downloaded IntelMausi $INTEL_MAUSI_RELEASE_NUMBER"
            unzip -q "$dir"/temp/IntelMausi.zip -d "$dir"/temp/IntelMausi
            mv "$dir"/temp/IntelMausi/IntelMausi.kext "$efi"/Kexts/IntelMausi.kext
        ;;
        2 )
            case $os_choice in
                3|4|5 )
                    error "You have chosen macOS Big Sur or lower, but AppleIGB requires 12 or higher."
                    exit 1
                ;;
            esac
            download_file $APPLEIGB_URL "$dir"/temp/AppleIGB.zip
            info "Downloaded AppleIGB 5.11"
            unzip -q "$dir"/temp/AppleIGB -d "$dir"/temp/AppleIGB
            mv "$dir"/temp/AppleIGB/AppleIGB.kext "$efi"/Kexts/AppleIGB.kext
        ;;
        3 )
            download_file $SMALLTREEINTEL82576_URL "$dir"/temp/SmallTreeIntel82576.zip
            info "Downloaded SmallTreeIntel82576 1.3.0"
            unzip -q "$dir"/temp/SmallTreeIntel82576.zip -d "$dir"/temp/SmallTreeIntel82576
            mv "$dir"/temp/SmallTreeIntel82576/SmallTreeIntel82576.kext "$efi"/Kexts/SmallTreeIntel82576.kext
        ;;
        4 )
            download_file $ATHEROSE2200ETHERNET_URL "$dir"/temp/AtherosE2200Ethernet.zip
            info "Downloaded AtherosE2200Ethernet 2.2.2"
            unzip -q "$dir"/temp/AtherosE2200Ethernet.zip -d "$dir"/temp/AtherosE2200Ethernet
            mv "$dir"/temp/AtherosE2200Ethernet/AtherosE2200Ethernet-V2.2.2/Release/AtherosE2200Ethernet.kext "$efi"/Kexts/AtherosE2200Ethernet.kext
        ;;
        5 )
            
            REALTEKRTL8111_RELEASE_URL=$(curl -s "$REALTEKRTL8111_URL" | jq -r '.assets[] | select(.name | match("RealtekRTL8111-V[0-9]\\.[0-9]\\.[0-9]")) | .browser_download_url')
            REALTEKRTL8111_RELEASE_NR=$(echo "$(curl -s "$REALTEKRTL8111_URL")" | grep -o '"tag_name": "[^"]*' | grep -o '[^"]*$')

            if [ -z "$REALTEKRTL8111_RELEASE_URL" ]; then
                error "RealtekRTL8111 release URL not found, is GitHub rate-limiting you?"
                exit 1
            fi
            download_file "$REALTEKRTL8111_RELEASE_URL" "$dir"/temp/RealtekRTL8111.zip
            info "Downloaded RealtekRTL8111 $REALTEKRTL8111_RELEASE_NR"
            unzip -q "$dir"/temp/RealtekRTL8111.zip -d "$dir"/temp/RealtekRTL8111
            mv "$dir"/temp/RealtekRTL8111/RealtekRTL8111-V"$REALTEKRTL8111_RELEASE_NR"/Release/RealtekRTL8111.kext "$efi"/Kexts/RealtekRTL8111.kext
        ;;
        6 )
            case $oc_choice in 
                5 )
                    error "You have picked macOS Mojave, LucyRTL8125 which requires macOS catalina or higher."
                    exit 1
                ;;
            esac
            
            LUCYRTL8125ETHERNET_RELEASE_URL=$(curl -s "$LUCYRTL8125ETHERNET_URL" | jq -r '.assets[] | select(.name | match("LucyRTL8125Ethernet-V[0-9]\\.[0-9]\\.[0-9]")) | .browser_download_url')
            LUCYRTL8125ETHERNET_NR_RELEASE_NUMBER=$(curl -s "$LUCYRTL8125ETHERNET" | jq -r '.tag_name')
            if [ -z "$LUCYRTL8125ETHERNET_RELEASE_URL" ]; then
                error "LucyRTL8125Ethernet release URL not found, is GitHub rate-limiting you?"
                exit 1
            fi
            download_file "$LUCYRTL8125ETHERNET_RELEASE_URL" "$dir"/temp/LucyRTL8125Ethernet.zip
            info "Downloaded LucyRTL8125Ethernet $LUCYRTL8125ETHERNET_NR_RELEASE_NUMBER"
            unzip -q "$dir"/temp/LucyRTL8125Ethernet.zip -d "$dir"/temp/LucyRTL8125Ethernet
            mv "$dir"/temp/LucyRTL8125Ethernet/LucyRTL8125Ethernet-V1.1.0/Release/LucyRTL8125Ethernet.kext "$efi"/Kexts/LucyRTL8125Ethernet.kext
        ;;
        7 )
            echo "" > /dev/null
        ;;
        * )
            error "Invalid Choice"
            ethernet
        ;;
    esac
}
ethernet


echo ""
echo "################################################################"
echo "Next, we'll continue with USB."
echo "For this, we are going to use USBToolBox/USBMap"
echo "This script will automatically install the USBToolBox Kext, but the UTBToolMap will have to be made manually"
echo "You will need to run the USBToolBox application and make the kext manually"
echo "After you do that, you will need to put it into the EFI/EFI/OC/Kexts directory and then"
echo "Open your config.plist using ProperTree from CorpNewt and do an OC Snapshot."
echo "################################################################"
echo ""
sleep 7

USBTOOLBOX_KEXT_RELEASE_URL=$(curl -s "$USBTOOLBOX_KEXT_URL" | jq -r '.assets[] | select(.name | match("USBToolBox-[0-9]\\.[0-9]\\.[0-9]-RELEASE")) | .browser_download_url')

if [ -z "$USBTOOLBOX_KEXT_RELEASE_URL" ]; then
    error "USBToolBox Kext release URL not found, is GitHub rate-limiting you?"
    exit 1
fi

download_file "$USBTOOLBOX_KEXT_RELEASE_URL" "$dir"/temp/USBToolbox.zip
unzip -q "$dir"/temp/USBToolbox.zip -d "$dir"/temp/USBToolBox
mv "$dir"/temp/USBToolBox/USBToolbox.kext "$efi"/Kexts/USBToolBox.kext

wifi() {
    echo "################################################################"
    echo "Next, we have Wi-Fi."
    echo "1. Intel"
    echo "2. Broadcom"
    echo "3. None"
    echo "Info: For now, these are the only Wi-Fi brands that are supported by hackintoshing."
    echo "################################################################"
    read -r -p "Pick a number 1-3: " wifi_choice
    echo ""
    case $wifi_choice in
    1 )
        ITLWM_RELEASE_URL=$(curl -s $ITLWM_URL | jq -r --arg osname "$os_name" '.assets[] | select(.name | endswith("_stable_" + $osname + ".kext.zip")) | .browser_download_url')
        ITLWM_RELEASE_NUMBER=$(curl -s "$ITLWM_URL" | jq -r '.tag_name')
        if [ -z "$ITLWM_RELEASE_URL" ]; then
            error "AirportItlwm release URL not found, is GitHub rate-limiting you?"
            exit 1
        fi

        download_file "$ITLWM_RELEASE_URL" "$dir"/temp/AirportItlwm.zip
        info "Downloaded AirportItlwm-$os_name $ITLWM_RELEASE_NUMBER"
        unzip -q "$dir"/temp/AirportItlwm.zip -d "$dir"/temp/AirportItlwm
        mv "$dir"/temp/AirportItlwm/Airportitlwm.kext "$efi"/Kexts/Airportitlwm.kext
    ;;
    2 )
        
        AIRPORT_BRCM_RELEASE_URL=$(curl -s "$AIRPORT_BRCM_URL" | jq -r '.assets[] | select(.name | match("AirportBrcmFixup-[0-9]\\.[0-9]\\.[0-9]-RELEASE")) | .browser_download_url')
        AIRPORT_BRCM_RELEASE_NUMBER=$(curl -s "$AIRPORT_BRCM_URL" | jq -r '.tag_name')
        if [ -z "$AIRPORT_BRCM_RELEASE_URL" ]; then
            error "AirportBrcmFixup release URL not found, is GitHub rate-limiting you?"
            exit 1
        fi
        download_file "$AIRPORT_BRCM_RELEASE_URL" "$dir"/temp/AirportBrcmFixup.zip
        info "Downloaded AirportBrcmFixup $AIRPORT_BRCM_RELEASE_NUMBER"
        unzip -q "$dir"/temp/AirportBrcmFixup.zip -d "$dir"/temp/AirportBrcmFixup
        mv "$dir"/temp/AirportBrcmFixup/AirportBrcmFixup.kext "$efi"/Kexts/AirportBrcmFixup.kext
        
    ;;
    3 )
        echo "" > /dev/null
    ;;
    * )
        error "Invalid Choice"
        wifi
    ;;
esac
}
wifi

bluetooth() {
    echo "################################################################"
    echo "Now, we have Bluetooth."
    echo "1. Intel"
    echo "2. Broadcom"
    echo "3. None"
    echo "################################################################"
    read -r -p "Pick a number 1-3: " bt_choice
    echo ""
    case $bt_choice in
    1 )
        INTELBTFIRMWARE_RELEASE_URL=$(curl -s "$INTELBTFIRMWARE_URL" | jq -r '.assets[] | select(.name | match("IntelBluetooth-v[0-9]\\.[0-9]\\.[0-9]")) | .browser_download_url')
        INTELBTFIRMWARE_RELEASE_NUMBER=$(curl -s "$INTELBTFIRMWARE_URL" | jq -r '.tag_name')        
        if [ -z "$INTELBTFIRMWARE_RELEASE_URL" ]; then
            error "IntelBluetoothFirmware release URL not found, is GitHub rate-limiting you?"
            exit 1
        fi
        download_file "$INTELBTFIRMWARE_RELEASE_URL" "$dir"/temp/IntelBluetoothFirmware.zip
        info "Downloaded IntelBluetoothFirmware"
        unzip -q "$dir"/temp/IntelBluetoothFirmware.zip -d "$dir"/temp/IntelBluetoothFirmware
        mv "$dir"/temp/IntelBluetoothFirmware/IntelBluetoothFirmware.kext "$efi"/Kexts/IntelBluetoothFirmware.kext
        mv "$dir"/temp/IntelBluetoothFirmware/IntelBTPatcher.kext "$efi"/Kexts/IntelBTPatcher.kext
        case $os_choice in
            2|3|4|5 )
                mv "$dir"/temp/IntelBluetoothFirmware/IntelBluetoothInjector.kext "$efi"/Kexts/IntelBluetoothInjector.kext
            ;;
        esac
    ;;
    2 )
        BRCMPATCHRAM_RELEASE_NUMBER=$(curl -s "$BRCMPATCHRAM_URL" | jq -r '.tag_name')
        BRCMPATCHRAM_RELEASE_URL=$(curl -s "$BRCMPATCHRAM_URL" | jq -r '.assets | .[] | select(.name | endswith("-RELEASE.zip")) | .browser_download_url')
        if [ -z "$BRCMPATCHRAM_RELEASE_URL" ]; then
            error "BrcmPatchRAM release URL not found, is GitHub rate-limiting you?"
            exit 1
        fi

        download_file "$BRCMPATCHRAM_RELEASE_URL" "$dir"/temp/BrcmPatchRAM.zip
        info "Downloaded BrcmPatchRAM $AIRPORT_BRCM_RELEASE_NUMBER"
        unzip -q "$dir"/temp/BrcmPatchRAM.zip -d "$dir"/temp/BrcmPatchRAM
        mv "$dir"/temp/BrcmPatchRAM/BrcmFirmwareData.kext "$efi"/Kexts/BrcmFirmwareData.kext
        case $os_choice in
            5 )
                mv "$dir"/temp/BrcmPatchRAM/BrcmPatchRAM2.kext "$efi"/Kexts/BrcmPatchRAM2.kext
            ;;
            2|1 )
                mv "$dir"/temp/BrcmPatchRAM/BrcmPatchRAM3.kext "$efi"/Kexts/BrcmPatchRAM3.kext
            ;;
            4|3 )
                mv "$dir"/temp/BrcmPatchRAM/BrcmPatchRAM3.kext "$efi"/Kexts/BrcmPatchRAM3.kext
                mv "$dir"/temp/BrcmPatchRAM/BrcmBlueteoothInjector.kext "$efi"/Kexts/BrcmBluetoothInjector.kext
            ;;
        esac
    ;;
    3 )
        echo "" > /dev/null
    ;;
    * )
        error "Invalid Choice"
        bluetooth
    ;;
esac
case $bt_choice in
    1 )
        case $os_choice in 
            1|2 )
                BRCMPATCHRAM_RELEASE_URL=$(curl -s "$BRCMPATCHRAM_URL" | jq -r '.assets | .[] | select(.name | endswith("-RELEASE.zip")) | .browser_download_url')
                if [ -z "$BRCMPATCHRAM_RELEASE_URL" ]; then
                    error "BrcmPatchRAM release URL not found, is GitHub rate-limiting you?"
                    exit 1
                fi
                download_file "$BRCMPATCHRAM_RELEASE_URL" "$dir"/temp/BrcmPatchRAM.zip
                info "Downloaded BlueToolFixup $BRCMPATCHRAM_RELEASE_NUMBER"
                unzip -q "$dir"/temp/BrcmPatchRAM.zip -d "$dir"/temp/BrcmPatchRAM
                mv "$dir"/temp/BrcmPatchRAM/BlueToolFixup.kext "$efi"/Kexts/BlueToolFixup.kext
            ;;
        esac
    ;;
    2 )
        case $os_choice in
            1|2 )
                mv "$dir"/temp/BrcmPatchRAM/BlueToolFixup.kext "$efi"/Kexts
                info "Moved BlueToolFixup to Kexts folder"
            ;;
        esac
    ;;
esac
}
bluetooth

nvme_choice() {
    echo "################################################################"
    echo "Does your device have an NVME drive?"
    echo "################################################################"
    read -r -p "y/n: " nvme_choice
    case $nvme_choice in
        y|Y|Yes|yes|YES )
            NVMEFIX_RELEASE_URL=$(curl -s "$NVMEFIX_URL" | jq -r '.assets[] | select(.name | match("NVMeFix-[0-9]\\.[0-9]\\.[0-9]-RELEASE")) | .browser_download_url')
            NVMEFIX_RELEASE_NUMBER=$(curl -s "$NVMEFIX_URL" | jq -r '.tag_name')
            if [ -z "$NVMEFIX_RELEASE_URL" ]; then
                error "NVMeFix release URL not found, is GitHub rate-limiting you?"
                exit 1
            fi

            download_file "$NVMEFIX_RELEASE_URL" "$dir"/temp/NVMeFix.zip
            info "Downloaded NVMeFix $NVMEFIX_RELEASE_NUMBER"
            unzip -q "$dir"/temp/NVMeFix.zip -d "$dir"/temp/NVMeFix
            mv "$dir"/temp/NVMeFix/NVMeFix.kext "$efi"/Kexts/NVMeFix.kext
        ;;
        n|N|No|no|NO )
            echo "" > /dev/null
        ;;
        * )
            error "Invalid Choice"
            nvme_choice
    esac

}
nvme_choice

VOODOOPS2_RELEASE_URL=$(curl -s "$VOODOOPS2_URL" | jq -r '.assets[] | select(.name | match("VoodooPS2Controller-[0-9]\\.[0-9]\\.[0-9]-RELEASE")) | .browser_download_url')

laptop_input_screen() {
    echo "################################################################"
    echo "Since this hackintosh is a laptop, we are going to need to pick the kexts for it's input, such as trackpad or keyboard."
    echo "We are just going to assume that your keyboard is PS/2, If it isn't you can add more kexts later."
    echo "1. Synaptics SMBus Trackpads"
    echo "2. ELAN SMBus Trackpads"
    echo "3. ELAN Proprietary"
    echo "4. Plain I2c/ I2CHID"
    echo "5. FTE1001"
    echo "6. Atmel Multitouch Protocol"
    echo "7. Synaptics HID"
    echo "8. Alps HID" 
    echo "9. None"
    echo "################################################################"
    read -r -p "Pick a number 1-9: " input_choice

    VOODOOPS2_URL="https://api.github.com/repos/acidanthera/VoodooPS2/releases/latest"
    VOODOOPS2_RELEASE_URL=$(curl -s "$VOODOOPS2_URL" | jq -r '.assets[] | select(.name | match("VoodooPS2Controller-[0-9]\\.[0-9]\\.[0-9]-RELEASE")) | .browser_download_url')

    VOODOORMI_URL="https://api.github.com/repos/VoodooSMBus/VoodooRMI/releases/latest"
    VOODOORMI_RELEASE_URL=$(curl -s "$VOODOORMI_URL" | jq -r '.assets[] | select(.name | match("VoodooRMI-[0-9]\\.[0-9]\\.[0-9]-Release")) | .browser_download_url')

    VOODOOSMBUS_URL="https://api.github.com/repos/VoodooSMBus/VoodooSMBus/releases/latest"
    VOODOOSMBUS_RELEASE_URL=$(curl -s "$VOODOOSMBUS_URL" | jq -r '.assets[] | select(.name | match("VoodooSMBus-v[0-9]\\.[0-9]")) | .browser_download_url')
    
    VOODOOI2C_URL="https://api.github.com/repos/VoodooI2C/VoodooI2C/releases/latest"
    VOODOOI2C_RELEASE_URL=$(curl -s "$VOODOOI2C_URL" | jq -r '.assets[] | select(.name | match("VoodooI2C-[0-9]\\.[0-9]")) | .browser_download_url')

    ALPS_HID_URL="https://api.github.com/repos/blankmac/AlpsHID/releases/latest"
    ALPS_HID_RELEASE_URL=$(curl -s "$ALPS_HID_URL" | jq -r '.assets[] | select(.name | match("AlpsHID[0-9]\\.[0-9]_release")) | .browser_download_url')


    case $input_choice in
        1 )
            download_file "$VOODOORMI_RELEASE_URL" "$dir"/temp/VoodooRMI.zip
            info "Downloaded VoodooRMI"
            unzip -q "$dir"/temp/VoodooRMI.zip -d "$dir"/temp/VoodooRMI
            mv "$dir"/temp/VoodooRMI/Release/VoodooRMI.kext "$efi"/Kexts/VoodooRMI.kext
        ;;
        2 )
            download_file "$VOODOOSMBUS_RELEASE_URL" "$dir"/VoodooSMBus.zip
            info "Downloaded VoodooSMBus"
            unzip -q "$dir"/VoodooSMBus.zip -d "$dir"/VoodooSMBus
            mv "$dir"/VoodooSMBus/VoodooSMBus.kext "$efi"/Kexts/VoodooSMBus.kext
        ;;
        3 )
            download_file "$VOODOOI2C_RELEASE_URL" "$dir"/temp/VoodooI2c.zip
            info "Downloaded VoodooI2CELAN"
            unzip -q "$dir"/temp/VoodooI2c.zip -d "$dir"/temp/VoodooI2C
            mv "$dir"/temp/VoodooI2C/VoodooI2C.kext "$efi"/Kexts/VoodooI2C.kext
            mv "$dir"/temp/VoodooI2C/VoodooI2C/VoodooI2CELAN.kext "$efi"/Kexts/VoodooI2CELAN.kext
        ;;
        4 )
            download_file "$VOODOOI2C_RELEASE_URL" "$dir"/temp/VoodooI2C.zip
            info "Downloaded VoodooI2C, VoodooI2CHID"
            unzip -q "$dir"/temp/VoodooI2C.zip -d "$dir"/temp/VoodooI2C
            mv "$dir"/temp/VoodooI2C/VoodooI2C.kext "$efi"/Kexts/VoodooI2C.kext
            mv "$dir"/temp/VoodooI2C/VoodooI2CHID.kext "$efi"/Kexts/VoodooI2CHID.kext
        ;;
        5 )
            download_file "$VOODOOI2C_RELEASE_URL" "$dir"/temp/VoodooI2C.zip
            info "Downloaded VoodooI2C, VoodooI2CFTE"
            unzip -q "$dir"/temp/VoodooI2C.zip -d "$dir"/temp/VoodooI2C
            mv "$dir"/temp/VoodooI2C/VoodooI2C.kext "$efi"/Kexts/VoodooI2C.kext
            mv "$dir"/temp/VoodooI2C/VooodooI2CFTE.kext "$efi"/VooodooI2CFTE.kext
        ;;
        6 )
            download_file "$VOODOOI2C_RELEASE_URL" "$dir"/temp/VoodooI2C.zip
            info "Downloaded VoodooI2C, VoodooI2CAtmelMXT"
            unzip -q "$dir"/temp/VoodooI2C.zip -d "$dir"/temp/VoodooI2C
            mv "$dir"/temp/VodoooI2C/VoodooI2C.kext "$efi"/Kexts/VoodooI2C.kext
            mv "$dir"/temp/VoodooI2C/VoodooI2CAtmelMXT.kext "$efi"/Kexts/VoodooI2CAtmelMXT.kext
        ;;
        7 )
            download_file "$VOODOOI2C_RELEASE_URL" "$dir"/temp/VoodooI2C.zip
            download_file "$VOODOORMI_RELEASE_URL" "$dir"/temp/VoodooRMI.zip
            info "Downloaded VoodoI2C, VoodooRMI"
            unzip -q "$dir"/temp/VoodooI2c.zip -d "$dir"/temp/VoodooI2C
            unzip -q "$dir"/temp/VoodooRMI.zip -d "$dir"/temp/VoodooRMI
            mv "$dir"/temp/VoodooI2C/VoodooI2C.kext "$efi"/Kexts/VoodooI2C.kext
            mv "$dir"/temp/VoodooRMI/VoodooRMI.kext "$efi"/Kexts/VoodooRMI.kext
        ;;
        8 )
            download_file "$ALPS_HID_RELEASE_URL" "$dir"/temp/AlpsHID.zip
            info "Downloaded AlpsHID"
            unzip -q "$dir"/temp/AlpsHID.zip -d "$dir"/temp/AlpsHID
            mv "$dir"/temp/AlpsHID/AlpsHID.kext "$efi"/Kexts/AlpsHID.kext
        ;;
        * )
            error "Invalid Choice."
            laptop_input_screen
        ;;
    esac
}
case $pc_choice in
    2 )
        download_file "$VOODOOPS2_RELEASE_URL" "$dir"/temp/VoodooPS2Controller.zip
        info "Downloaded VoodooPS2"
        unzip -q "$dir"/temp/VoodooPS2Controller.zip -d "$dir"/temp/VoodooPS2Controller
        mv "$dir"/temp/VoodooPS2Controller/VoodooPS2Controller.kext "$efi"/Kexts/VoodooPS2Controller.kext
    ;;
esac

case $pc_choice in
    1 )
        echo "" > /dev/null
    ;;
    2 )
        laptop_input_screen
    ;;
esac

brightnesskeys() {
    echo "################################################################"
    echo "Does this laptop have screen brightness keys?"
    echo "################################################################"
    read -r -p "y/n: " brightness_choice
    case $brightness_choice in
        y|Y|YES|Yes|yes )
            BRIGHTNESSKEYS_RELEASE_URL=$(curl -s "$BRIGHTNESSKEYS_URL" | jq -r '.assets[] | select(.name | match("BrightnessKeys-[0-9]\\.[0-9]\\.[0-9]-RELEASE")) | .browser_download_url')
            download_file "$BRIGHTNESSKEYS_RELEASE_URL" "$dir"/temp/BrightnessKeys.zip
            info "Downloaded BrightnessKeys"
            unzip -q "$dir"/temp/BrightnessKeys.zip -d "$dir"/temp/BrightnessKeys
            mv "$dir"/temp/BrightnessKeys/BrightnessKeys.kext "$efi"/Kexts/BrightnessKeys.kext
        ;;
        n|N|NO|No|no )
            echo "" > /dev/null
        ;;
        * )
            error "Invalid Choice"
            brightnesskeys
        ;;
    esac
}
case $pc_choice in 
    2 )
        brightnesskeys
        ECENABLER_RELEASE_URL=$(curl -s "$ECENABLER_URL" | jq -r '.assets[] | select(.name | match("ECEnabler-[0-9]\\.[0-9]\\.[0-9]-RELEASE")) | .browser_download_url')
        if [ -z "$ECENABLER_RELEASE_URL" ]; then
            error "ECEnabler release URL not found, is GitHub rate-limiting you?"
            exit 1
        fi
        download_file "$ECENABLER_RELEASE_URL" "$dir"/temp/ECEnabler.zip
        info "Downloaded ECEnabler"
        unzip -q "$dir"/temp/ECEnabler.zip -d "$dir"/temp/ECEnabler
        mv "$dir"/temp/ECEnabler/ECEnabler.kext "$efi"/Kexts/ECEnabler.kext
    ;;
esac

acpi_laptop() {
    echo "################################################################"
    echo "Now, we need to download ACPI"
    echo "1. Haswell & Broadwell"
    echo "2. Skylake & Kaby Lake"
    echo "3. Coffee Lake (8th gen)"
    echo "4. Coffee and Comet Lake (9 and 10th gen)"
    echo "5. Ice Lake"
    echo "################################################################"
    read -r -p "Pick a number, 1-5: " acpilaptop_choice
}
intel_desktop_acpi() {
    echo "################################################################"
    echo "Now, we need to download ACPI"
    echo "1. Haswell and Broadwell"
    echo "2. Skylake & Kaby Lake"
    echo "3. Coffee Lake"
    echo "4. Comet Lake"
    echo "5. Other (Server systems, HEDT, etc)"
    echo "################################################################"
    read -r -p "Pick a number 1-5: " intel_acpidesktop_choice
}
amd_desktop_acpi() {
    echo "################################################################"
    echo "Now, we need to download ACPI"
    echo "1. Bulldozer(15h) and Jaguar(16h)"
    echo "2. Ryzen and Threadripper(17h and 19h)"
    echo "################################################################"
    read -r -p "Pick a number 1-2: " amd_acpidesktop_choice
}

acpi_server() {
    echo "################################################################"
    echo "Now, we need to download ACPI"
    echo "1. Haswell-E/Broadwell-E"
    echo "2. Skylake-X/W and Cascade Lake-X/W"
    echo "################################################################"
    read -r -p "Pick a number 1-2: " acpiserver_choice
}

asusmb() {
    echo "################################################################"
    echo "We'll need to ask you this question for gathering ACPI files."
    echo "Do you have an Asus's 400 series motherboard?"
    echo "################################################################"
    read -r -p "y/n: " asus_mb_choice
    case $asus_mb_choice in
        y|Y|Yes|YES|yes )
            cp "$src"/acpi/SSDT-RHUB.aml "$efi"/ACPI/SSDT-RHUB.aml
            info "Copied SSDT-RHUB to ACPI folder"
        ;;
        n|N|NO|No|no )
            echo "" > /dev/null
        ;;
        * )
            error "Invalid Choice"
            asusmb
        ;;
    esac
}
laptop9th_10thgen() {
    echo "################################################################"
    echo "We'll need to ask you this question for gathering ACPI files."
    echo "Is your laptop a 9th gen or a 10th gen chip?"
    echo "1. 9th gen"
    echo "2. 10th gen"
    echo "################################################################"
    read -r -p "Pick a number 1 or 2: " laptopgen_choice
    case $laptopgen_choice in
        1 )
            cp "$src"/acpi/SSDT-PMC.aml "$efi"/ACPI/SSDT-PMC.aml
            info "Copied SSDT-RHUB to ACPI folder"
        ;;
        2 )
            echo "" > /dev/null
        ;;
        * )
            error "Invalid Choice"
            laptop9th_10thgen
        ;;
    esac
}
am5mb() {
    echo "################################################################"
    echo "We'll need to ask you this question for gathering ACPI files."
    echo "Do you have an AM5 series motherboard? (B550/A520)"
    echo "################################################################"
    read -r -p "y/n: " am5_mb_choice
    case $am5_mb_choice in
        y|Y|YES|Yes|yes )
            cp "$src"/acpi/SSDT-CPUR.aml "$efi"/ACPI/SSDT-CPUR.aml
            info "Copied SSDT-CPUR to ACPI Folder"
        ;;
        n|N|NO|No|no )
            echo "" > /dev/null
        ;;
        * )
            error "Invalid Choice"
            am5mb
        ;;
    esac
}

case $pc_choice in
    1 )
        case $amd_cpu in
            True )
                amd_desktop_acpi
            ;;
            False )
                intel_desktop_acpi
            ;;
        esac
    ;;
    2 )
        acpi_laptop
        case $acpilaptop_choice in
            4 )
                laptop9th_10thgen
            ;;
        esac
        
    ;;
esac

case $intel_acpidesktop_choice in
    4 )
        asusmb
    ;;
    5 )
        acpi_server
    ;;
esac

case $pc_choice in 
    1 )
        case $intel_acpidesktop_choice in
            1 )
                cp "$src"/acpi/SSDT-PLUG-DRTNIA.aml "$efi"/ACPI/SSDT-PLUG-DRTNIA.aml
                info "Copied SSDT-PLUG-DRTNIA to ACPI folder"
                cp "$src"/acpi/SSDT-EC-DESKTOP.aml "$efi"/ACPI/SSDT-EC-DESKTOP.aml
                info "Copied SSDT-EC-DESKTOP to ACPI folder"
            ;;
            2 )
                cp "$src"/acpi/SSDT-PLUG-DRTNIA.aml "$efi"/ACPI/SSDT-PLUG-DRTNIA.aml
                info "Copied SSDT-PLUG-DRTNIA to ACPI folder"
                cp "$src"/acpi/SSDT-EC-USBX-DESKTOP.aml "$efi"/ACPI/SSDT-EC-USBX-DESKTOP.aml
                info "Copied SSDT-EC-USBX-DESKTOP to ACPI folder"
            ;;
            3 )
                cp "$src"/acpi/SSDT-PLUG-DRTNIA.aml "$efi"/ACPI/SSDT-PLUG-DRTNIA.aml
                info "Copied SSDT-PLUG-DRTNIA to ACPI folder"
                cp "$src"/acpi/SSDT-EC-USBX-DESKTOP.aml "$efi"/ACPI/SSDT-EC-USBX-DESKTOP.aml
                info "Copied SSDT-EC-USBX-DESKTOP to ACPI folder"
                cp "$src"/acpi/SSDT-AWAC.aml "$efi"/ACPI/SSDT-AWAC.aml
                info "Copied SSDT-AWAC to ACPI folder"
                cp "$src"/acpi/SSDT-PMC.aml "$efi"/ACPI/SSDT-PMC.aml
                info "Copied SSDT-PMC to ACPI folder"
            ;;
            4 )
                cp "$src"/acpi/SSDT-PLUG-DRTNIA.aml "$efi"/ACPI/SSDT-PLUG-DRTNIA.aml
                info "Copied SSDT-PLUG-DRTNIA to ACPI folder"
                cp "$src"/acpi/SSDT-EC-USBX-DESKTOP.aml "$efi"/ACPI/SSDT-EC-USBX-DESKTOP.aml
                info "Copied SSDT-EC-USBX-DESKTOP to ACPI folder"
                cp "$src"/acpi/SSDT-AWAC.aml "$efi"/ACPI/SSDT-AWAC.aml
                info "Copied SSDT-AWAC to ACPI folder"
            ;;
            5 )
                case $acpiserver_choice in
                    1 )
                        cp "$src"/acpi/SSDT-PLUG-DRTNIA.aml "$efi"/ACPI/SSDT-PLUG-DRTNIA.aml
                        info "Copied SSDT-PLUG-DRTNIA to ACPI folder"
                        cp "$src"/acpi/SSDT-EC-USBX-DESKTOP.aml "$efi"/ACPI/SSDT-EC-USBX-DESKTOP.aml
                        info "Copied SSDT-EC-USBX-DESKTOP to ACPI folder"
                        cp "$src"/acpi/SSDT-RTC0-RANGE-HEDT.aml "$efi"/ACPI/SSDT-RTC0-RANGE-HEDT.aml
                        info "Copied SSDT-RTC0-RANGE-HEDT to ACPI folder"
                        cp "$src"/acpi/SSDT-UNC.aml "$efi"/ACPI/SSDT-UNC.aml
                        info "Copied SSDT-UNC to ACPI folder"
                    ;;
                    2 )
                        cp "$src"/acpi/SSDT-PLUG-DRTNIA.aml "$efi"/ACPI/SSDT-PLUG-DRTNIA.aml
                        info "Copied SSDT-PLUG-DRTNIA to ACPI folder"
                        cp "$src"/acpi/SSDT-EC-USBX-DESKTOP.aml "$efi"/ACPI/SSDT-EC-USBX-DESKTOP.aml
                        info "Copied SSDT-EC-USBX-DESKTOP to ACPI folder"
                        cp "$src"/acpi/SSDT-RTC0-RANGE-HEDT.aml "$efi"/ACPI/SSDT-RTC0-RANGE-HEDT.aml
                        info "Copied SSDT-RTC0-RANGE-HEDT to ACPI folder"
                esac
            ;;
            * )
                error "Invalid Choice"
                acpi_server
            ;;
        esac
    ;;
    2 )
        case $acpilaptop_choice in
            1 )
                cp "$src"/acpi/SSDT-PLUG-DRTNIA.aml "$efi"/ACPI/SSDT-PLUG-DRTNIA.aml
                info "Copied SSDT-PLUG-DRTNIA to ACPI folder"
                cp "$src"/acpi/SSDT-EC-LAPTOP.aml "$efi"/ACPI/SSDT-EC-LAPTOP.aml
                info "Copied SSDT-EC-LAPTOP to ACPI folder"
                cp "$src"/acpi/SSDT-PNLF.aml "$efi"/ACPI/SSDT-PNLF.aml
                info "Copied SSDT-PLNF to ACPI folder"
                cp "$src"/acpi/SSDT-XOSI.aml "$efi"/ACPI/SSDT-XOSI.aml
                info "Copied SSDT-XOSI to ACPI folder"
            ;;
            2 )
                cp "$src"/acpi/SSDT-PLUG-DRTNIA.aml "$efi"/ACPI/SSDT-PLUG-DRTNIA.aml
                info "Copied SSDT-PLUG-DRTNIA to ACPI folder"
                cp "$src"/acpi/SSDT-EC-USBX-LAPTOP.aml "$efi"/ACPI/SSDT-EC-USBX-LAPTOP.aml
                info "Copied SSDT-EC-USBX-LAPTOP to ACPI folder"
                cp "$src"/acpi/SSDT-PNLF.aml "$efi"/ACPI/SSDT-PNLF.aml
                info "Copied SSDT-PLNF to ACPI folder"
                cp "$src"/acpi/SSDT-XOSI.aml "$efi"/ACPI/SSDT-XOSI.aml
                info "Copied SSDT-XOSI to ACPI folder"
            ;;
            3 )
                cp "$src"/acpi/SSDT-PLUG-DRTNIA.aml "$efi"/ACPI/SSDT-PLUG-DRTNIA.aml
                info "Copied SSDT-PLUG-DRTNIA to ACPI folder"
                cp "$src"/acpi/SSDT-EC-USBX-LAPTOP.aml "$efi"/ACPI/SSDT-EC-USBX-LAPTOP.aml
                info "Copied SSDT-EC-USBX-LAPTOP to ACPI folder"
                cp "$src"/acpi/SSDT-AWAC.aml "$efi"/ACPI/SSDT-AWAC.aml
                info "Copied SSDT-AWAC to ACPI folder"
                cp "$src"/acpi/SSDT-PNLF.aml "$efi"/ACPI/SSDT-PNLF.aml
                info "Copied SSDT-PLNF to ACPI folder"
                cp "$src"/acpi/SSDT-XOSI.aml "$efi"/ACPI/SSDT-XOSI.aml
                info "Copied SSDT-XOSI to ACPI folder"
            ;;
            4 )
                cp "$src"/acpi/SSDT-PLUG-DRTNIA.aml "$efi"/ACPI/SSDT-PLUG-DRTNIA.aml
                info "Copied SSDT-PLUG-DRTNIA to ACPI folder"
                cp "$src"/acpi/SSDT-EC-USBX-LAPTOP.aml "$efi"/ACPI/SSDT-EC-USBX-LAPTOP.aml
                info "Copied SSDT-EC-USBX-LAPTOP to ACPI folder"
                cp "$src"/acpi/SSDT-AWAC.aml "$efi"/ACPI/SSDT-AWAC.aml
                info "Copied SSDT-AWAC to ACPI folder"
                cp "$src"/acpi/SSDT-PNLF.aml "$efi"/ACPI/SSDT-PNLF.aml
                info "Copied SSDT-PLNF to ACPI folder"
                cp "$src"/acpi/SSDT-XOSI.aml "$efi"/ACPI/SSDT-XOSI.aml
                info "Copied SSDT-XOSI to ACPI folder"
            ;;
            5 )
                cp "$src"/acpi/SSDT-PLUG-DRTNIA.aml "$efi"/ACPI/SSDT-PLUG-DRTNIA.aml
                info "Copied SSDT-PLUG-DRTNIA to ACPI folder"
                cp "$src"/acpi/SSDT-EC-USBX-LAPTOP.aml "$efi"/ACPI/SSDT-EC-USBX-LAPTOP.aml
                info "Copied SSDT-EC-USBX-LAPTOP to ACPI folder"
                cp "$src"/acpi/SSDT-AWAC.aml "$efi"/ACPI/SSDT-AWAC.aml
                info "Copied SSDT-AWAC to ACPI folder"
                cp "$src"/acpi/SSDT-RHUB.aml "$efi"/ACPI/SSDT-RHUB.aml
                info "Copied SSDT-RHUB to ACPI folder"
                cp "$src"/acpi/SSDT-PNLF.aml "$efi"/ACPI/SSDT-PNLF.aml
                info "Copied SSDT-PLNF to ACPI folder"
                cp "$src"/acpi/SSDT-XOSI.aml "$efi"/ACPI/SSDT-XOSI.aml
                info "Copied SSDT-XOSI to ACPI folder"
            ;;
            * )
                error "Invalid Choice"
                acpi_laptop
            ;;
        esac
    ;;
esac
case $amd_cpu in
    True )
        case $amd_acpidesktop_choice in
            1 )
                cp "$src"/acpi/SSDT-EC-USBX-DESKTOP.aml "$efi"/ACPI/SSDT-EC-USBX-DESKTOP.aml
                info "Copied SSDT-EC-USBX-DESKTOP to ACPI folder"
            ;;
            2 )
                am5mb
                cp "$src"/acpi/SSDT-EC-USBX-DESKTOP.aml "$efi"/ACPI/SSDT-EC-USBX-DESKTOP.aml
                info "Copied SSDT-EC-USBX-DESKTOP to ACPI folder"
            ;;
        esac
    ;;
esac

git clone -q https://github.com/corpnewt/OCSnapshot.git "$dir"/temp/OCSnapshot
python3 "$dir"/temp/OCSnapshot/OCSnapshot.py -i "$efi"/config.plist -s "$dir"/EFI/EFI/OC -c &> /dev/null


change_plist NVRAM.Add.7C436110-AB2A-4BBB-A880-FE41995C9F82.prev-lang:kbd string
set_plist NVRAM.Add.7C436110-AB2A-4BBB-A880-FE41995C9F82.prev-lang:kbd string "en-US:0"
delete_plist "#WARNING - 1"
delete_plist "#WARNING - 2"
delete_plist "#WARNING - 3"
delete_plist "#WARNING - 4"
delete_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x1b,0x0)"
add_plist "# Generated by oc-efi-maker, if anyone is asking for help with this EFI, politely tell them to make their own efi, - Mac" string


macserial() {
    info "Generating SMBIOS..."
    case $os in
        Linux )
            chmod +x "$dir"/temp/OpenCore/Utilities/macserial/macserial.linux
            smbiosoutput=$("$dir"/temp/OpenCore/Utilities/macserial/macserial.linux --num 1 --model "$smbiosname")
        ;;
        Darwin )
            chmod +x "$dir"/temp/OpenCore/Utilities/macserial/macserial
            smbiosoutput=$("$dir"/temp/OpenCore/Utilities/macserial/macserial --num 1 --model "$smbiosname")
        ;;
    esac
    SN=$(echo "$smbiosoutput" | awk -F '|' '{print $1}' | tr -d '[:space:]')
    MLB=$(echo "$smbiosoutput" | awk -F '|' '{print $2}' | tr -d '[:space:]')
    UUID=$(uuidgen)
    set_plist PlatformInfo.Generic.SystemProductName string "$smbiosname"
    set_plist PlatformInfo.Generic.SystemSerialNumber string "$SN"
    set_plist PlatformInfo.Generic.MLB string "$MLB"
    set_plist PlatformInfo.Generic.SystemUUID string "$UUID"
}

misc_nvram() {
    set_plist Misc.Debug.AppleDebug bool True
    set_plist Misc.Debug.ApplePanic bool True
    set_plist Misc.Debug.DisableWatchDog bool True
    set_plist Misc.Debug.Target int 67
    set_plist Misc.Security.AllowSetDefault bool True
    set_plist Misc.Security.BlacklistAppleUpdate bool True
    set_plist Misc.Security.ScanPolicy int 0
    set_plist Misc.Security.SecureBootModel string Default
    set_plist Misc.Security.Vault string Optional
    set_plist NVRAM.Add.7C436110-AB2A-4BBB-A880-FE41995C9F82.boot-args string "-v debug=0x100 alcid=1 keepsyms=1"
}
misc_nvram

amdgpu() {
    echo "################################################################"
    echo "Do you have an AMD Navi 10/14/21/23 series GPU?"
    echo "Info: This action will add agdpmod=pikera to boot args"
    echo "################################################################"
    read -r -p "y/n: " navigpu_choice
    case $navigpu_choice in
        y|Y|YES|Yes|yes )
            append_plist NVRAM.Add.7C436110-AB2A-4BBB-A880-FE41995C9F82.boot-args string " agdpmod=pikera"
        ;;
        n|N|NO|No|no )
            echo "" > /dev/null
        ;;
    esac   
}
case $ati_radeon_plugins in
    y|Y|YES|Yes|yes )
        amdgpu
    ;;
esac



cpu_rev_laptop() {
    echo "################################################################"
    echo "Now, we need to ask you what generation your processor is."
    echo "1. Haswell"
    echo "2. Broadwell"
    echo "3. Skylake"
    echo "4. Kaby Lake"
    echo "5. Coffee & Whiskey Lake"
    echo "6. Coffee Lake Plus & Comet Lake"
    echo "7. Ice Lake"
    echo "################################################################"
    read -r -p "Pick a number 1-7: " laptop_cpu_gen_choice
    
    case $laptop_cpu_gen_choice in
        1 )
            haswell_laptop_config_setup
        ;;
        2 )
            broadwell_laptop_config_setup
        ;;
        3 )
            skylake_laptop_config_setup
        ;;
        4 )
            kabylake_laptop_config_setup
        ;;
        5 )
            coffee_whiskeylake_laptop_config_setup
        ;;
        6 )
            coffelakeplus_cometlake_laptop_config_setup
        ;;
        7 )
            ice_lake_laptop_config_setup
        ;;
        * )
            error "Invalid Choice"
            cpu_rev_laptop
    esac
}


desktop_haswell_broadwell() {
    echo "################################################################"
    echo "Now, we need to ask you what generation your processor is."
    echo "1. Haswell"
    echo "2. Broadwell"
    echo "################################################################"
    read -r -p "Pick a number 1-2: " haswell_broadwell_choice
    case $haswell_broadwell_choice in
        1 )
            haswell_broadwell_desktop_config_setup
        ;;
        2 )
            haswell_broadwell_desktop_config_setup
        ;;
    esac
}

laptop_haswell_broadwell() {
    echo "################################################################"
    echo "Now, we need to ask you what generation your processor is."
    echo "1. Haswell"
    echo "2. Broadwell"
    echo "################################################################"
    read -r -p "Pick a number 1-2: " haswell_broadwell_choice
    case $haswell_broadwell_choice in
        1 )
            haswell_laptop_config_setup
        ;;
        2 )
            broadwell_laptop_config_setup
        ;;
    esac
}

desktop_skylake_kabylake() {
    echo "################################################################"
    echo "Now, we need to ask you what generation your processor is."
    echo "1. Skylake"
    echo "2. Kaby Lake"
    echo "################################################################"
    read -r -p "Pick a number 1-2: " skylake_kabylake_choice
    case $skylake_kabylake_choice in
        1 )
            skylake_desktop_config_setup
        ;;
        2 )
            kabylake_desktop_config_setup
        ;;
    esac
}

laptop_skylake_kabylake() {
    echo "################################################################"
    echo "Now, we need to ask you what generation your processor is."
    echo "1. Skylake"
    echo "2. Kaby Lake"
    echo "################################################################"
    read -r -p "Pick a number 1-2: " skylake_kabylake_choice
    case $skylake_kabylake_choice in
        1 )
            skylake_laptop_config_setup
        ;;
        2 )
            kabylake_laptop_config_setup
        ;;
    esac
}

# cpu_rev_desktop() {
#     echo "################################################################"
#     echo "Now, we need to ask you what generation your processor is."
#     echo "1. Haswell"
#     echo "2. Broadwell"
#     echo "3. Skylake"
#     echo "4. Kaby Lake"
#     echo "5. Coffee Lake"
#     echo "6. Comet Lake"
#     echo "7. Bulldozer(15h) and Jaguar (16h)"
#     echo "8. Ryzen and Threadripper(17h and 19h)"
#     echo "################################################################"
#     read -r -p "Pick a number 1-8: " desktop_cpu_gen_choice
#     case $desktop_cpu_gen_choice in
#         1|2 ) 
#             haswell_broadwell_desktop_config_setup
#         ;;
#         3 )
#             skylake_desktop_config_setup
#         ;;
#         4 )
#             kabylake_desktop_config_setup
#         ;;
#         5 )
#             coffeelake_desktop_config_setup
#         ;;
#         6 )
#             cometlake_desktop_config_setup
#         ;;
#         7 ) 
#             amd1516_desktop_config_setup
#         ;;
#         8 ) 
#             amd1719_desktop_config_setup
#         ;;
#         * )
#             error "Invalid Choice"
#             cpu_rev_desktop
#     esac
# }

cpu_rev_server(){
    echo "################################################################"
    echo "Now, we need to ask you what generation your processor is."
    echo "1. Haswell-E"
    echo "2. Broadwell-E"
    echo "3. Skylake-X/W and Cascade Lake-X/W"
    echo "################################################################"
    read -r -p "Pick a number 1-3: " server_cpu_gen_choice
    case $server_cpu_gen_choice in
        1|2 )
            haswell_broadwell_e_server_config_setup
        ;;
        3 )
            skylake_cascade_server_config_setup
        ;;
        * )
            error "Invalid Choice"
            cpu_rev_server
    esac
}

case $amd_cpu in
    True )
        case $amd_acpidesktop_choice in
            1 )
                amd1516_desktop_config_setup
            ;;
            2 )
                amd1719_desktop_config_setup
            ;;
        esac
    ;;
esac

case $pc_choice in 
    1 )
        case $intel_acpidesktop_choice in
            1 )
                desktop_haswell_broadwell
            ;;
            2 )
                desktop_skylake_kabylake
            ;;
            3 )
                coffeelake_desktop_config_setup
            ;;
            4 )
                cometlake_desktop_config_setup
            ;;
            7 )
                cpu_rev_server
            ;;
        esac
    ;;
    2 )
        cpu_rev_laptop
    ;;
esac                        


info "Cleaning up temporary files..."
rm -rf "$dir"/temp
info "Done!"
info "Your EFI is located at $dir/EFI"
info "Thanks for using the script!"