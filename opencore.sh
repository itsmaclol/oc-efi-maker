#!/bin/bash

os=$(uname)

tmpdir=$(mktemp -d)
dir=$tmpdir
mkdir "$dir"/temp

# Thanks to palera1n install.sh and to checkra1n for this coloring scheme!
RED='\033[0;31m'
YELLOW='\033[0;33m'
DARK_GRAY='\033[90m'
LIGHT_CYAN='\033[0;96m'
NO_COLOR='\033[0m'
error() {
    echo -e " - [${DARK_GRAY}$(date +'%m/%d/%y %H:%M:%S')${NO_COLOR}] ${RED}<Error>${NO_COLOR}: ${RED}$1${NO_COLOR}"
}

info() {
    echo -e " - [${DARK_GRAY}$(date +'%m/%d/%y %H:%M:%S')${NO_COLOR}] ${LIGHT_CYAN}<Info>${NO_COLOR}: ${LIGHT_CYAN}$1${NO_COLOR}"
}

warning() {
    echo -e " - [${DARK_GRAY}$(date +'%m/%d/%y %H:%M:%S')${NO_COLOR}] ${YELLOW}<Warning>${NO_COLOR}: ${YELLOW}$1${NO_COLOR}"
}
clear
internet_check() {
    ping -c 1 -W 1 google.com > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo "" > /dev/null
    else
        error "You do not seem to have an internet connection, please connect to the internet and try again, or if you are completely sure that you have internet, use the --ignore-internet-check flag."
        exit 1
    fi
}

get_distribution() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRIBUTION=$NAME
        VERSION=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        DISTRIBUTION=$(lsb_release -si)
        VERSION=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        DISTRIBUTION=$DISTRIB_ID
        VERSION=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        DISTRIBUTION="Debian"
        VERSION=$(cat /etc/debian_version)
    elif [ -f /etc/redhat-release ]; then
        DISTRIBUTION=$(cat /etc/redhat-release | awk '{print $1}')
        VERSION=$(cat /etc/redhat-release | awk '{print $3}')
    else
        DISTRIBUTION="Unknown"
        VERSION="Unknown"
    fi
}
get_package_manager() {
    if command -v apt-get >/dev/null 2>&1; then
        PACKAGE_MANAGER="apt-get"
    elif command -v yum >/dev/null 2>&1; then
        PACKAGE_MANAGER="yum"
    elif command -v dnf >/dev/null 2>&1; then
        PACKAGE_MANAGER="dnf"
    elif command -v pacman >/dev/null 2>&1; then
        PACKAGE_MANAGER="pacman"
    elif command -v apk >/dev/null 2>&1; then
        PACKAGE_MANAGER="apk"
    else
        PACKAGE_MANAGER="Unknown"
    fi
}

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
        info "Detected $DISTRIBUTION with version $VERSION and $PACKAGE_MANAGER package manager."
    ;;
    * )
        error "Unsupported OS."
        exit 1
esac
dependencies() {
    dependencies=("jq" "curl" "python3" "unzip" "git")
    missing_dependencies=()

    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" > /dev/null; then
            missing_dependencies+=("$dep")
        fi
    done

    if [[ ${#missing_dependencies[@]} -gt 0 ]]; then
        info "If you have run this script before, and the dependencies didnt install, please install ${missing_dependencies[*]} manually."
        info "Dependencies are missing, would you like to install them?"
        read -r -p "y/n: " install_deps
        case $install_deps in
            y|Y|Yes|YES|yes )
                if [[ "$(uname)" == "Darwin" && -x "$(command -v brew)" ]]; then
                    brew install "${missing_dependencies[@]}"
                    info "Dependencies installed, please rerun this script."
                    exit 1
                elif [[ "$(uname)" == "Linux" ]]; then
                    case $PACKAGE_MANAGER in
                        "pacman" )
                            sudo pacman -Syu "${missing_dependencies[@]}" --noconfirm
                        ;;
                        "apt-get" )
                            sudo apt-get update
                            sudo apt-get install "${missing_dependencies[@]}" -y
                        ;;
                        "yum"|"dnf" )
                            dnf update
                            dnf install "${missing_dependencies[@]}" -y
                        ;;
                        "apk" )
                            apk update
                            apk add "${missing_dependencies[@]}"
                    esac
                    info "Dependencies installed, please rerun this script."
                    exit 1
                else
                    error "Unsupported operating system. You need to install ${missing_dependencies[*]} manually."
                    exit 1
                fi
            ;;
            n|N|NO|No|no )
                error "${missing_dependencies[*]} is/are needed for the script to work as intended."
                exit 1
            ;;
        esac
    fi
}

help_page() {
        cat << EOF
Usage: $0 [Options]
Opencore EFI Maker

Options:
    --help                       Print this help
    --ignore-internet-check      Ignores the internet check at the beginning of the script. Use this if you are 100% sure that you have internet.
    --ignore-dependencies        Ignores the dependency check at the beginning of the script. Use this if you are 100% sure that you have the dependencies installed.
    --ignore-deps-internet-check Ignores both the internet and dependency check at the beginning of the script. Use this if you are 100% sure that you have the dependencies installed and have internet.

Warning: This script is made for an elementary opencore EFI, if you want a stable hackintosh please follow the guide over at https://dortania.github.io/OpenCore-Install-Guide/
EOF
exit 1
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
    * )
        internet_check
        dependencies
esac

OC_URL="https://api.github.com/repos/acidanthera/OpenCorePkg/releases/latest"
LILU_URL="https://api.github.com/repos/acidanthera/Lilu/releases/latest"
VIRTUALSMC_URL="https://api.github.com/repos/acidanthera/VirtualSMC/releases/latest"
APPLEALC_URL="https://api.github.com/repos/acidanthera/AppleALC/releases/latest"
INTEL_MAUSI_URL="https://api.github.com/repos/acidanthera/IntelMausi/releases/latest"
APPLEIGB_URL="https://github.com/donatengit/AppleIGB/releases/download/v5.11/AppleIGB.kext.DEBUG.zip"   
SMALLTREEINTEL82576_URL="https://github.com/khronokernel/SmallTree-I211-AT-patch/releases/download/1.3.0/SmallTreeIntel82576.kext.zip"
ATHEROSE2200ETHERNET_URL="https://github.com/Mieze/AtherosE2200Ethernet/releases/download/2.2.2/AtherosE2200Ethernet-V2.2.2.zip"
REALTEKRTL8111_URL="https://api.github.com/repos/Mieze/RTL8111_driver_for_OS_X/releases/latest"
LUCYRTL8125ETHERNET_URL="https://api.github.com/repos/Mieze/LucyRTL8125Ethernet/releases/latest"
USBTOOLBOX_KEXT_URL="https://api.github.com/repos/USBToolBox/kext/releases/latest"
ITLWM_URL="https://api.github.com/repos/OpenIntelWireless/itlwm/releases/latest"
AIRPORT_BRCM_URL="https://api.github.com/repos/acidanthera/AirportBrcmFixup/releases/latest"
INTELBTFIRMWARE_URL="https://api.github.com/repos/OpenIntelWireless/IntelBluetoothFirmware/releases/latest"
BRCMPATCHRAM_URL="https://api.github.com/repos/acidanthera/BrcmPatchRAM/releases/latest"
NVMEFIX_URL="https://api.github.com/repos/acidanthera/NVMeFix/releases/latest"
VOODOOPS2_URL="https://api.github.com/repos/acidanthera/VoodooPS2/releases/latest"
WHATEVERGREEN_URL="https://api.github.com/repos/acidanthera/WhateverGreen/releases/latest"
SSDT_PLUG_DRTNIA="https://github.com/dortania/Getting-Started-With-ACPI/raw/master/extra-files/compiled/SSDT-PLUG-DRTNIA.aml"
SSDT_EC_DESKTOP="https://github.com/dortania/Getting-Started-With-ACPI/raw/master/extra-files/compiled/SSDT-EC-DESKTOP.aml"
SSDT_EC_USBX_DESKTOP="https://github.com/dortania/Getting-Started-With-ACPI/raw/master/extra-files/compiled/SSDT-EC-USBX-DESKTOP.aml"
SSDT_AWAC="https://github.com/dortania/Getting-Started-With-ACPI/raw/master/extra-files/compiled/SSDT-AWAC.aml"
SSDT_PMC="https://github.com/dortania/Getting-Started-With-ACPI/raw/master/extra-files/compiled/SSDT-PMC.aml"
SSDT_RHUB="https://github.com/dortania/Getting-Started-With-ACPI/raw/master/extra-files/compiled/SSDT-RHUB.aml"
SSDT_CPUR="https://github.com/dortania/Getting-Started-With-ACPI/blob/master/extra-files/compiled/SSDT-CPUR.aml"
SSDT_EC_LAPTOP="https://github.com/dortania/Getting-Started-With-ACPI/raw/master/extra-files/compiled/SSDT-EC-LAPTOP.aml"
SSDT_PNLF="https://github.com/dortania/Getting-Started-With-ACPI/raw/master/extra-files/compiled/SSDT-PNLF.aml"
SSDT_XOSI="https://github.com/dortania/Getting-Started-With-ACPI/raw/master/extra-files/compiled/SSDT-XOSI.aml"
SSDT_EC_USBX_LAPTOP="https://github.com/dortania/Getting-Started-With-ACPI/raw/master/extra-files/compiled/SSDT-EC-USBX-LAPTOP.aml"
SSDT_PMC="https://github.com/dortania/Getting-Started-With-ACPI/blob/master/extra-files/compiled/SSDT-PMC.aml"
#VIRTUALSMC_AMD_URL="url here"
#VIRTUALSMC_AMD2_URL="url here"

info "Downloading plisteditor.py..."
curl -Ls https://raw.githubusercontent.com/itsmaclol/plisteditor/main/plisteditor.py -o "$dir"/temp/plisteditor.py
add_plist() {
    python3 "$dir"/temp/plisteditor.py add  "$1" --type "$2" --path "$efi"/config.plist
}

set_plist() {
    python3 "$dir"/temp/plisteditor.py set  "$1" --type "$2" --value "$3" --path "$efi"/config.plist
}


delete_plist() {
    python3 "$dir"/temp/plisteditor.py delete "$1" --path "$efi"/config.plist
}

change_plist() {
    python3 "$dir"/temp/plisteditor.py change "$1" --new_type "$2" --path "$efi"/config.plist
}
echo "################################################################"
echo "Welcome to the OpenCore EFI Maker."
echo "Made and maintained by Mac and the OpenCore Team."
echo "################################################################"
echo ""


opencore() {
    echo "################################################################"
    echo "Please pick the version of OpenCore you would like to download."
    echo "1. RELEASE"
    echo "2. DEBUG"
    echo "################################################################"
    read -r -p "1 or 2: " oc_choice

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
    FILE_NAME="OpenCore-$rldb-$OC_RELEASE_NUMBER"
    info "Downloading $FILE_NAME..."
    curl -Ls "$DOWNLOAD_URL" -o "$dir"/"$FILE_NAME".zip
    unzip -q "$dir"/"$FILE_NAME".zip -d "$dir"
    info "Saved at $dir/$FILE_NAME.zip"
}
opencore 

macos_choice(){
    echo ""
    echo "################################################################"
    echo "Next, for the macOS Version."
    echo "1: macOS Ventura"
    echo "2: macOS Monterey"
    echo "3: macOS Big Sur"
    echo "4: macOS Catalina"
    echo "5: macOS Mojave"
    echo "Info: For any macOS lower than this, you will need to follow the guide yourself."
    echo "################################################################"
    echo ""
    read -r -p "Pick a number 1-5: " os_choice
    case $os_choice in
        1 )
            os_name="Ventura"  
            info "Downloading macOS Ventura, please wait..."
            #python3 ""$dir""/Utilities/macrecovery/macrecovery.py -b Mac-4B682C642B45593E -m 00000000000000000 download   
        ;;
        2 )
            os_name="Monterey"
            info "Downloading macOS Monterey, please wait..."
            #python3 ""$dir""/Utilities/macrecovery/macrecovery.py -b Mac-FFE5EF870D7BA81A -m 00000000000000000 download
        ;;
        3 )
            os_name="BigSur"
            info "Downloading macOS Big Sur, please wait..."
            #python3 ""$dir""/Utilities/macrecovery/macrecovery.py -b Mac-42FD25EABCABB274 -m 00000000000000000 download
        ;;
        4 )
            os_name="Catalina"
            info "Downloading macOS Catalina, please wait..."
            #python3 ""$dir""/Utilities/macrecovery/macrecovery.py -b Mac-00BE6ED71E35EB86 -m 00000000000000000 download
        ;;
        5 )
            os_name="Mojave"
            info "Downloading macOS Mojave, please wait..."
            #python3 ""$dir""/Utilities/macrecovery/macrecovery.py -b Mac-7BA5B2DFE22DDD8C -m 00000000000KXPG00 download
        ;;
        * )
            error "Invalid Choice"
            macos_choice
    esac
}
macos_choice

info "Setting up EFI Folder Structure..."
sleep 3
efi="$dir"/EFI/EFI/OC
mkdir -p "$efi"
cp -r "$dir"/X64/EFI/BOOT "$dir"/EFI/EFI/BOOT
cp -r "$dir"/X64/EFI/OC/ACPI "$efi"/ACPI
cp -r "$dir"/X64/EFI/OC/Kexts "$efi"/Kexts
cp -r "$dir"/X64/EFI/OC/Resources "$efi"/Resources
cp "$dir"/X64/EFI/OC/OpenCore.efi "$efi"/OpenCore.efi
cp "$dir"/Docs/Sample.plist "$efi"/config.plist
mkdir "$efi"/Drivers
cp "$dir"/X64/EFI/OC/Drivers/OpenRuntime.efi "$efi"/Drivers/OpenRuntime.efi
cp "$dir"/X64/EFI/OC/Drivers/ResetNvramEntry.efi "$efi"/Drivers/ResetNvramEntry.efi
mkdir "$efi"/Tools
cp "$dir"/X64/EFI/OC/Tools/OpenShell.efi "$efi"/Tools/
info "Downloading HfsPlus..."
curl -Ls https://github.com/acidanthera/OcBinaryData/raw/master/Drivers/HfsPlus.efi -o "$efi"/Drivers/HfsPlus.efi
LILU_RELEASE_URL=$(curl -s "$LILU_URL" | jq -r '.assets[] | select(.name | match("Lilu-[0-9]\\.[0-9]\\.[0-9]-RELEASE")) | .browser_download_url')
if [ -z "$LILU_RELEASE_URL" ]; then
    error "Lilu release URL not found, is GitHub rate-limiting you?"
    exit 1
fi
LILU_RELEASE_NUMBER=$(curl -s "$LILU_URL" | jq -r '.tag_name')
info "Downloading Lilu $LILU_RELEASE_NUMBER..."
curl -Ls "$LILU_RELEASE_URL" -o "$dir"/temp/Lilu.zip
unzip -q "$dir"/temp/Lilu.zip -d "$dir"/temp/Lilu
mv "$dir"/temp/Lilu/Lilu.kext "$efi"/Kexts/Lilu.kext



VIRTUALSMC_RELEASE_URL=$(curl -s "$VIRTUALSMC_URL" | jq -r '.assets[] | select(.name | match("VirtualSMC-[0-9]\\.[0-9]\\.[0-9]-RELEASE")) | .browser_download_url')
if [ -z "$VIRTUALSMC_RELEASE_URL" ]; then
    error "VirtualSMC release URL not found, is GitHub rate-limiting you?"
    exit 1
fi
VIRTUALSMC_RELEASE_NUMBER=$(curl -s "$VIRTUALSMC_URL" | jq -r '.tag_name')
info "Downloading VirtualSMC $VIRTUALSMC_RELEASE_NUMBER..."
curl -Ls "$VIRTUALSMC_RELEASE_URL" -o "$dir"/temp/VirtualSMC.zip
unzip -q "$dir"/temp/VirtualSMC.zip -d "$dir"/temp/VirtualSMC
mv "$dir"/temp/VirtualSMC/Kexts/VirtualSMC.kext "$efi"/Kexts/VirtualSMC.kext


APPLEALC_RELEASE_URL=$(curl -s "$APPLEALC_URL" | jq -r '.assets[] | select(.name | match("AppleALC-[0-9]\\.[0-9]\\.[0-9]-RELEASE")) | .browser_download_url')

if [ -z "$APPLEALC_RELEASE_URL" ]; then
    error "AppleALC release URL not found, is GitHub rate-limiting you?"
    exit 1
fi
APPLEALC_RELEASE_NUMBER=$(curl -s "$APPLEALC_URL" | jq -r '.tag_name')
info "Downloading AppleALC $APPLEALC_RELEASE_NUMBER..."
curl -Ls "$APPLEALC_RELEASE_URL" -o "$dir"/temp/AppleALC.zip
unzip -q "$dir"/temp/AppleALC.zip -d "$dir"/temp/AppleALC
mv "$dir"/temp/AppleALC/AppleALC.kext "$efi"/Kexts/AppleALC.kext

WHATEVERGREEN_RELEASE_URL=$(curl -s "$WHATEVERGREEN_URL" | jq -r '.assets[] | select(.name | match("WhateverGreen-[0-9]\\.[0-9]\\.[0-9]-RELEASE")) | .browser_download_url')

if [ -z "$WHATEVERGREEN_RELEASE_URL" ]; then
    error "AppleALC release URL not found, is GitHub rate-limiting you?"
    exit 1
fi
WHATEVERGREEN_RELEASE_NUMBER=$(curl -s "$WHATEVERGREEN_URL" | jq -r '.tag_name')
info "Downloading WhateverGreen $WHATEVERGREEN_RELEASE_NUMBER..."
curl -Ls "$WHATEVERGREEN_RELEASE_URL" -o "$dir"/temp/WhateverGreen.zip
unzip -q "$dir"/temp/WhateverGreen.zip -d "$dir"/temp/WhateverGreen
mv "$dir"/temp/WhateverGreen/WhateverGreen.kext "$efi"/Kexts/WhateverGreen.kext

info "Downloading Done!"

pc() {
    echo ""
    echo "################################################################"
    echo "Now, we're going to need some info before we continue."
    echo "Is this hackintosh a Laptop or a Desktop?"
    echo "1. Desktop"
    echo "2. Laptop"
    echo "################################################################"
    read -r -p "1 or 2: " pc_choice 
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
vsmcplugins() {
    echo ""
    echo "################################################################"
    echo "Do you want VirtualSMC Plugins?"
    echo "################################################################"
    read -r -p "y/n: " vsmc_plugins
    case $vsmc_plugins in
    y|Y|Yes|YES|yes )
        mv "$dir"/temp/VirtualSMC/Kexts/SMCSuperIO.kext "$efi"/Kexts/SMCSuperIO.kext
        mv "$dir"/temp/VirtualSMC/Kexts/SMCProcessor.kext "$efi"/Kexts/SMCProcessor.kext
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
        echo "" > /dev/null
    ;;
    * )
        error "Invalid Choice"
        vsmcplugins
    ;;
esac

}
vsmcplugins




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
    read -r -p "Pick a number 1-6: " eth_choice
    case $eth_choice in
        1 )
            INTEL_MAUSI_RELEASE_URL=$(curl -s "$INTEL_MAUSI_URL" | jq -r '.assets[] | select(.name | match("IntelMausi-[0-9]\\.[0-9]\\.[0-9]-RELEASE")) | .browser_download_url')

            if [ -z "$INTEL_MAUSI_RELEASE_URL" ]; then
                error "IntelMausi release URL not found, is GitHub rate-limiting you?"
                exit 1
            fi
            info "Downloading IntelMausi..."
            curl -Ls "$INTEL_MAUSI_RELEASE_URL" -o "$dir"/temp/IntelMausi.zip
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
            sleep 3
            info "Downloading AppleIGB..."
            curl -Ls $APPLEIGB_URL -o "$dir"/temp/AppleIGB.zip
            unzip -q "$dir"/temp/AppleIGB -d "$dir"/temp/AppleIGB
            mv "$dir"/temp/AppleIGB/AppleIGB.kext "$efi"/Kexts/AppleIGB.kext
        ;;
        3 )
            info "Downloading SmallTreeIntel82576..."
            curl -Ls $SMALLTREEINTEL82576_URL -o "$dir"/temp/SmallTreeIntel82576.zip
            unzip -q "$dir"/temp/SmallTreeIntel82576.zip -d "$dir"/temp/SmallTreeIntel82576
            mv "$dir"/temp/SmallTreeIntel82576/SmallTreeIntel82576.kext "$efi"/Kexts/SmallTreeIntel82576.kext
        ;;
        4 )
            info "Downloading AtherosE2200Ethernet..."
            curl -Ls $ATHEROSE2200ETHERNET_URL -o "$dir"/temp/AtherosE2200Ethernet.zip
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
            info "Downloading RealtekRTL8111..."
            curl -Ls "$REALTEKRTL8111_RELEASE_URL" -o "$dir"/temp/RealtekRTL8111.zip
            unzip -q "$dir"/temp/RealtekRTL8111.zip -d "$dir"/temp/RealtekRTL8111
            mv "$dir"/temp/RealtekRTL8111/RealtekRTL8111-V"$REALTEKRTL8111_RELEASE_NR"/Release/RealtekRTL8111.kext "$efi"/Kexts/RealtekRTL8111.kext
        ;;
        6 )
            case $oc_choice in 
                5 )
                    error "You have picked macOS Mojave for LucyRTL8125 which requires macOS catalina or higher."
                    exit 1
                ;;
            esac
            
            LUCYRTL8125ETHERNET_RELEASE_URL=$(curl -s "$LUCYRTL8125ETHERNET_URL" | jq -r '.assets[] | select(.name | match("LucyRTL8125Ethernet-V[0-9]\\.[0-9]\\.[0-9]")) | .browser_download_url')
            if [ -z "$LUCYRTL8125ETHERNET_RELEASE_URL" ]; then
                error "LucyRTL8125Ethernet release URL not found, is GitHub rate-limiting you?"
                exit 1
            fi
            info "Downloading LucyRTL8125Ethernet..."
            curl -Ls "$LUCYRTL8125ETHERNET_RELEASE_URL" -o "$dir"/temp/LucyRTL8125Ethernet.zip
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
echo "For this, we are going to use USBToolBox"
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

curl -Ls "$USBTOOLBOX_KEXT_RELEASE_URL" -o "$dir"/temp/USBToolbox.zip
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
    read -r -p "Enter a number 1-3: " wifi_choice
    echo ""
    case $wifi_choice in
    1 )
        ITLWM_RELEASE_URL=$(curl -s $ITLWM_URL | jq -r --arg osname "$os_name" '.assets[] | select(.name | endswith("_stable_" + $osname + ".kext.zip")) | .browser_download_url')

        if [ -z "$ITLWM_RELEASE_URL" ]; then
            error "AirportItlwm release URL not found, is GitHub rate-limiting you?"
            exit 1
        fi

        info "Downloading AirportItlwm-$os_name..."
        curl -Ls "$ITLWM_RELEASE_URL" -o "$dir"/temp/AirportItlwm.zip
        unzip -q "$dir"/temp/AirportItlwm.zip -d "$dir"/temp/AirportItlwm
        mv "$dir"/temp/AirportItlwm/Airportitlwm.kext "$efi"/Kexts/Airportitlwm.kext
    ;;
    2 )
        
        AIRPORT_BRCM_RELEASE_URL=$(curl -s "$AIRPORT_BRCM_URL" | jq -r '.assets[] | select(.name | match("AirportBrcmFixup-[0-9]\\.[0-9]\\.[0-9]-RELEASE")) | .browser_download_url')

        if [ -z "$AIRPORT_BRCM_RELEASE_URL" ]; then
            error "AirportBrcmFixup release URL not found, is GitHub rate-limiting you?"
            exit 1
        fi
        info "Downloading AirportBrcmFixup..."
        curl -Ls "$AIRPORT_BRCM_RELEASE_URL" -o "$dir"/temp/AirportBrcmFixup.zip
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
    read -r -p "Enter a number 1-3: " bt_choice
    case $bt_choice in
    1 )
        INTELBTFIRMWARE_RELEASE_URL=$(curl -s "$INTELBTFIRMWARE_URL" | jq -r '.assets[] | select(.name | match("IntelBluetooth-v[0-9]\\.[0-9]\\.[0-9]")) | .browser_download_url')
        if [ -z "$INTELBTFIRMWARE_RELEASE_URL" ]; then
            error "IntelBluetoothFirmware release URL not found, is GitHub rate-limiting you?"
            exit 1
        fi
        info "Downloading IntelBluetoothFirmware..."
        curl -Ls "$INTELBTFIRMWARE_RELEASE_URL" -o "$dir"/temp/IntelBluetoothFirmware.zip
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
        BRCMPATCHRAM_RELEASE_URL=$(curl -s "$BRCMPATCHRAM_URL" | jq -r '.assets | .[] | select(.name | endswith("-RELEASE.zip")) | .browser_download_url')

        if [ -z "$BRCMPATCHRAM_RELEASE_URL" ]; then
            error "BrcmPatchRAM release URL not found, is GitHub rate-limiting you?"
            exit 1
        fi

        info "Downloading BrcmPatchRAM..."
        curl -Ls "$BRCMPATCHRAM_RELEASE_URL" -o "$dir"/temp/BrcmPatchRAM.zip
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
            if [ -z "$NVMEFIX_RELEASE_URL" ]; then
                error "NVMeFix release URL not found, is GitHub rate-limiting you?"
                exit 1
            fi

            info "Downloading NVMeFix..."
            curl -Ls "$NVMEFIX_RELEASE_URL" -o "$dir"/temp/NVMeFix.zip
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
    echo "################################################################"
    read -r -p "Pick a number 1-8: " input_choice

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
            info "Downloading VoodooRMI..."
            curl -Ls "$VOODOORMI_RELEASE_URL" -o "$dir"/temp/VoodooRMI.zip
            unzip -q "$dir"/temp/VoodooRMI.zip -d "$dir"/temp/VoodooRMI
            mv "$dir"/temp/VoodooRMI/Release/VoodooRMI.kext "$efi"/Kexts/VoodooRMI.kext
        ;;
        2 )
            info "Downloading VoodooSMBus..."
            curl -Ls "$VOODOOSMBUS_RELEASE_URL" -o "$dir"/VoodooSMBus.zip
            unzip -q "$dir"/VoodooSMBus.zip -d "$dir"/VoodooSMBus
            mv "$dir"/VoodooSMBus/VoodooSMBus.kext "$efi"/Kexts/VoodooSMBus.kext
        ;;
        3 )
            info "Downloading VoodooI2CELAN..."
            curl -Ls "$VOODOOI2C_RELEASE_URL" "$dir"/temp/VoodooI2c.zip
            unzip -q "$dir"/temp/VoodooI2c.zip -d "$dir"/temp/VoodooI2C
            mv "$dir"/temp/VoodooI2C/VoodooI2C.kext "$efi"/Kexts/VoodooI2C.kext
            mv "$dir"/temp/VoodooI2C/VoodooI2C/VoodooI2CELAN.kext "$efi"/Kexts/VoodooI2CELAN.kext
        ;;
        4 )
            info "Downloading VoodooI2C, VoodooI2CHID..."
            curl -Ls "$VOODOOI2C_RELEASE_URL" -o "$dir"/temp/VoodooI2C.zip
            unzip -q "$dir"/temp/VoodooI2C.zip -d "$dir"/temp/VoodooI2C
            mv "$dir"/temp/VoodooI2C/VoodooI2C.kext "$efi"/Kexts/VoodooI2C.kext
            mv "$dir"/temp/VoodooI2C/VoodooI2CHID.kext "$efi"/Kexts/VoodooI2CHID.kext
        ;;
        5 )
            info "Downloading VoodooI2C, VoodooI2CFTE..."
            curl -Ls "$VOODOOI2C_RELEASE_URL" -o "$dir"/temp/VoodooI2C.zip
            unzip -q "$dir"/temp/VoodooI2C.zip -d "$dir"/temp/VoodooI2C
            mv "$dir"/temp/VoodooI2C/VoodooI2C.kext "$efi"/Kexts/VoodooI2C.kext
            mv "$dir"/temp/VoodooI2C/VooodooI2CFTE.kext "$efi"/VooodooI2CFTE.kext
        ;;
        6 )
            info "Downloading VoodooI2C, VoodooI2CAtmelMXT"
            curl -Ls "$VOODOOI2C_RELEASE_URL" -o "$dir"/temp/VoodooI2C.zip
            unzip -q "$dir"/temp/VoodooI2C.zip -d "$dir"/temp/VoodooI2C
            mv "$dir"/temp/VodoooI2C/VoodooI2C.kext "$efi"/Kexts/VoodooI2C.kext
            mv "$dir"/temp/VoodooI2C/VoodooI2CAtmelMXT.kext "$efi"/Kexts/VoodooI2CAtmelMXT.kext
        ;;
        7 )
            info "Downloading VoodoI2C, VoodooRMI..."
            curl -Ls "$VOODOOI2C_RELEASE_URL" -o "$dir"/temp/VoodooI2C.zip
            curl -Ls "$VOODOORMI_RELEASE_URL" -o "$dir"/temp/VoodooRMI.zip
            unzip -q "$dir"/temp/VoodooI2c.zip -d "$dir"/temp/VoodooI2C
            unzip -q "$dir"/temp/VoodooRMI.zip -d "$dir"/temp/VoodooRMI
            mv "$dir"/temp/VoodooI2C/VoodooI2C.kext "$efi"/Kexts/VoodooI2C.kext
            mv "$dir"/temp/VoodooRMI/VoodooRMI.kext "$efi"/Kexts/VoodooRMI.kext
        ;;
        8 )
            info "Downloading AlpsHID..."
            curl -Ls "$ALPS_HID_RELEASE_URL" -o "$dir"/temp/AlpsHID.zip
            unzip -q "$dir"/temp/AlpsHID.zip -d "$dir"/temp/AlpsHID
            mv "$dir"/temp/AlpsHID/AlpsHID.kext "$efi"/Kexts/AlpsHID.kext
        ;;
        * )
            error "Invalid Choice."
            laptop_input_screen
        ;;
    esac
}

info "Downloading VoodooPS2 for PS/2 laptop keyboard..."
curl -Ls "$VOODOOPS2_RELEASE_URL" -o "$dir"/temp/VoodooPS2Controller.zip
unzip -q "$dir"/temp/VoodooPS2Controller.zip -d "$dir"/temp/VoodooPS2Controller
mv "$dir"/temp/VoodooPS2Controller/VoodooPS2Controller.kext "$efi"/Kexts/VoodooPS2Controller.kext


case $pc_choice in
    1 )
        echo "" > /dev/null
    ;;
    2 )
        laptop_input_screen
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
acpi_desktop() {
    echo "################################################################"
    echo "Now, we need to download ACPI"
    echo "1. Haswell and Broadwell"
    echo "2. Skylake & Kaby Lake"
    echo "3. Coffee Lake"
    echo "4. Comet Lake"
    : 'echo "5. Bulldozer(15h) and Jaguar(16h)"
    echo "6. Ryzen and Threadripper(17h and 19h)"'
    echo "################################################################"
    read -r -p "Pick a number 1-4: " acpidesktop_choice
}

acpi_func() {
    case $pc_choice in 
    1 )
        acpi_desktop
    ;;
    2 )
        acpi_laptop
    ;;
    esac
}
acpi_func

case $pc_choice in
    1 )
       case $acpidesktop_choice in
           4 )
                echo "################################################################"
                echo "We'll need to ask you this question for gathering ACPI files."
                echo "Do you have an Asus's 400 series motherboard?"
                echo "################################################################"
                read -r -p "y/n: " asus_mb_choice
            ;;
        esac
    ;;
esac

case $pc_choice in
    2 )
        case $acpilaptop_choice in
            4 )
                echo "################################################################"
                echo "We'll need to ask you this question for gathering ACPI files."
                echo "Is your laptop a 9th gen or a 10th gen chip?"
                echo "1. 9th gen"
                echo "2. 10th gen"
                echo "################################################################"
                read -r -p "Pick a number 1 or 2: " laptopgen_choice
            ;;
        esac
esac

#case $pc_choice in
#    3 )
#       case $acpidesktop_choice in
#           6 )
#                echo "################################################################"
#                echo "We'll need to ask you this question for gathering ACPI files."
#                echo "Do you have an AM5 series motherboard? (B550/A520)"
#                echo "################################################################"
#                read -r -p "y/n: " am5_desktop_choice
#            ;;
#        esac
#    ;;
#esac


case $pc_choice in 
    1 )
        case $acpidesktop_choice in
            1 )
                info "Downloading SSDT-PLUG-DRTNIA..."
                curl -Ls "$SSDT_PLUG_DRTNIA" -o "$efi"/ACPI/SSDT-PLUG-DRTNIA.aml
                info "Downloading SSDT-EC-DESKTOP..."
                curl -Ls "$SSDT_EC_DESKTOP" -o "$efi"/ACPI/SSDT-EC-DESKTOP.aml
            ;;
            2 )
                info "Downloading SSDT-PLUG-DRTNIA..."
                curl -Ls "$SSDT_PLUG_DRTNIA" -o "$efi"/ACPI/SSDT-PLUG-DRTNIA.aml
                info "Downloading SSDT-EC-USBX-DESKTOP..."
                curl -Ls "$SSDT_EC_USBX_DESKTOP" -o "$efi"/ACPI/SSDT-EC-USBX-DESKTOP.aml
            ;;
            3 )
                info "Downloading SSDT-PLUG-DRTNIA..."
                curl -Ls "$SSDT_PLUG_DRTNIA" -o "$efi"/ACPI/SSDT-PLUG-DRTNIA.aml
                info "Downloading SSDT-EC-USBX-DESKTOP..."
                curl -Ls "$SSDT_EC_USBX_DESKTOP" -o "$efi"/ACPI/SSDT-EC-USBX-DESKTOP.aml
                info "Downloading SSDT-AWAC..."
                curl -Ls "$SSDT_AWAC" -o "$efi"/ACPI/SSDT-AWAC.aml
                info "Downloading SSDT-PMC..."
                curl -Ls "$SSDT_PMC" -o "$efi"/ACPI/SSDT-PMC.aml
            ;;
            4 )
                info "Downloading SSDT-PLUG-DRTNIA..."
                curl -Ls "$SSDT_PLUG_DRTNIA" -o "$efi"/ACPI/SSDT-PLUG-DRTNIA.aml
                info "Downloading SSDT-EC-USBX-DESKTOP..."
                curl -Ls "$SSDT_EC_USBX_DESKTOP" -o "$efi"/ACPI/SSDT-EC-USBX-DESKTOP.aml
                info "Downloading SSDT-AWAC..."
                curl -Ls "$SSDT_AWAC" -o "$efi"/ACPI/SSDT-AWAC.aml
                case $asus_mb_choice in
                    y|Y|Yes|YES|yes )
                        info "Downloading SSDT-RHUB..."
                        curl -Ls "$SSDT_RHUB" -o "$efi"/ACPI/SSDT-RHUB.aml
                    ;;
                esac
            ;;
            : '5 )
                info "Downloading SSDT-EC-USBX-DESKTOP..."
                curl -Ls $SSDT_EC_USBX_DESKTOP -o "$efi"/ACPI/SSDT-EC-USBX-DESKTOP.aml
            ;;
            6 )
                info "Dowloading SSDT-EC-USBX-DESKTOP..."
                curl -Ls "$SSDT_EC_USBX_DESKTOP" -o "$efi"/ACPI/SSDT-EC-USBX-DESKTOP.aml
                case $am5_desktop_choice in
                    y|Y|YES|Yes|yes )
                        info "Downloading SSDT-CPUR..."
                        curl -Ls "$SSDT_CPUR" -o "$efi"/ACPI/SSDT-CPUR.aml
                esac
            ;;'
            * )
                error "Invalid Choice"
                acpi_desktop
            ;;
        esac
    ;;
    2 )
        case $acpilaptop_choice in
            1 )
                info "Downloading SSDT-PLUG-DRTNIA..."
                curl -Ls "$SSDT_PLUG_DRTNIA" -o "$efi"/ACPI/SSDT-PLUG-DRTNIA.aml
                info "Downloading SSDT-EC-LAPTOP..."
                curl -Ls "$SSDT_EC_LAPTOP" -o "$efi"/ACPI/SSDT-EC-LAPTOP.aml
                info "Downloading SSDT-PLNF..."
                curl -Ls "$SSDT_PNLF" -o "$efi"/ACPI/SSDT-PNLF.aml
                info "Downloading SSDT-XOSI..."
                curl -Ls "$SSDT_XOSI" -o "$efi"/ACPI/SSDT-XOSI.aml
            ;;
            2 )
                info "Downloading SSDT-PLUG_DRTNIA..."
                curl -Ls "$SSDT_PLUG_DRTNIA" -o "$efi"/ACPI/SSDT-PLUG-DRTNIA.aml
                info "Downloading SSDT-EC-USBX-LAPTOP..."
                curl -Ls "$SSDT_EC_USBX_LAPTOP" -o "$efi"/ACPI/SSDT-EC-USBX-LAPTOP.aml
                info "Downloading SSDT-PNLF..."
                curl -Ls "$SSDT_PNLF" -o "$efi"/ACPI/SSDT-PNLF.aml
                info "Downloading SSDT-XOSI..."
                curl -Ls "$SSDT_XOSI" -o "$efi"/ACPI/SSDT-XOSI.aml
            ;;
            3 )
                info "Downloading SSDT-PLUG-DRTNIA..."
                curl -Ls "$SSDT_PLUG_DRTNIA" -o "$efi"/ACPI/SSDT-PLUG-DRTNIA.aml
                info "Downloading SSDT-EC-USBX-LAPTOP..."
                curl -Ls "$SSDT_EC_USBX_LAPTOP" -o "$efi"/ACPI/SSDT-EC-USBX-LAPTOP.aml
                info "Downloading SSDT-AWAC..."
                curl -Ls "$SSDT_AWAC" -o "$efi"/ACPI/SSDT-AWAC.aml
                info "Downloading SSDT-PNLF..."
                curl -Ls "$SSDT_PNLF" -o "$efi"/ACPI/SSDT-PNLF.aml
                info "Downloading SSDT-XOSI..."
                curl -Ls "$SSDT_XOSI" -o "$efi"/ACPI/SSDT-XOSI.aml
            ;;
            4 )
                info "Downloading SSDT-PLUG-DRTNIA..."
                curl -Ls "$SSDT_PLUG_DRTNIA" -o "$efi"/ACPI/SSDT-PLUG-DRTNIA.aml
                info "Downloading SSDT-EC-USBX-LAPTOP..."
                curl -Ls "$SSDT_EC_USBX_LAPTOP" -o "$efi"/ACPI/SSDT-EC-USBX-LAPTOP.aml
                info "Downloading SSDT-AWAC..."
                curl -Ls "$SSDT_AWAC" -o "$efi"/ACPI/SSDT-AWAC.aml
                case $laptopgen_choice in
                    1 )
                        info "Downloading SSDT-PMC..."
                        curl -Ls "$SSDT_PMC" -o "$efi"/ACPI/SSDT-PMC.aml
                    ;;
                    2 )
                        echo "" > /dev/null
                    ;;
                    * )
                        error "Invalid Choice"

                esac
                info "Downloading SSDT-PNLF..."
                curl -Ls "$SSDT_PNLF" -o "$efi"/ACPI/SSDT-PNLF.aml
                info "Downloading SSDT-XOSI..."
                curl -Ls "$SSDT_XOSI" -o "$efi"/ACPI/SSDT-XOSI.aml
            ;;
            5 )
                info "Downloading SSDT-PLUG-DRTNIA..."
                curl -Ls "$SSDT_PLUG_DRTNIA" -o "$efi"/ACPI/SSDT-PLUG-DRTNIA.aml
                info "Downloading SSDT-EC-USBX-LAPTOP..."
                curl -Ls "$SSDT_EC_USBX_LAPTOP" -o "$efi"/ACPI/SSDT-EC-USBX-LAPTOP.aml
                info "Downloading SSDT-AWAC..."
                curl -Ls "$SSDT_AWAC" -o "$efi"/ACPI/SSDT-AWAC.aml
                info "Downloading SSDT-RHUB..."
                curl -Ls "$SSDT_RHUB" -o "$efi"/ACPI/SSDT-RHUB.aml
                info "Downloading SSDT-PNLF..."
                curl -Ls "$SSDT_PNLF" -o "$efi"/ACPI/SSDT-PNLF.aml
                info "Downloading SSDT-XOSI..."
                curl -Ls "$SSDT_XOSI" -o "$efi"/ACPI/SSDT-XOSI.aml
            ;;
            * )
                error "Invalid Choice"
                acpi_laptop
            ;;
        esac
    ;;
esac

git clone -q https://github.com/corpnewt/OCSnapshot.git "$dir"/OCSnapshot
info "Adding Driver entries into config.plist..."
info "Adding ACPI entries into config.plist..."
info "Adding Tool entries into config.plist..."
info "Adding Kext entries into config.plist..."
python3 "$dir"/OCSnapshot/OCSnapshot.py -i "$efi"/config.plist -s "$dir"/EFI/EFI/OC -c &> /dev/null


change_plist NVRAM.Add.7C436110-AB2A-4BBB-A880-FE41995C9F82.prev-lang:kbd string
set_plist NVRAM.Add.7C436110-AB2A-4BBB-A880-FE41995C9F82.prev-lang:kbd string "en-US:0"
delete_plist "#WARNING - 1"
delete_plist "#WARNING - 2"
delete_plist "#WARNING - 3"
delete_plist "#WARNING - 4"
delete_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x1b,0x0)"
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
                add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-patch-enable" number
                add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-stolenmem" data
                add_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-fbmem" data
                set_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-patch-enable" number 1
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
    set_plist Misc.Debug.AppleDebug bool True
    set_plist Misc.Debug.ApplePanic bool True
    set_plist Misc.Debug.DisableWatchDog bool True
    set_plist Misc.Debug.Target number 67
    set_plist Misc.Security.AllowSetDefault bool True
    set_plist Misc.Security.BlacklistAppleUpdate bool True
    set_plist Misc.Security.ScanPolicy number 0
    set_plist Misc.Security.SecureBootModel string Default
    set_plist Misc.Security.Vault string Optional
    set_plist NVRAM.Add.7C436110-AB2A-4BBB-A880-FE41995C9F82.boot-args string "-v debug=0x100 alcid=1 keepsyms=1"
    platforminfo() {
        echo "################################################################"
        echo "Now, we need to pick an SMBIOS."
        echo "1. MacBookAir9,1 - CPU: Dual/Quad Core 12W GPU: G4/G7 Display Size: 13inch "
        echo "2. MacBookPro16,2 - CPU: Quad Core 28W GPU: G4/G7 Display Size:13inch "
        echo "################################################################"
        read -r -p "Pick a number 1-2: " smbios_choice
        info "Generating SMBIOS..."
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
    case $os in
        Linux )
            chmod +x "$dir"/Utilities/macserial/macserial.linux
            smbiosoutput=$("$dir"/Utilities/macserial/macserial.linux --num 1 --model "$smbiosname")
        ;;
        Darwin )
            chmod +x "$dir"/Utilities/macserial/macserial
            smbiosoutput=$("$dir"/Utilities/macserial/macserial --num 1 --model "$smbiosname")
        ;;
    esac
    SN=$(echo "$smbiosoutput" | awk -F '|' '{print $1}' | tr -d '[:space:]')
    MLB=$(echo "$smbiosoutput" | awk -F '|' '{print $2}' | tr -d '[:space:]')
    UUID=$(uuidgen)
    set_plist PlatformInfo.Generic.SystemProductName string "$smbiosname"
    set_plist PlatformInfo.Generic.SystemSerialNumber string "$SN"
    set_plist PlatformInfo.Generic.MLB string "$MLB"
    set_plist PlatformInfo.Generic.SystemUUID string "$UUID"
    case $os_choice in
        4 )
            set_plist UEFI.APFS.MinVersion number 1412101001000000
            set_plist UEFI.APFS.MinDate number 20200306
        ;;
        5 )
            set_plist UEFI.APFS.MinVersion number 945275007000000
            set_plist UEFI.APFS.MinDate number 20190820
        ;;
    esac
    set_plist UEFI.Quirks.ReleaseUsbOwnership bool True
    case $hplaptop_choice in
        y|Yes|YES|Y|yes )
            set_plist UEFI.Quirks.UnblockFsConnect bool True
        ;;
    esac
    info "Done!"
    info "Your EFI is located at $dir/EFI"
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
    set_plist Booter.Quirks.SetupVirtualMap bool False
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
    set_plist Misc.Debug.AppleDebug bool True
    set_plist Misc.Debug.ApplePanic bool True
    set_plist Misc.Debug.DisableWatchDog bool True
    set_plist Misc.Debug.Target number 67
    set_plist Misc.Security.AllowSetDefault bool True
    set_plist Misc.Security.BlacklistAppleUpdate bool True
    set_plist Misc.Security.ScanPolicy number 0
    set_plist Misc.Security.SecureBootModel string Default
    set_plist Misc.Security.Vault string Optional
    set_plist NVRAM.Add.7C436110-AB2A-4BBB-A880-FE41995C9F82.boot-args string "-v debug=0x100 alcid=1 keepsyms=1"
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
    case $os in
        Linux )
            chmod +x "$dir"/Utilities/macserial/macserial.linux
            smbiosoutput=$("$dir"/Utilities/macserial/macserial.linux --num 1 --model "$smbiosname")
        ;;
        Darwin )
            chmod +x "$dir"/Utilities/macserial/macserial
            smbiosoutput=$("$dir"/Utilities/macserial/macserial --num 1 --model "$smbiosname")
        ;;
    esac
    SN=$(echo "$smbiosoutput" | awk -F '|' '{print $1}' | tr -d '[:space:]')
    MLB=$(echo "$smbiosoutput" | awk -F '|' '{print $2}' | tr -d '[:space:]')
    UUID=$(uuidgen)
    set_plist PlatformInfo.Generic.SystemProductName string "$smbiosname"
    set_plist PlatformInfo.Generic.SystemSerialNumber string "$SN"
    set_plist PlatformInfo.Generic.MLB string "$MLB"
    set_plist PlatformInfo.Generic.SystemUUID string "$UUID"
    case $os_choice in
        4 )
            set_plist UEFI.APFS.MinVersion number 1412101001000000
            set_plist UEFI.APFS.MinDate number 20200306
        ;;
        5 )
            set_plist UEFI.APFS.MinVersion number 945275007000000
            set_plist UEFI.APFS.MinDate number 20190820
        ;;
    esac
    set_plist UEFI.Quirks.ReleaseUsbOwnership bool True
    case $hplaptop_choice in
        y|Yes|YES|Y|yes )
            set_plist UEFI.Quirks.UnblockFsConnect bool True
        ;;
    esac
    info "Done!"
    info "Your EFI is located in $dir/EFI"
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
    set_plist Misc.Debug.AppleDebug bool True
    set_plist Misc.Debug.ApplePanic bool True
    set_plist Misc.Debug.DisableWatchDog bool True
    set_plist Misc.Debug.Target number 67
    set_plist Misc.Security.AllowSetDefault bool True
    set_plist Misc.Security.BlacklistAppleUpdate bool True
    set_plist Misc.Security.ScanPolicy number 0
    set_plist Misc.Security.SecureBootModel string Default
    set_plist Misc.Security.Vault string Optional
    set_plist NVRAM.Add.7C436110-AB2A-4BBB-A880-FE41995C9F82.boot-args string "-v debug=0x100 alcid=1 keepsyms=1"
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
    case $os in
        Linux )
            chmod +x "$dir"/Utilities/macserial/macserial.linux
            smbiosoutput=$("$dir"/Utilities/macserial/macserial.linux --num 1 --model "$smbiosname")
        ;;
        Darwin )
            chmod +x "$dir"/Utilities/macserial/macserial
            smbiosoutput=$("$dir"/Utilities/macserial/macserial --num 1 --model "$smbiosname")
        ;;
    esac
    SN=$(echo "$smbiosoutput" | awk -F '|' '{print $1}' | tr -d '[:space:]')
    MLB=$(echo "$smbiosoutput" | awk -F '|' '{print $2}' | tr -d '[:space:]')
    UUID=$(uuidgen)
    set_plist PlatformInfo.Generic.SystemProductName string "$smbiosname"
    set_plist PlatformInfo.Generic.SystemSerialNumber string "$SN"
    set_plist PlatformInfo.Generic.MLB string "$MLB"
    set_plist PlatformInfo.Generic.SystemUUID string "$UUID"
    case $os_choice in
        4 )
            set_plist UEFI.APFS.MinVersion number 1412101001000000
            set_plist UEFI.APFS.MinDate number 20200306
        ;;
        5 )
            set_plist UEFI.APFS.MinVersion number 945275007000000
            set_plist UEFI.APFS.MinDate number 20190820
        ;;
    esac
    set_plist UEFI.Quirks.ReleaseUsbOwnership bool True
    case $hplaptop_choice in
        y|Yes|YES|Y|yes )
            set_plist UEFI.Quirks.UnblockFsConnect bool True
        ;;
    esac
    info "Done!"
    info "Your EFI is located in $dir/EFI"    
}

kabylake_laptop_config_setup() {
    info "Configuring config.plist for Kaby Lake Laptop..."
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
                error "Invalid Choice"
                chromebook
            ;;
        esac
    }
    chromebook
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
    set_plist Misc.Debug.AppleDebug bool True
    set_plist Misc.Debug.ApplePanic bool True
    set_plist Misc.Debug.DisableWatchDog bool True
    set_plist Misc.Debug.Target number 67
    set_plist Misc.Security.AllowSetDefault bool True
    set_plist Misc.Security.BlacklistAppleUpdate bool True
    set_plist Misc.Security.ScanPolicy number 0
    set_plist Misc.Security.SecureBootModel string Default
    set_plist Misc.Security.Vault string Optional
    set_plist NVRAM.Add.7C436110-AB2A-4BBB-A880-FE41995C9F82.boot-args string "-v debug=0x100 alcid=1 keepsyms=1"
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
    case $os in
        Linux )
            chmod +x "$dir"/Utilities/macserial/macserial.linux
            smbiosoutput=$("$dir"/Utilities/macserial/macserial.linux --num 1 --model "$smbiosname")
        ;;
        Darwin )
            chmod +x "$dir"/Utilities/macserial/macserial
            smbiosoutput=$("$dir"/Utilities/macserial/macserial --num 1 --model "$smbiosname")
        ;;
    esac
    SN=$(echo "$smbiosoutput" | awk -F '|' '{print $1}' | tr -d '[:space:]')
    MLB=$(echo "$smbiosoutput" | awk -F '|' '{print $2}' | tr -d '[:space:]')
    UUID=$(uuidgen)
    set_plist PlatformInfo.Generic.SystemProductName string "$smbiosname"
    set_plist PlatformInfo.Generic.SystemSerialNumber string "$SN"
    set_plist PlatformInfo.Generic.MLB string "$MLB"
    set_plist PlatformInfo.Generic.SystemUUID string "$UUID"
    case $os_choice in
        4 )
            set_plist UEFI.APFS.MinVersion number 1412101001000000
            set_plist UEFI.APFS.MinDate number 20200306
        ;;
        5 )
            set_plist UEFI.APFS.MinVersion number 945275007000000
            set_plist UEFI.APFS.MinDate number 20190820
        ;;
    esac
    set_plist UEFI.Quirks.ReleaseUsbOwnership bool True
    case $hplaptop_choice in
        y|Yes|YES|Y|yes )
            set_plist UEFI.Quirks.UnblockFsConnect bool True
        ;;
    esac
    info "Done!"
    info "Your EFI is located at $dir/EFI"
}

skylake_laptop_config_setup() {
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
    set_plist Misc.Debug.AppleDebug bool True
    set_plist Misc.Debug.ApplePanic bool True
    set_plist Misc.Debug.DisableWatchDog bool True
    set_plist Misc.Debug.Target number 67
    set_plist Misc.Security.AllowSetDefault bool True
    set_plist Misc.Security.BlacklistAppleUpdate bool True
    set_plist Misc.Security.ScanPolicy number 0
    set_plist Misc.Security.SecureBootModel string Default
    set_plist Misc.Security.Vault string Optional
    set_plist NVRAM.Add.7C436110-AB2A-4BBB-A880-FE41995C9F82.boot-args string "-v debug=0x100 alcid=1 keepsyms=1"
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

    case $os in
        Linux )
            chmod +x "$dir"/Utilities/macserial/macserial.linux
            smbiosoutput=$("$dir"/Utilities/macserial/macserial.linux --num 1 --model "$smbiosname")
        ;;
        Darwin )
            chmod +x "$dir"/Utilities/macserial/macserial
            smbiosoutput=$("$dir"/Utilities/macserial/macserial --num 1 --model "$smbiosname")
        ;;
    esac
    SN=$(echo "$smbiosoutput" | awk -F '|' '{print $1}' | tr -d '[:space:]')
    MLB=$(echo "$smbiosoutput" | awk -F '|' '{print $2}' | tr -d '[:space:]')
    UUID=$(uuidgen)
    set_plist PlatformInfo.Generic.SystemProductName string "$smbiosname"
    set_plist PlatformInfo.Generic.SystemSerialNumber string "$SN"
    set_plist PlatformInfo.Generic.MLB string "$MLB"
    set_plist PlatformInfo.Generic.SystemUUID string "$UUID"
    case $os_choice in
        4 )
            set_plist UEFI.APFS.MinVersion number 1412101001000000
            set_plist UEFI.APFS.MinDate number 20200306
        ;;
        5 )
            set_plist UEFI.APFS.MinVersion number 945275007000000
            set_plist UEFI.APFS.MinDate number 20190820
        ;;
    esac
    set_plist UEFI.Quirks.ReleaseUsbOwnership bool True
    case $hplaptop_choice in
        y|Yes|YES|Y|yes )
            set_plist UEFI.Quirks.UnblockFsConnect bool True
        ;;
    esac
    info "Done!"
    info "Your EFI is located at $dir/EFI"
}

broadwell_laptop_config_setup() {
    info "Configuring config.plit for Broadwell Laptop..."
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
    set_plist Misc.Debug.AppleDebug bool True
    set_plist Misc.Debug.ApplePanic bool True
    set_plist Misc.Debug.DisableWatchDog bool True
    set_plist Misc.Debug.Target number 67
    set_plist Misc.Security.AllowSetDefault bool True
    set_plist Misc.Security.BlacklistAppleUpdate bool True
    set_plist Misc.Security.ScanPolicy number 0
    set_plist Misc.Security.SecureBootModel string Default
    set_plist Misc.Security.Vault string Optional
    set_plist NVRAM.Add.7C436110-AB2A-4BBB-A880-FE41995C9F82.boot-args string "-v debug=0x100 alcid=1 keepsyms=1"
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
        read -r -p "Pick a number 1-9: " smbios_choice
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
    case $os in
        Linux )
            chmod +x "$dir"/Utilities/macserial/macserial.linux
            smbiosoutput=$("$dir"/Utilities/macserial/macserial.linux --num 1 --model "$smbiosname")
        ;;
        Darwin )
            chmod +x "$dir"/Utilities/macserial/macserial
            smbiosoutput=$("$dir"/Utilities/macserial/macserial --num 1 --model "$smbiosname")
        ;;
    esac
    SN=$(echo "$smbiosoutput" | awk -F '|' '{print $1}' | tr -d '[:space:]')
    MLB=$(echo "$smbiosoutput" | awk -F '|' '{print $2}' | tr -d '[:space:]')
    UUID=$(uuidgen)
    set_plist PlatformInfo.Generic.SystemProductName string "$smbiosname"
    set_plist PlatformInfo.Generic.SystemSerialNumber string "$SN"
    set_plist PlatformInfo.Generic.MLB string "$MLB"
    set_plist PlatformInfo.Generic.SystemUUID string "$UUID"
    case $os_choice in
        4 )
            set_plist UEFI.APFS.MinVersion number 1412101001000000
            set_plist UEFI.APFS.MinDate number 20200306
        ;;
        5 )
            set_plist UEFI.APFS.MinVersion number 945275007000000
            set_plist UEFI.APFS.MinDate number 20190820
        ;;
    esac
    set_plist UEFI.Quirks.ReleaseUsbOwnership bool True
    set_plist UEFI.Quirks.IgnoreInvalidFlexRatio bool True
    case $hplaptop_choice in
        y|Yes|YES|Y|yes )
            set_plist UEFI.Quirks.UnblockFsConnect bool True
        ;;
    esac
    info "Done!"
    info "Your EFI is located at $dir/EFI"
    warning "You must disable CFG-Lock in BIOS."
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
    import_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).framebuffer-cursormem" data 00009000
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
    set_plist Misc.Debug.AppleDebug bool True
    set_plist Misc.Debug.ApplePanic bool True
    set_plist Misc.Debug.DisableWatchDog bool True
    set_plist Misc.Debug.Target number 67
    set_plist Misc.Security.AllowSetDefault bool True
    set_plist Misc.Security.BlacklistAppleUpdate bool True
    set_plist Misc.Security.ScanPolicy number 0
    set_plist Misc.Security.SecureBootModel string Default
    set_plist Misc.Security.Vault string Optional
    set_plist NVRAM.Add.7C436110-AB2A-4BBB-A880-FE41995C9F82.boot-args string "-v debug=0x100 alcid=1 keepsyms=1"
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
    case $os in
        Linux )
            chmod +x "$dir"/Utilities/macserial/macserial.linux
            smbiosoutput=$("$dir"/Utilities/macserial/macserial.linux --num 1 --model "$smbiosname")
        ;;
        Darwin )
            chmod +x "$dir"/Utilities/macserial/macserial
            smbiosoutput=$("$dir"/Utilities/macserial/macserial --num 1 --model "$smbiosname")
        ;;
    esac
    SN=$(echo "$smbiosoutput" | awk -F '|' '{print $1}' | tr -d '[:space:]')
    MLB=$(echo "$smbiosoutput" | awk -F '|' '{print $2}' | tr -d '[:space:]')
    UUID=$(uuidgen)
    set_plist PlatformInfo.Generic.SystemProductName string "$smbiosname"
    set_plist PlatformInfo.Generic.SystemSerialNumber string "$SN"
    set_plist PlatformInfo.Generic.MLB string "$MLB"
    set_plist PlatformInfo.Generic.SystemUUID string "$UUID"
    case $os_choice in
        4 )
            set_plist UEFI.APFS.MinVersion number 1412101001000000
            set_plist UEFI.APFS.MinDate number 20200306
        ;;
        5 )
            set_plist UEFI.APFS.MinVersion number 945275007000000
            set_plist UEFI.APFS.MinDate number 20190820
        ;;
    esac
    set_plist UEFI.Quirks.ReleaseUsbOwnership bool True
    set_plist UEFI.Quirks.IgnoreInvalidFlexRatio True
    case $hplaptop_choice in
        y|Yes|YES|Y|yes )
            set_plist UEFI.Quirks.UnblockFsConnect bool True
        ;;
    esac
    info "Done!"
    info "Your EFI is located at $dir/EFI"
    warning "You must enable CFG-Lock in BIOS."
}

haswell_broadwell_desktop_config_setup() {
    #gumi note: will update device properties to new format later
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
    echo "$plat_id" | xxd -r -p - > "$dir"/temp/aapl_id.bin
    import_plist "DeviceProperties.Add.PciRoot(0x0)/Pci(0x2,0x0).AAPL,ig-platform-id" "$dir"/temp/aapl_id.bin
    hd4400() {
        echo "################################################################"
        echo "Do you have a HD4400?"
        echo "################################################################"
        read -r -p "y/n: " hd4400_choice
        case $hd4400_choice in
            y|Y|YES|Yes|yes )   
                add_plist ":DeviceProperties:Add:PciRoot(0x0)/Pci(0x2,0x0):device-id" data
                echo "12040000" | xxd -r -p - > "$dir"/temp/deviceid.bin
                import_plist ":DeviceProperties:Add:PciRoot(0x0)/Pci(0x2,0x0):device-id" "$dir"/temp/deviceid.bin
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
                echo "01000000" | xxd -r -p - > "$dir"/temp/framebuffer_patch_enable.bin
                echo "00003001" | xxd -r -p - > "$dir"/temp/framebuffer_stolenmem.bin 
                echo "00009000" | xxd -r -p - > "$dir"/temp/framebuffer_fbmem
                add_plist ":DeviceProperties:Add:PciRoot(0x0)/Pci(0x2,0x0):framebuffer-patch-enable" data
                add_plist ":DeviceProperties:Add:PciRoot(0x0)/Pci(0x2,0x0):framebuffer-stolenmem" data
                add_plist ":DeviceProperties:Add:PciRoot(0x0)/Pci(0x2,0x0):framebuffer-fbmem" data
                import_plist ":DeviceProperties:Add:PciRoot(0x0)/Pci(0x2,0x0):framebuffer-patch-enable" "$dir"/temp/framebuffer-patch-enable.bin
                import_plist ":DeviceProperties:Add:PciRoot(0x0)/Pci(0x2,0x0):framebuffer-stolenmem" "$dir"/temp/framebuffer-stolenmem.bin
                import_plist ":DeviceProperties:Add:PciRoot(0x0)/Pci(0x2,0x0):framebuffer-fbmem" "$dir"/temp/framebuffer-fbmem.bin
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
    set_plist Kernel.Quirks.DisableIoMapper bool True
    set_plist Kernel.Quirks.PanicNoKextDump bool True
    set_plist Kernel.Quirks.PowerTimeoutKernelPanic bool True
    case $os_choice in
        4|5 ) 
             set_plist Kernel.Quirks.XhciPortLimit False
        ;;
    esac
    set_plist Misc.Debug.AppleDebug bool True
    set_plist Misc.Debug.ApplePanic bool True
    set_plist Misc.Debug.DisableWatchDog bool True
    set_plist Misc.Debug.Target number 67
    set_plist Misc.Security.AllowSetDefault bool True
    set_plist Misc.Security.BlacklistAppleUpdate bool True
    set_plist Misc.Security.ScanPolicy number 0
    set_plist Misc.Security.SecureBootModel string Default
    set_plist Misc.Security.Vault string Optional
    set_plist NVRAM.Add.7C436110-AB2A-4BBB-A880-FE41995C9F82.boot-args string "-v debug=0x100 alcid=1 keepsyms=1"
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
    case $os in
        Linux )
            chmod +x "$dir"/Utilities/macserial/macserial.linux
            smbiosoutput=$("$dir"/Utilities/macserial/macserial.linux --num 1 --model "$smbiosname")
        ;;
        Darwin )
            chmod +x "$dir"/Utilities/macserial/macserial
            smbiosoutput=$("$dir"/Utilities/macserial/macserial --num 1 --model "$smbiosname")
        ;;
    esac
    SN=$(echo "$smbiosoutput" | awk -F '|' '{print $1}' | tr -d '[:space:]')
    MLB=$(echo "$smbiosoutput" | awk -F '|' '{print $2}' | tr -d '[:space:]')
    UUID=$(uuidgen)
    set_plist PlatformInfo.Generic.SystemProductName string "$smbiosname"
    set_plist PlatformInfo.Generic.SystemSerialNumber string "$SN"
    set_plist PlatformInfo.Generic.MLB string "$MLB"
    set_plist PlatformInfo.Generic.SystemUUID string "$UUID"
    case $os_choice in
        4 )
            set_plist UEFI.APFS.MinVersion number 1412101001000000
            set_plist UEFI.APFS.MinDate number 20200306
        ;;
        5 )
            set_plist UEFI.APFS.MinVersion number 945275007000000
            set_plist UEFI.APFS.MinDate number 20190820
        ;;
    esac
    set_plist UEFI.Quirks.IgnoreInvalidFlexRatio True
    case $hpdesktop_choice in
        y|Yes|YES|Y|yes )
            set_plist UEFI.Quirks.UnblockFsConnect bool True
        ;;
    esac
    info "Done!"
    info "Your EFI is located at $dir/EFI"
    warning "Please disable the following options in the BIOS.\nFast Boot\nSecure Boot\nSerial/COM Port\nParallel Port\nVT-d\n Compatibility Support Module (CSM)\nThunderbolt (For initial install)\nIntel SGX\nIntel Platform Trust"
    warning "Please enable the following options in the BIOS.\nVT-x\nAbove 4G Decoding\nHyper-Threading\nExecute Disable Bit\nEHCI-XHCI Hand-off\n OS Type (Other OS) Windows 8.1/10 UEFI Mode\nDVMT Pre-Allocated(iGPU Memory) 64MB or higher\nSATA Mode: AHCI\nCFG Lock"
}

skylake_laptop_config_setup(){
    #device properties go here
    cfg(){
        echo "################################################################"
        echo "Is CFG-Lock enabled in BIOS?"
        echo "################################################################"
        read -r -p "y/n: " cfg_choice
        case $cfg_choice in
            y|Y|YES|yes|Yes )
                echo > "" /dev/null
            ;;
            N|n|NO|No|no )
                set_plist Kernel.Quirks.AppleXcpmCfgLock bool True
            ;;
            * )
                error "Invalid Choice"
                cfg
        esac
    }
    cfg
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
    set_plist Misc.Debug.AppleDebug bool True
    set_plist Misc.Debug.ApplePanic bool True
    set_plist Misc.Debug.DisableWatchDog bool True
    set_plist Misc.Debug.Target number 67
    set_plist Misc.Security.AllowSetDefault bool True
    set_plist Misc.Security.BlacklistAppleUpdate bool True
    set_plist Misc.Security.ScanPolicy number 0
    set_plist Misc.Security.SecureBootModel string Default
    set_plist Misc.Security.Vault string Optional
    set_plist NVRAM.Add.7C436110-AB2A-4BBB-A880-FE41995C9F82.boot-args string "-v debug=0x100 alcid=1 keepsyms=1"
    platforminfo_setup(){
        smbiosname=iMac17,1
    }
    # idk if this is mandatory for ventura platform info to function
    platforminfo_setup_ventura(){
        echo "################################################################"
        echo "Now, we need to pick a Kaby Lake SMBIOS, even though this is a Skylake machine."
        echo "Pick the closest one to your hardware."
        echo "1. iMac18,1 - Used for computers utilizing the iGPU for displaying"
        echo "2. iMac18,3 - Used for computers using a dGPU for displaying, and an iGPU for computing tasks only"
        echo "################################################################"
        read -r -p "Pick a number between 1-2: " smbios_choice
        case $smbios_choice in
            1 )
                smbiosname="iMac18,1"
            ;;
            2 )
                smbiosname="iMac18,3"
            ;;
            * )
                error "Invalid Choice"
                platforminfo_setup_ventura
            ;;
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
    case $os in
        Linux )
            chmod +x "$dir"/Utilities/macserial/macserial.linux
            smbiosoutput=$("$dir"/Utilities/macserial/macserial.linux --num 1 --model "$smbiosname")
        ;;
        Darwin )
            chmod +x "$dir"/Utilities/macserial/macserial
            smbiosoutput=$("$dir"/Utilities/macserial/macserial --num 1 --model "$smbiosname")
        ;;
    esac
    SN=$(echo "$smbiosoutput" | awk -F '|' '{print $1}' | tr -d '[:space:]')
    MLB=$(echo "$smbiosoutput" | awk -F '|' '{print $2}' | tr -d '[:space:]')
    UUID=$(uuidgen)
    set_plist PlatformInfo.Generic.SystemProductName string "$smbiosname"
    set_plist PlatformInfo.Generic.SystemSerialNumber string "$SN"
    set_plist PlatformInfo.Generic.MLB string "$MLB"
    set_plist PlatformInfo.Generic.SystemUUID string "$UUID"
    case $os_choice in
        4 )
            set_plist UEFI.APFS.MinVersion number 1412101001000000
            set_plist UEFI.APFS.MinDate number 20200306
        ;;
        5 )
            set_plist UEFI.APFS.MinVersion number 945275007000000
            set_plist UEFI.APFS.MinDate number 20190820
        ;;
    esac
    set_plist UEFI.Quirks.IgnoreInvalidFlexRatio bool True
    case $hpdesktop_choice in
        y|Yes|YES|Y|yes )
            set_plist UEFI.Quirks.UnblockFsConnect bool True
        ;;
    esac
    info "Done!"
    info "Your EFI is located at $dir/EFI"
    warning "Please disable the following options in the BIOS.\nFast Boot\nSecure Boot\nSerial/COM Port\nParallel Port\nVT-d\n Compatibility Support Module (CSM)\nThunderbolt (For initial install)\nIntel SGX\nIntel Platform Trust\nCFG Lock"
    warning "Please enable the following options in the BIOS.\nVT-x\nAbove 4G Decoding\nHyper-Threading\nExecute Disable Bit\nEHCI-XHCI Hand-off\n OS Type (Other OS) Windows 8.1/10 UEFI Mode\nDVMT Pre-Allocated(iGPU Memory) 64MB or higher\nSATA Mode: AHCI\nCFG Lock"
}

kabylake_desktop_config_setup(){
    #device properties go here
        cfg(){
        echo "################################################################"
        echo "Is CFG-Lock enabled in BIOS?"
        echo "################################################################"
        read -r -p "y/n: " cfg_choice
        case $cfg_choice in
            y|Y|YES|yes|Yes )
                echo > "" /dev/null
            ;;
            N|n|NO|No|no )
                set_plist Kernel.Quirks.AppleXcpmCfgLock bool True
            ;;
            * )
                error "Invalid Choice"
                cfg
        esac
    }
    cfg
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
    set_plist Misc.Debug.AppleDebug bool True
    set_plist Misc.Debug.ApplePanic bool True
    set_plist Misc.Debug.DisableWatchDog bool True
    set_plist Misc.Debug.Target number 67
    set_plist Misc.Security.AllowSetDefault bool True
    set_plist Misc.Security.BlacklistAppleUpdate bool True
    set_plist Misc.Security.ScanPolicy number 0
    set_plist Misc.Security.SecureBootModel string Default
    set_plist Misc.Security.Vault string Optional
    set_plist NVRAM.Add.7C436110-AB2A-4BBB-A880-FE41995C9F82.boot-args string "-v debug=0x100 alcid=1 keepsyms=1"
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
    case $os in
        Linux )
            chmod +x "$dir"/Utilities/macserial/macserial.linux
            smbiosoutput=$("$dir"/Utilities/macserial/macserial.linux --num 1 --model "$smbiosname")
        ;;
        Darwin )
            chmod +x "$dir"/Utilities/macserial/macserial
            smbiosoutput=$("$dir"/Utilities/macserial/macserial --num 1 --model "$smbiosname")
        ;;
    esac
    SN=$(echo "$smbiosoutput" | awk -F '|' '{print $1}' | tr -d '[:space:]')
    MLB=$(echo "$smbiosoutput" | awk -F '|' '{print $2}' | tr -d '[:space:]')
    UUID=$(uuidgen)
    set_plist PlatformInfo.Generic.SystemProductName string "$smbiosname"
    set_plist PlatformInfo.Generic.SystemSerialNumber string "$SN"
    set_plist PlatformInfo.Generic.MLB string "$MLB"
    set_plist PlatformInfo.Generic.SystemUUID string "$UUID"
    case $os_choice in
        4 )
            set_plist UEFI.APFS.MinVersion number 1412101001000000
            set_plist UEFI.APFS.MinDate number 20200306
        ;;
        5 )
            set_plist UEFI.APFS.MinVersion number 945275007000000
            set_plist UEFI.APFS.MinDate number 20190820
        ;;
    esac
    set_plist UEFI.Quirks.IgnoreInvalidFlexRatio True
    case $hpdesktop_choice in
        y|Yes|YES|Y|yes )
            set_plist UEFI.Quirks.UnblockFsConnect bool True
        ;;
    esac
    info "Done!"
    info "Your EFI is located at $dir/EFI"
    warning "Please disable the following options in the BIOS.\nFast Boot\nSecure Boot\nSerial/COM Port\nParallel Port\nVT-d\nCompatibility Support Module (CSM)\nThunderbolt (For intital install)\nIntel SGX\nIntel Platform Trust\nCFG Lock"
    warning "Please enable the following options in the BIOS.\nVT-x\nAbove 4G Decoding\nHyper-Threading\nExecute Disable Bit\nEHCI/XHCI Hand-off\nOS type: Windows 8.1/10 UEFI Mode (might be Other OS)\nDVMT Pre-Allocated(iGPU Memory): 64MB or higher\nSATA Mode: AHCI"
}

coffeelake_desktop_config_setup(){
    set_plist Booter.Quirks.DevirtualizeMmio bool True
    set_plist Booter.Quirks.EnableWriteUnprotector bool False
    set_plist Booter.Quirks.ProtectUefiServices bool True
    set_plist Booter.Quirks.RebuildAppleMemoryMap bool True
    set_plist Booter.Quirks.ResizeAppleGpuBars number -1
    resizegpu(){
        echo "################################################################"
        echo "Does your GPU support Resizeable BAR?"
        echo "################################################################"
        read -r -p "y/n: " resizegpu_choice
        case $resizegpu_choice in
            Y|y|YES|Yes|yes )
                set_plist Booter.Quirks.ResizeAppleGpuBars number 1
            ;;
            n|N|NO|No|no )
                set_plist Booter.Quirks.ResizeAppleGpuBars number -1
            ;;
            * )
                error "Invalid Choice"
                resizegpu
            esac
    }
    resizegpu
    set_plist Booter.Quirks.SyncRunetimePermissions bool True
    # device properties here 
        cfg(){
        echo "################################################################"
        echo "Is CFG-Lock enabled in BIOS?"
        echo "################################################################"
        read -r -p "y/n: " cfg_choice
        case $cfg_choice in
            y|Y|YES|yes|Yes )
                echo > "" /dev/null
            ;;
            N|n|NO|No|no )
                set_plist Kernel.Quirks.AppleXcpmCfgLock bool True
            ;;
            * )
                error "Invalid Choice"
                cfg
        esac
    }
    cfg
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
    set_plist Misc.Debug.AppleDebug bool True
    set_plist Misc.Debug.ApplePanic bool True
    set_plist Misc.Debug.DisableWatchDog bool True
    set_plist Misc.Debug.Target number 67
    set_plist Misc.Security.AllowSetDefault bool True
    set_plist Misc.Security.BlacklistAppleUpdate bool True
    set_plist Misc.Security.ScanPolicy number 0
    set_plist Misc.Security.SecureBootModel string Default
    set_plist Misc.Security.Vault string Optional
    set_plist NVRAM.Add.7C436110-AB2A-4BBB-A880-FE41995C9F82.boot-args string "-v debug=0x100 alcid=1 keepsyms=1"
    # gpu args go here
    smbiosname=iMac19,1
    case $os in
        Linux )
            chmod +x "$dir"/Utilities/macserial/macserial.linux
            smbiosoutput=$("$dir"/Utilities/macserial/macserial.linux --num 1 --model "$smbiosname")
        ;;
        Darwin )
            chmod +x "$dir"/Utilities/macserial/macserial
            smbiosoutput=$("$dir"/Utilities/macserial/macserial --num 1 --model "$smbiosname")
        ;;
    esac
    SN=$(echo "$smbiosoutput" | awk -F '|' '{print $1}' | tr -d '[:space:]')
    MLB=$(echo "$smbiosoutput" | awk -F '|' '{print $2}' | tr -d '[:space:]')
    UUID=$(uuidgen)
    set_plist PlatformInfo.Generic.SystemProductName string "$smbiosname"
    set_plist PlatformInfo.Generic.SystemSerialNumber string "$SN"
    set_plist PlatformInfo.Generic.MLB string "$MLB"
    set_plist PlatformInfo.Generic.SystemUUID string "$UUID"
    case $os_choice in
        4 )
            set_plist UEFI.APFS.MinVersion number 1412101001000000
            set_plist UEFI.APFS.MinDate number 20200306
        ;;
        5 )
            set_plist UEFI.APFS.MinVersion number 945275007000000
            set_plist UEFI.APFS.MinDate number 20190820
        ;;
    esac
    set_plist UEFI.Quirks.IgnoreInvalidFlexRatio bool True
    case $hpdesktop_choice in
        y|Yes|YES|Y|yes )
            set_plist UEFI.Quirks.UnblockFsConnect bool True
        ;;
    esac
    info "Done!"
    info "Your EFI is located at $dir/EFI"
    warning "Please disable the following options in the BIOS.\nFast Boot\nSecure Boot\nSerial/COM Port\nParallel Port\nVT-d\nCompatibility Support Module (CSM)\nThunderbolt (For intital install)\nIntel SGX\nIntel Platform Trust\nCFG Lock"
    warning "Please enable the following options in the BIOS.\nVT-x\nAbove 4G Decoding\nHyper-Threading\nExecute Disable Bit\nEHCI/XHCI Hand-off\nOS type: Windows 8.1/10 UEFI Mode (might be Other OS)\nDVMT Pre-Allocated(iGPU Memory): 64MB or higher\nSATA Mode: AHCI"
}

cometlake_desktop_config_setup(){
    set_plist Booter.Quirks.DevirtualizeMmio bool True
    set_plist Booter.Quirks.EnableWriteUnprotector bool False
    set_plist Booter.Quirks.ProtectUefiServices bool True
    set_plist Booter.Quirks.RebuildAppleMemoryMap bool True
    set_plist Booter.Quirks.ResizeAppleGpuBars number -1
    set_plist Booter.Quirks.SyncRunetimePermissions bool True
    #device properties here 
    #case $os_choice in
        #4 )
           #import_plist Kernel.Patch. #i dont know how to add a new dictionary >.<
        #;;
    #esac
    cfg(){
        echo "################################################################"
        echo "Is CFG-Lock enabled in BIOS?"
        echo "################################################################"
        read -r -p "y/n: " cfg_choice
        case $cfg_choice in
            y|Y|YES|yes|Yes )
                echo > "" /dev/null
            ;;
            N|n|NO|No|no )
                set_plist Kernel.Quirks.AppleXcpmCfgLock bool True
            ;;
            * )
                error "Invalid Choice"
                cfg
        esac
    }
    cfg
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
    set_plist set_plist Kernel.Quirks.PanicNoKextDump bool True
    set_plist set_plist Kernel.Quirks.PowerTimeoutKernelPanic bool True
    case $os_choice in
        4|5 ) 
             set_plist Kernel.Quirks.XhciPortLimit bool False
        ;;
    esac
    set_plist Misc.Debug.AppleDebug bool True
    set_plist Misc.Debug.ApplePanic bool True
    set_plist Misc.Debug.DisableWatchDog bool True
    set_plist Misc.Debug.Target number 67
    set_plist Misc.Security.AllowSetDefault bool True
    set_plist Misc.Security.BlacklistAppleUpdate bool True
    set_plist Misc.Security.ScanPolicy number 0
    set_plist Misc.Security.SecureBootModel string Default
    set_plist Misc.Security.Vault string Optional
    set_plist NVRAM.Add.7C436110-AB2A-4BBB-A880-FE41995C9F82.boot-args string "-v debug=0x100 alcid=1 keepsyms=1"
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
    case $os in
        Linux )
            chmod +x "$dir"/Utilities/macserial/macserial.linux
            smbiosoutput=$("$dir"/Utilities/macserial/macserial.linux --num 1 --model "$smbiosname")
        ;;
        Darwin )
            chmod +x "$dir"/Utilities/macserial/macserial
            smbiosoutput=$("$dir"/Utilities/macserial/macserial --num 1 --model "$smbiosname")
        ;;
    esac
    SN=$(echo "$smbiosoutput" | awk -F '|' '{print $1}' | tr -d '[:space:]')
    MLB=$(echo "$smbiosoutput" | awk -F '|' '{print $2}' | tr -d '[:space:]')
    UUID=$(uuidgen)
    set_plist PlatformInfo.Generic.SystemProductName string "$smbiosname"
    set_plist PlatformInfo.Generic.SystemSerialNumber string "$SN"
    set_plist PlatformInfo.Generic.MLB string "$MLB"
    set_plist PlatformInfo.Generic.SystemUUID string "$UUID"
    case $os_choice in
        4 )
            set_plist UEFI.APFS.MinVersion number 1412101001000000
            set_plist UEFI.APFS.MinDate number 20200306
        ;;
        5 )
            set_plist UEFI.APFS.MinVersion number 945275007000000
            set_plist UEFI.APFS.MinDate number 20190820
        ;;
    esac
    set_plist UEFI.Quirks.IgnoreInvalidFlexRatio bool True
    case $hpdesktop_choice in
        y|Yes|YES|Y|yes )
            set_plist UEFI.Quirks.UnblockFsConnect bool True
        ;;
    esac
    info "Done!"
    info "Your EFI is located at $dir/EFI"
    warning "Please disable the following options in the BIOS.\nFast Boot\nSecure Boot\nSerial/COM Port\nParallel Port\nVT-d\nCompatibility Support Module (CSM)\nThunderbolt (For intital install)\nIntel SGX\nIntel Platform Trust\nCFG Lock"
    warning "Please enable the following options in the BIOS.\nVT-x\nAbove 4G Decoding\nHyper-Threading\nExecute Disable Bit\nEHCI/XHCI Hand-off\nOS type: Windows 8.1/10 UEFI Mode (might be Other OS)\nDVMT Pre-Allocated(iGPU Memory): 64MB or higher\nSATA Mode: AHCI"
    #gumi note: mayb add smth pertaining to 2020+ bios regarding Above4G
}

: 'amd1516_desktop_config_setup(){
    set_plist Kernel.Emulate.DummyPowerManagement bool True
    # kernel patch start
    set_plist Kernel.Quirks.PanicNoKextDump bool True
    set_plist Kernel.Quirks.PowerTimeoutKernelPanic bool True
    set_plist Kernel.Quirks.ProvideCpuCurrentInfo bool True
    case $os_choice in
        4|5 ) 
             set_plist Kernel.Quirks.XhciPortLimit bool False
        ;;
    esac
    set_plist Misc.Debug.AppleDebug bool True
    set_plist Misc.Debug.ApplePanic bool True
    set_plist Misc.Debug.DisableWatchDog bool True
    set_plist Misc.Debug.Target number 67
    set_plist Misc.Security.AllowSetDefault bool True
    set_plist Misc.Security.BlacklistAppleUpdate bool True
    set_plist Misc.Security.ScanPolicy number 0
    set_plist Misc.Security.SecureBootModel string Default
    set_plist Misc.Security.Vault string Optional
    set_plist NVRAM.Add.7C436110-AB2A-4BBB-A880-FE41995C9F82.boot-args string "-v debug=0x100 alcid=1 keepsyms=1"
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
    case $os in
        Linux )
            chmod +x "$dir"/Utilities/macserial/macserial.linux
            smbiosoutput=$("$dir"/Utilities/macserial/macserial.linux --num 1 --model "$smbiosname")
        ;;
        Darwin )
            chmod +x "$dir"/Utilities/macserial/macserial
            smbiosoutput=$("$dir"/Utilities/macserial/macserial --num 1 --model "$smbiosname")
        ;;
    esac
    SN=$(echo "$smbiosoutput" | awk -F '|' '{print $1}' | tr -d '[:space:]')
    MLB=$(echo "$smbiosoutput" | awk -F '|' '{print $2}' | tr -d '[:space:]')
    UUID=$(uuidgen)
    set_plist PlatformInfo.Generic.SystemProductName string "$smbiosname"
    set_plist PlatformInfo.Generic.SystemSerialNumber string "$SN"
    set_plist PlatformInfo.Generic.MLB string "$MLB"
    set_plist PlatformInfo.Generic.SystemUUID string "$UUID"
    case $os_choice in
        4 )
            set_plist UEFI.APFS.MinVersion number 1412101001000000
            set_plist UEFI.APFS.MinDate number 20200306
        ;;
        5 )
            set_plist UEFI.APFS.MinVersion number 945275007000000
            set_plist UEFI.APFS.MinDate number 20190820
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
    info "Done!"
    info "Your EFI is located at $dir/EFI"
    warning "Please disable the following options in the BIOS.\nFast Boot\nSecure Boot\nSerial/COM Port\nParallel Port\nVT-d\nCompatibility Support Module (CSM)\nIOMMU"
    warning "Please enable the following options in the BIOS.\nAbove 4G Decoding\nEHCI/XHCI Hand-off\nOS type: Windows 8.1/10 UEFI Mode (might be Other OS)\nSATA Mode: AHCI"
}'

: 'amd1719_desktop_config_setup(){
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
                set_plist Booter.Quirks.ResizeAppleGpuBars number 1
            ;;
            n|N|NO|No|no )
                set_plist Booter.Quirks.ResizeAppleGpuBars number -1
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
    # kernel patch start
    set_plist Kernel.Quirks.PanicNoKextDump bool True
    set_plist Kernel.Quirks.PowerTimeoutKernelPanic bool True
    set_plist Kernel.Quirks.ProvideCpuCurrentInfo bool True
    case $os_choice in
        4|5 ) 
             set_plist Kernel.Quirks.XhciPortLimit bool False
        ;;
    esac
    set_plist Misc.Debug.AppleDebug bool True
    set_plist Misc.Debug.ApplePanic bool True
    set_plist Misc.Debug.DisableWatchDog bool True
    set_plist Misc.Debug.Target number 67
    set_plist Misc.Security.AllowSetDefault bool True
    set_plist Misc.Security.BlacklistAppleUpdate bool True
    set_plist Misc.Security.ScanPolicy number 0
    set_plist Misc.Security.SecureBootModel string Default
    set_plist Misc.Security.Vault string Optional
    set_plist NVRAM.Add.7C436110-AB2A-4BBB-A880-FE41995C9F82.boot-args string "-v debug=0x100 alcid=1 keepsyms=1"
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
    case $os in
        Linux )
            chmod +x "$dir"/Utilities/macserial/macserial.linux
            smbiosoutput=$("$dir"/Utilities/macserial/macserial.linux --num 1 --model "$smbiosname")
        ;;
        Darwin )
            chmod +x "$dir"/Utilities/macserial/macserial
            smbiosoutput=$("$dir"/Utilities/macserial/macserial --num 1 --model "$smbiosname")
        ;;
    esac
    SN=$(echo "$smbiosoutput" | awk -F '|' '{print $1}' | tr -d '[:space:]')
    MLB=$(echo "$smbiosoutput" | awk -F '|' '{print $2}' | tr -d '[:space:]')
    UUID=$(uuidgen)
    set_plist PlatformInfo.Generic.SystemProductName string "$smbiosname"
    set_plist PlatformInfo.Generic.SystemSerialNumber string "$SN"
    set_plist PlatformInfo.Generic.MLB string "$MLB"
    set_plist PlatformInfo.Generic.SystemUUID string "$UUID"
    case $os_choice in
        4 )
            set_plist UEFI.APFS.MinVersion number 1412101001000000
            set_plist UEFI.APFS.MinDate number 20200306
        ;;
        5 )
            set_plist UEFI.APFS.MinVersion number 945275007000000
            set_plist UEFI.APFS.MinDate number 20190820
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
    info "Done!"
    info "Your EFI is located at $dir/EFI"
    warning "Please disable the following options in the BIOS.\nFast Boot\nSecure Boot\nSerial/COM Port\nParallel Port\nVT-d\nCompatibility Support Module (CSM)\nIOMMU"
    warning "Please enable the following options in the BIOS.\nAbove 4G Decoding\nEHCI/XHCI Hand-off\nOS type: Windows 8.1/10 UEFI Mode (might be Other OS)\nSATA Mode: AHCI"
}'

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

cpu_rev_desktop() {
    echo "################################################################"
    echo "Now, we need to ask you what generation your processor is."
    echo "1. Haswell"
    echo "2. Broadwell"
    echo "3. Skylake"
    echo "4. Kaby Lake"
    echo "5. Coffee Lake"
    echo "6. Comet Lake"
    : 'echo "7. Bulldozer(15h) and Jaguar (16h)"
     echo "8. Ryzen and Threadripper(17h and 19h)"'
    echo "################################################################"
    read -r -p "Pick a number 1-6: " desktop_cpu_gen_choice
    case $desktop_cpu_gen_choice in
        1 )
            haswell_broadwelldesktop_config_setup
        ;;
        2 ) 
            haswell_broadwell_desktop_config_setup
        ;;
        3 )
            skylake_desktop_config_setup
        ;;
        4 )
            kabylake_desktop_config_setup
        ;;
        5 )
            coffeelake_desktop_config_setup
        ;;
        6 )
            cometlake_desktop_config_setup
        ;;
        # 7 ) 
        #    amd1516_desktop_config_setup
        # ;;
        # 8 ) 
        #    amd1719_desktop_config_setup
        # ;;
        * )
            error "Invalid Choice"
            cpu_rev_desktop
    esac
}

case $pc_choice in # Mac note: i dont know why this makes shellcheck hang and memory leak
    1 )
        cpu_rev_desktop
    ;;
    2 )
        cpu_rev_laptop
    ;;
esac