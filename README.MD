# oc-efi-maker
oc-efi-maker is a script to generate an OpenCore EFI files, to hackintosh your computer.
## Installaton
Running the script locally:
```
git clone https://github.com/itsmaclol/oc-efi-maker.git && cd oc-efi-maker
chmod +x ./opencore.sh
./opencore.sh
```
## Flags
`-h`, `--help` - Prints the help page

`--ignore-internet-check ` - Ignores the internet check at the beginning of the script. Use this if you are 100% sure that you have internet.

`--ignore-dependencies` - Ignores the dependency check at the beginning of the script. Use this if you are 100% sure that you have the dependencies installed.

`--ignore-deps-internet-check` - Ignores both the internet and dependency check at the beginning of the script. Use this if you are 100% sure that you have the dependencies installed and have internet.

# Please Read!
This project was made for fun, and the EFI's that this script generates are only for testing purposes, if you want an actual stable hackintosh, please follow [the dortania guide](https://dortania.github.io/OpenCore-Install-Guide)

## Credits
Apple for macOS

Dortania for the Dortania Opencore guide

acidanthera for Opencore, whatevergreen, applealc, intelmausi etc...

& more...

Made with <3 by Mac
