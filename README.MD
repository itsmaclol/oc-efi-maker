# oc-efi-maker
oc-efi-maker is a script to generate an OpenCore EFI files, to Install macOS your computer.
## Installaton
Running the script locally:
### Linux and macOS

```
git clone https://github.com/itsmaclol/oc-efi-maker.git && cd oc-efi-maker
chmod +x ./opencore.sh
./opencore.sh
```
### Windows

```
git clone --branch windows https://github.com/itsmaclol/oc-efi-maker.git && cd oc-efi-maker
opencore.bat
```
## Flags
`-h`, `--help` - Prints the help page

`--ignore-internet-check ` - Ignores the internet check at the beginning of the script. Use this if you are 100% sure that you have internet.

`--ignore-dependencies` - Ignores the dependency check at the beginning of the script. Use this if you are 100% sure that you have the dependencies installed.

`--ignore-deps-internet-check` - Ignores both the internet and dependency check at the beginning of the script. Use this if you are 100% sure that you have the dependencies installed and have internet.

# Please Read!
This project was made for fun, and the EFI's that this script generates are only for testing purposes, if you want an actual stable hackintosh, please follow [the dortania guide](https://dortania.github.io/OpenCore-Install-Guide)

## Credits
[Apple](https://www.apple.com) for macOS

[Dortania](https://github.com/dortania) for [the OpenCore guide](https://dortania.github.io/OpenCore-Install-Guide)

[acidanthera](https://github.com/acidanthera) for OpenCore, WhateverGreen, AppleALC, IntelMausi etc...

[Corpnewt](https://github.com/corpnewt.com) For [OCSnapshot](https://github.com/corpnewt/OCSnapshot)

& more...

Made with <3 by [Mac](https://github.com/itsmaclol)
