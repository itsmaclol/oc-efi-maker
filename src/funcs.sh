internet_check() {
    ping -c 1 -W 1 google.com > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo "" > /dev/null
    else
        error "You do not seem to have an internet connection, please connect to the internet and try again, or if you are completely sure that you have internet, use the --ignore-internet-check flag."
        exit 1
    fi
}

add_plist() {
    python3 "$dir"/temp/plisteditor.py -s add "$1" --type "$2" --path "$efi"/config.plist
}

set_plist() {
    python3 "$dir"/temp/plisteditor.py -s set "$1" --type "$2" --value "$3" --path "$efi"/config.plist
}

delete_plist() {
    python3 "$dir"/temp/plisteditor.py -s delete "$1" --path "$efi"/config.plist
}

change_plist() {
    python3 "$dir"/temp/plisteditor.py -s change "$1" --new_type "$2" --path "$efi"/config.plist
}

append_plist() {
    python3 "$dir"/temp/plisteditor.py -s append "$1" --type "$2" --value="$3" --path "$efi"/config.plist
}

remvalue_plist() {
    python3 "$dir"/temp/plisteditor.py remvalue "$1" --type "$2" --value="$3" --path "$efi"/config.plist
}

print_plist() {
     python3 "$dir"/temp/plisteditor.py print "$1" --path "$efi"/config.plist
}

error() {
    echo -e " [${DARK_GRAY}$(date +'%m/%d/%y')${NO_COLOR}] ${RED}[-] ${RED}ERROR${NO_COLOR}: ${RED}$1${NO_COLOR}"
}

info() {
    echo -e " [${DARK_GRAY}$(date +'%m/%d/%y')${NO_COLOR}] ${LIGHT_CYAN}[*] ${LIGHT_CYAN}Misc${NO_COLOR}: ${LIGHT_CYAN}$1${NO_COLOR}"
}

warning() {
    echo -e " [${DARK_GRAY}$(date +'%m/%d/%y')${NO_COLOR}] ${YELLOW} [*] ${YELLOW}Warning${NO_COLOR}: ${YELLOW}$1${NO_COLOR}"
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
    elif command -v zypper >/dev/null 2>&1; then
        PACKAGE_MANAGER="zypper"
    else
        PACKAGE_MANAGER="Unknown"
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
    --extras                     Prints out the extras menu
    --ignore-recovery-download   Ignores the macOS recovery download menu, in case you are just trying to make an efi without the macOS installer.

Warning: This script is made for an elementary opencore EFI, if you want a stable hackintosh please follow the guide over at https://dortania.github.io/OpenCore-Install-Guide/
EOF
exit 1
}