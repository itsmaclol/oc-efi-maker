amdkernelpatches() {
    corecount() {
        echo "################################################################"
        echo "What is the Core Count of your processor?"
        echo "We're not referring to the Thread Count, we're referring to the Core Count."
        echo "1. 4 Cores"
        echo "2. 6 Cores"
        echo "3. 8 Cores"
        echo "4. 12 Cores"
        echo "5. 16 Cores"
        echo "6. 24 Cores"
        echo "7. 32 Cores"
        echo "################################################################"
        read -r -p "Pick a number 1-7: " core_count_choice
        case $core_count_choice in
            1 )
                core_count="04"
            ;;
            2 )
                core_count="06"
            ;;
            3 )
                core_count="08"
            ;;
            4 )
                core_count="0C"
            ;;
            5 )
                core_count="10"
            ;;
            6 )
                core_count="18"
            ;;
            7 )
                core_count="20"
            ;;
            * )
                error "Invalid choice."
                corecount
        esac
    }
    corecount
    case $os_choice in
        5 )
            corecountpatch="B8$core_count 0000 0000"
        ;;
        4|3 )
            corecountpatch="BA$core_count 0000 0000"
        ;;
        2 )
            corecountpatch="BA$core_count 0000 0000"
        ;;
        1 )
            corecountpatch="BA$core_count 0000 00"
        ;;
    esac
    info "Adding AMD Kernel patches to config.plist, this may take a while, please wait..."
    delete_plist Kernel.Patch
    add_plist Kernel.Patch array
    # First kernel patch
    add_plist Kernel.Patch.0 dict
    add_plist Kernel.Patch.0.Arch string
    set_plist Kernel.Patch.0.Arch string x86_64
    add_plist Kernel.Patch.0.Base string
    set_plist Kernel.Patch.0.Base string _cpuid_set_info
    add_plist Kernel.Patch.0.Comment string
    set_plist Kernel.Patch.0.Comment string "algrey | Force cpuid_cores_per_package to constant (user-specified) | 10.13-10.14"
    add_plist Kernel.Patch.0.Count int
    set_plist Kernel.Patch.0.Count int 1
    add_plist Kernel.Patch.0.Enabled bool
    set_plist Kernel.Patch.0.Enabled bool True
    add_plist Kernel.Patch.0.Find data
    set_plist Kernel.Patch.0.Find data "C1E81A00 0000"
    add_plist Kernel.Patch.0.Identifier string
    set_plist Kernel.Patch.0.Identifier string kernel
    add_plist Kernel.Patch.0.Limit int
    set_plist Kernel.Patch.0.Limit int 0
    add_plist Kernel.Patch.0.Mask data
    set_plist Kernel.Patch.0.Mask data "FFFDFF00 0000"
    add_plist Kernel.Patch.0.MaxKernel string
    set_plist Kernel.Patch.0.MaxKernel string 18.99.99
    add_plist Kernel.Patch.0.MinKernel string
    set_plist Kernel.Patch.0.MinKernel string 17.0.0
    add_plist Kernel.Patch.0.Replace data
    set_plist Kernel.Patch.0.Replace data "$corecountpatch"
    add_plist Kernel.Patch.0.ReplaceMask data
    set_plist Kernel.Patch.0.ReplaceMask data "FFFFFFFF FF00"
    add_plist Kernel.Patch.0.Skip int
    set_plist Kernel.Patch.0.Skip int 0
    # Second Kernel Patch
    add_plist Kernel.Patch.1 dict
    add_plist Kernel.Patch.1.Arch string
    set_plist Kernel.Patch.1.Arch string x86_64
    add_plist Kernel.Patch.1.Base string
    set_plist Kernel.Patch.1.Base string _cpuid_set_info
    add_plist Kernel.Patch.1.Comment string
    set_plist Kernel.Patch.1.Comment string "algrey | Force cpuid_cores_per_package to constant (user-specified) | 10.15-11.0"
    add_plist Kernel.Patch.1.Count int
    set_plist Kernel.Patch.1.Count int 1
    add_plist Kernel.Patch.1.Enabled bool
    set_plist Kernel.Patch.1.Enabled bool True
    add_plist Kernel.Patch.1.Find data
    set_plist Kernel.Patch.1.Find data "C1E81A00 0000"
    add_plist Kernel.Patch.1.Identifier string
    set_plist Kernel.Patch.1.Identifier string kernel
    add_plist Kernel.Patch.1.Limit int
    set_plist Kernel.Patch.1.Limit int 0
    add_plist Kernel.Patch.1.Mask data
    set_plist Kernel.Patch.1.Mask data "FFFDFF00 0000"
    add_plist Kernel.Patch.1.MaxKernel string
    set_plist Kernel.Patch.1.MaxKernel string 20.99.99
    add_plist Kernel.Patch.1.MinKernel string
    set_plist Kernel.Patch.1.MinKernel string 19.0.0
    add_plist Kernel.Patch.1.Replace data
    set_plist Kernel.Patch.1.Replace data "$corecountpatch"
    add_plist Kernel.Patch.1.ReplaceMask data
    set_plist Kernel.Patch.1.ReplaceMask data "FFFFFFFF FF00"
    add_plist Kernel.Patch.1.Skip int
    set_plist Kernel.Patch.1.Skip int 0
    # Third Kernel Patch
    add_plist Kernel.Patch.2 dict
    add_plist Kernel.Patch.2.Arch string
    set_plist Kernel.Patch.2.Arch string x86_64
    add_plist Kernel.Patch.2.Base string
    set_plist Kernel.Patch.2.Base string _cpuid_set_info
    add_plist Kernel.Patch.2.Comment string
    set_plist Kernel.Patch.2.Comment string "algrey | Force cpuid_cores_per_package to constant (user-specified) | 12.0-13.2"
    add_plist Kernel.Patch.2.Count int
    set_plist Kernel.Patch.2.Count int 1
    add_plist Kernel.Patch.2.Enabled bool
    set_plist Kernel.Patch.2.Enabled bool True
    add_plist Kernel.Patch.2.Find data
    set_plist Kernel.Patch.2.Find data "C1E81A00 0000"
    add_plist Kernel.Patch.2.Identifier string
    set_plist Kernel.Patch.2.Identifier string kernel
    add_plist Kernel.Patch.2.Limit int
    set_plist Kernel.Patch.2.Limit int 0
    add_plist Kernel.Patch.2.Mask data
    set_plist Kernel.Patch.2.Mask data "FFFDFF00 0000"
    add_plist Kernel.Patch.2.MaxKernel string
    set_plist Kernel.Patch.2.MaxKernel string 22.3.99
    add_plist Kernel.Patch.2.MinKernel string
    set_plist Kernel.Patch.2.MinKernel string 21.0.0
    add_plist Kernel.Patch.2.Replace data
    set_plist Kernel.Patch.2.Replace data "$corecountpatch"
    add_plist Kernel.Patch.2.ReplaceMask data
    add_plist Kernel.Patch.2.Skip int
    set_plist Kernel.Patch.2.Skip int 0
    # Fourth Kernel Patch
    add_plist Kernel.Patch.3 dict
    add_plist Kernel.Patch.3.Arch string
    set_plist Kernel.Patch.3.Arch string x86_64
    add_plist Kernel.Patch.3.Base string
    set_plist Kernel.Patch.3.Base string _cpuid_set_info
    add_plist Kernel.Patch.3.Comment string
    set_plist Kernel.Patch.3.Comment string "algrey | Force cpuid_cores_per_package to constant (user-specified) | 13.3+"
    add_plist Kernel.Patch.3.Count int
    set_plist Kernel.Patch.3.Count int 1
    add_plist Kernel.Patch.3.Enabled bool
    set_plist Kernel.Patch.3.Enabled bool True
    add_plist Kernel.Patch.3.Find data
    set_plist Kernel.Patch.3.Find data "C1E81A00 00"
    add_plist Kernel.Patch.3.Identifier string
    set_plist Kernel.Patch.3.Identifier string kernel
    add_plist Kernel.Patch.3.Limit int
    set_plist Kernel.Patch.3.Limit int 0
    add_plist Kernel.Patch.3.Mask data
    set_plist Kernel.Patch.3.Mask data "FFFDFF00 00"
    add_plist Kernel.Patch.3.MaxKernel string
    set_plist Kernel.Patch.3.MaxKernel string 23.99.99
    add_plist Kernel.Patch.3.MinKernel string
    set_plist Kernel.Patch.3.MinKernel string 22.4.0
    add_plist Kernel.Patch.3.Replace data
    set_plist Kernel.Patch.3.Replace data "$corecountpatch"
    add_plist Kernel.Patch.3.ReplaceMask data
    set_plist Kernel.Patch.3.ReplaceMask data "FFFFFFFF FF"
    add_plist Kernel.Patch.3.Skip int
    set_plist Kernel.Patch.3.Skip int 0
    # Fifth Kernel Patch
    add_plist Kernel.Patch.4 dict
    add_plist Kernel.Patch.4.Arch string
    set_plist Kernel.Patch.4.Arch string x86_64
    add_plist Kernel.Patch.4.Base string
    add_plist Kernel.Patch.4.Comment string
    set_plist Kernel.Patch.4.Comment string "algrey | _commpage_populate | Remove rdmsr | 10.13+0"
    add_plist Kernel.Patch.4.Count int
    set_plist Kernel.Patch.4.Count int 1
    add_plist Kernel.Patch.4.Enabled bool
    set_plist Kernel.Patch.4.Enabled bool True
    add_plist Kernel.Patch.4.Find data
    set_plist Kernel.Patch.4.Find data "B9A00100 000F32"
    add_plist Kernel.Patch.4.Identifier string
    set_plist Kernel.Patch.4.Identifier string kernel
    add_plist Kernel.Patch.4.Limit int
    set_plist Kernel.Patch.4.Limit int 0
    add_plist Kernel.Patch.4.Mask data
    add_plist Kernel.Patch.4.MaxKernel string
    set_plist Kernel.Patch.4.MaxKernel string 23.99.99
    add_plist Kernel.Patch.4.MinKernel string
    set_plist Kernel.Patch.4.MinKernel string 17.0.0
    add_plist Kernel.Patch.4.Replace data
    set_plist Kernel.Patch.4.Replace data "66906690 669090"
    add_plist Kernel.Patch.4.ReplaceMask data
    add_plist Kernel.Patch.4.Skip int
    set_plist Kernel.Patch.4.Skip int 0
    # Sixth Kernel Patch
    add_plist Kernel.Patch.5 dict
    add_plist Kernel.Patch.5.Arch string
    set_plist Kernel.Patch.5.Arch string x86_64
    add_plist Kernel.Patch.5.Base string
    add_plist Kernel.Patch.5.Comment string
    set_plist Kernel.Patch.5.Comment string "algrey | _cpuid_set_cache_info | Set CPUID proper instead of 4 | 10.13+"
    add_plist Kernel.Patch.5.Count int
    set_plist Kernel.Patch.5.Count int 1
    add_plist Kernel.Patch.5.Enabled bool
    set_plist Kernel.Patch.5.Enabled bool True
    add_plist Kernel.Patch.5.Find data
    set_plist Kernel.Patch.5.Find data "B8040000 004489F1 4489"
    add_plist Kernel.Patch.5.Identifier string
    set_plist Kernel.Patch.5.Identifier string kernel
    add_plist Kernel.Patch.5.Limit int
    set_plist Kernel.Patch.5.Limit int 0
    add_plist Kernel.Patch.5.Mask data
    add_plist Kernel.Patch.5.MaxKernel string
    set_plist Kernel.Patch.5.MaxKernel string 23.99.99
    add_plist Kernel.Patch.5.MinKernel string
    set_plist Kernel.Patch.5.MinKernel string 17.0.0
    add_plist Kernel.Patch.5.Replace data
    set_plist Kernel.Patch.5.Replace data "B81D0000 804489F1 4489"
    add_plist Kernel.Patch.5.ReplaceMask data
    add_plist Kernel.Patch.5.Skip int
    set_plist Kernel.Patch.5.Skip int 0
    # Seventh Kernel Patch
    add_plist Kernel.Patch.6 dict
    add_plist Kernel.Patch.6.Arch string
    set_plist Kernel.Patch.6.Arch string x86_64
    add_plist Kernel.Patch.6.Base string
    add_plist Kernel.Patch.6.Comment string
    set_plist Kernel.Patch.6.Comment string "algrey | _cpuid_set_generic_info | Remove wrmsr(0x8B) | 10.13+"
    add_plist Kernel.Patch.6.Count int
    set_plist Kernel.Patch.6.Count int 1
    add_plist Kernel.Patch.6.Enabled bool
    set_plist Kernel.Patch.6.Enabled bool True
    add_plist Kernel.Patch.6.Find data
    set_plist Kernel.Patch.6.Find data "B98B0000 0031C031 D20F30"
    add_plist Kernel.Patch.6.Identifier string
    set_plist Kernel.Patch.6.Identifier string kernel
    add_plist Kernel.Patch.6.Limit int
    set_plist Kernel.Patch.6.Limit int 0
    add_plist Kernel.Patch.6.Mask data
    add_plist Kernel.Patch.6.MaxKernel string
    set_plist Kernel.Patch.6.MaxKernel string 23.99.99
    add_plist Kernel.Patch.6.MinKernel string
    set_plist Kernel.Patch.6.MinKernel string 17.0.0
    add_plist Kernel.Patch.6.Replace data
    set_plist Kernel.Patch.6.Replace data "66906690 66906690 669090"
    add_plist Kernel.Patch.6.ReplaceMask data
    add_plist Kernel.Patch.6.Skip int
    set_plist Kernel.Patch.6.Skip int 0
    # Eighth Kernel Patch
    add_plist Kernel.Patch.7 dict
    add_plist Kernel.Patch.7.Arch string
    set_plist Kernel.Patch.7.Arch string x86_64
    add_plist Kernel.Patch.7.Base string
    add_plist Kernel.Patch.7.Comment string
    set_plist Kernel.Patch.7.Comment string "algrey | _cpuid_set_generic_info | Replace rdmsr(0x8B) with constant 186 | 10.13+"
    add_plist Kernel.Patch.7.Count int
    set_plist Kernel.Patch.7.Count int 1
    add_plist Kernel.Patch.7.Enabled bool
    set_plist Kernel.Patch.7.Enabled bool True
    add_plist Kernel.Patch.7.Find data
    set_plist Kernel.Patch.7.Find data "B98B0000 000F32"
    add_plist Kernel.Patch.7.Identifier string
    set_plist Kernel.Patch.7.Identifier string kernel
    add_plist Kernel.Patch.7.Limit int
    set_plist Kernel.Patch.7.Limit int 0
    add_plist Kernel.Patch.7.Mask data
    add_plist Kernel.Patch.7.MaxKernel string
    set_plist Kernel.Patch.7.MaxKernel string 23.99.99
    add_plist Kernel.Patch.7.MinKernel string
    set_plist Kernel.Patch.7.MinKernel string 17.0.0
    add_plist Kernel.Patch.7.Replace data
    set_plist Kernel.Patch.7.Replace data "BABA0000 006690"
    add_plist Kernel.Patch.7.ReplaceMask data
    add_plist Kernel.Patch.7.Skip int
    set_plist Kernel.Patch.7.Skip int 0
    # Ninth Kernel Patch
    add_plist Kernel.Patch.8 dict
    add_plist Kernel.Patch.8.Arch string
    set_plist Kernel.Patch.8.Arch string x86_64
    add_plist Kernel.Patch.8.Base string
    add_plist Kernel.Patch.8.Comment string
    set_plist Kernel.Patch.8.Comment string "algrey | _cpuid_set_generic_info | Set flag=1 | 10.13+"
    add_plist Kernel.Patch.8.Count int
    set_plist Kernel.Patch.8.Count int 1
    add_plist Kernel.Patch.8.Enabled bool
    set_plist Kernel.Patch.8.Enabled bool True
    add_plist Kernel.Patch.8.Find data
    set_plist Kernel.Patch.8.Find data "B9170000 000F32C1 EA1280E2 07"
    add_plist Kernel.Patch.8.Identifier string
    set_plist Kernel.Patch.8.Identifier string kernel
    add_plist Kernel.Patch.8.Limit int
    set_plist Kernel.Patch.8.Limit int 0
    add_plist Kernel.Patch.8.Mask data
    add_plist Kernel.Patch.8.MaxKernel string
    set_plist Kernel.Patch.8.MaxKernel string 23.99.99
    add_plist Kernel.Patch.8.MinKernel string
    set_plist Kernel.Patch.8.MinKernel string 17.0.0
    add_plist Kernel.Patch.8.Replace data
    set_plist Kernel.Patch.8.Replace data "B201660F 1F840000 00000066 90"
    add_plist Kernel.Patch.8.ReplaceMask data
    add_plist Kernel.Patch.8.Skip int
    set_plist Kernel.Patch.8.Skip int 0
    # Tenth Kernel Patch
    add_plist Kernel.Patch.9 dict
    add_plist Kernel.Patch.9.Arch string
    set_plist Kernel.Patch.9.Arch string x86_64
    add_plist Kernel.Patch.9.Base string
    add_plist Kernel.Patch.9.Comment string
    set_plist Kernel.Patch.9.Comment string "algrey | _cpuid_set_generic_info | Disable check to allow leaf7 | 10.13+"
    add_plist Kernel.Patch.9.Count int
    set_plist Kernel.Patch.9.Count int 1
    add_plist Kernel.Patch.9.Enabled bool
    set_plist Kernel.Patch.9.Enabled bool True
    add_plist Kernel.Patch.9.Find data
    set_plist Kernel.Patch.9.Find data "003A0F82"
    add_plist Kernel.Patch.9.Identifier string
    set_plist Kernel.Patch.9.Identifier string kernel
    add_plist Kernel.Patch.9.Limit int
    set_plist Kernel.Patch.9.Limit int 0
    add_plist Kernel.Patch.9.Mask data
    add_plist Kernel.Patch.9.MaxKernel string
    set_plist Kernel.Patch.9.MaxKernel string 23.99.99
    add_plist Kernel.Patch.9.MinKernel string
    set_plist Kernel.Patch.9.MinKernel string 17.0.0
    add_plist Kernel.Patch.9.Replace data
    set_plist Kernel.Patch.9.Replace data "00000F82"
    add_plist Kernel.Patch.9.ReplaceMask data
    add_plist Kernel.Patch.9.Skip int
    set_plist Kernel.Patch.9.Skip int 0
    # Eleventh Kernel Patch
    add_plist Kernel.Patch.10 dict
    add_plist Kernel.Patch.10.Arch string
    set_plist Kernel.Patch.10.Arch string x86_64
    add_plist Kernel.Patch.10.Base string
    add_plist Kernel.Patch.10.Comment string
    set_plist Kernel.Patch.10.Comment string "algrey | _cpuid_set_info | GenuineIntel to AuthenticAMD | 10.13-11.0"    add_plist Kernel.Patch.10.Count int
    add_plist Kernel.Patch.10.Count int
    set_plist Kernel.Patch.10.Count int 1
    add_plist Kernel.Patch.10.Enabled bool
    set_plist Kernel.Patch.10.Enabled bool True
    add_plist Kernel.Patch.10.Find data
    set_plist Kernel.Patch.10.Find data "47656E75 696E6549 6E74656C 00"
    add_plist Kernel.Patch.10.Identifier string
    set_plist Kernel.Patch.10.Identifier string kernel
    add_plist Kernel.Patch.10.Limit int
    set_plist Kernel.Patch.10.Limit int 0
    add_plist Kernel.Patch.10.Mask data
    add_plist Kernel.Patch.10.MaxKernel string
    set_plist Kernel.Patch.10.MaxKernel string 20.99.99
    add_plist Kernel.Patch.10.MinKernel string
    set_plist Kernel.Patch.10.MinKernel string 17.0.0
    add_plist Kernel.Patch.10.Replace data
    set_plist Kernel.Patch.10.Replace data "41757468 656E7469 63414D44 00"
    add_plist Kernel.Patch.10.ReplaceMask data
    add_plist Kernel.Patch.10.Skip int
    set_plist Kernel.Patch.10.Skip int 0
    # Twelfth Kernel Patch
    add_plist Kernel.Patch.11 dict
    add_plist Kernel.Patch.11.Arch string
    set_plist Kernel.Patch.11.Arch string x86_64
    add_plist Kernel.Patch.11.Base string
    set_plist Kernel.Patch.11.Base string _cpuid_set_info
    add_plist Kernel.Patch.11.Comment string
    set_plist Kernel.Patch.11.Comment string "Goldfish64, algrey | Bypass GenuineIntel check panic | 12.0+"
    add_plist Kernel.Patch.11.Count int
    set_plist Kernel.Patch.11.Count int 1
    add_plist Kernel.Patch.11.Enabled bool
    set_plist Kernel.Patch.11.Enabled bool True
    add_plist Kernel.Patch.11.Find data
    set_plist Kernel.Patch.11.Find data "00000000 000031D2 B301"
    add_plist Kernel.Patch.11.Identifier string
    set_plist Kernel.Patch.11.Identifier string kernel
    add_plist Kernel.Patch.11.Limit int
    set_plist Kernel.Patch.11.Limit int 0
    add_plist Kernel.Patch.11.Mask data
    set_plist Kernel.Patch.11.Mask data "00000000 0000FFFF FFFF"
    add_plist Kernel.Patch.11.MaxKernel string
    set_plist Kernel.Patch.11.MaxKernel string 23.99.99
    add_plist Kernel.Patch.11.MinKernel string
    set_plist Kernel.Patch.11.MinKernel string 21.0.0
    add_plist Kernel.Patch.11.Replace data
    set_plist Kernel.Patch.11.Replace data "90909090 909031D2 B301"
    add_plist Kernel.Patch.11.ReplaceMask data
    add_plist Kernel.Patch.11.Skip int
    set_plist Kernel.Patch.11.Skip int 0
    # Thirteenth Kernel Patch
    add_plist Kernel.Patch.12 dict
    add_plist Kernel.Patch.12.Arch string
    set_plist Kernel.Patch.12.Arch string x86_64
    add_plist Kernel.Patch.12.Base string
    add_plist Kernel.Patch.12.Comment string
    set_plist Kernel.Patch.12.Comment string "algrey | _cpuid_set_cpufamily | Force CPUFAMILY_INTEL_PENRYN | 10.13-11.2"
    add_plist Kernel.Patch.12.Count int
    set_plist Kernel.Patch.12.Count int 1
    add_plist Kernel.Patch.12.Enabled bool
    set_plist Kernel.Patch.12.Enabled bool True
    add_plist Kernel.Patch.12.Find data
    set_plist Kernel.Patch.12.Find data "31DB803D 00000000 067500"
    add_plist Kernel.Patch.12.Identifier string
    set_plist Kernel.Patch.12.Identifier string kernel
    add_plist Kernel.Patch.12.Limit int
    set_plist Kernel.Patch.12.Limit int 0
    add_plist Kernel.Patch.12.Mask data
    set_plist Kernel.Patch.12.Mask data "FFFFFFFF 000000FF FFFF00"
    add_plist Kernel.Patch.12.MaxKernel string
    set_plist Kernel.Patch.12.MaxKernel string 20.3.0
    add_plist Kernel.Patch.12.MinKernel string 17.0.0
    add_plist Kernel.Patch.12.Replace data
    set_plist Kernel.Patch.12.Replace data "BBBC4FEA 78E95D00 000090"
    add_plist Kernel.Patch.12.ReplaceMask data
    add_plist Kernel.Patch.12.Skip int
    set_plist Kernel.Patch.12.Skip int 0
    # Fourteenth Kernel Patch
    add_plist Kernel.Patch.13 dict
    add_plist Kernel.Patch.13.Arch string
    set_plist Kernel.Patch.13.Arch string x86_64
    add_plist Kernel.Patch.13.Base string
    set_plist Kernel.Patch.13.Base string _cpuid_set_info 
    add_plist Kernel.Patch.13.Comment string
    set_plist Kernel.Patch.13.Comment string "algrey | _cpuid_set_cpufamily | Force CPUFAMILY_INTEL_PENRYN | 11.3+"
    add_plist Kernel.Patch.13.Count int
    set_plist Kernel.Patch.13.Count int 1
    add_plist Kernel.Patch.13.Enabled bool
    set_plist Kernel.Patch.13.Enabled bool True
    add_plist Kernel.Patch.13.Find data
    set_plist Kernel.Patch.13.Find data "803D0000 00000675"
    add_plist Kernel.Patch.13.Identifier string
    set_plist Kernel.Patch.13.Identifier string kernel
    add_plist Kernel.Patch.13.Limit int
    set_plist Kernel.Patch.13.Limit int 0
    add_plist Kernel.Patch.13.Mask data
    set_plist Kernel.Patch.13.Mask data "FFFF0000 0000FFFF"
    add_plist Kernel.Patch.13.MaxKernel string
    set_plist Kernel.Patch.13.MaxKernel string 23.99.99
    add_plist Kernel.Patch.13.MinKernel string 20.4.0
    add_plist Kernel.Patch.13.Replace data
    set_plist Kernel.Patch.13.Replace data "BABC4FEA 7831DBEB"
    add_plist Kernel.Patch.13.ReplaceMask data
    add_plist Kernel.Patch.13.Skip int
    set_plist Kernel.Patch.13.Skip int 0
    # Fifteenth Kernel Patch
    add_plist Kernel.Patch.14 dict
    add_plist Kernel.Patch.14.Arch string
    set_plist Kernel.Patch.14.Arch string x86_64
    add_plist Kernel.Patch.14.Base string
    add_plist Kernel.Patch.14.Comment string
    set_plist Kernel.Patch.14.Comment string "algrey | _i386_init | Remove 3 rdmsr calls | 10.13+"
    add_plist Kernel.Patch.14.Count int
    set_plist Kernel.Patch.14.Count int 0
    add_plist Kernel.Patch.14.Enabled bool
    set_plist Kernel.Patch.14.Enabled bool True
    add_plist Kernel.Patch.14.Find data
    set_plist Kernel.Patch.14.Find data "B9990100 000F3248 C1E22089 C64809D6 B9980100 000F3248 C1E22089 C04809C2 BF580231 0531C945 31C0"
    add_plist Kernel.Patch.14.Identifier string
    set_plist Kernel.Patch.14.Identifier string kernel
    add_plist Kernel.Patch.14.Limit int
    set_plist Kernel.Patch.14.Limit int 0
    add_plist Kernel.Patch.14.Mask data
    add_plist Kernel.Patch.14.MaxKernel string
    set_plist Kernel.Patch.14.MaxKernel string 23.99.99
    add_plist Kernel.Patch.14.MinKernel string 17.0.0
    add_plist Kernel.Patch.14.Replace data
    set_plist Kernel.Patch.14.Replace data "660F1F84 00000000 00660F1F 84000000 0000660F 1F840000 00000066 0F1F8400 00000000 660F1F44 0000"
    add_plist Kernel.Patch.14.ReplaceMask data
    add_plist Kernel.Patch.14.Skip int
    set_plist Kernel.Patch.14.Skip int 0
    # Sixteenth Kernel Patch
    add_plist Kernel.Patch.15 dict
    add_plist Kernel.Patch.15.Arch string
    set_plist Kernel.Patch.15.Arch string x86_64
    add_plist Kernel.Patch.15.Base string
    add_plist Kernel.Patch.15.Comment string
    set_plist Kernel.Patch.15.Comment string "algrey, XLNC | Remove version check and panic | 10.13+"
    add_plist Kernel.Patch.15.Count int
    set_plist Kernel.Patch.15.Count int 1
    add_plist Kernel.Patch.15.Enabled bool
    set_plist Kernel.Patch.15.Enabled bool True
    add_plist Kernel.Patch.15.Find data
    set_plist Kernel.Patch.15.Find data "25FC0000 0083F813"
    add_plist Kernel.Patch.15.Identifier string
    set_plist Kernel.Patch.15.Identifier string kernel
    add_plist Kernel.Patch.15.Limit int
    set_plist Kernel.Patch.15.Limit int 0
    add_plist Kernel.Patch.15.Mask data
    add_plist Kernel.Patch.15.MaxKernel string    
    set_plist Kernel.Patch.15.MaxKernel string 23.99.99
    add_plist Kernel.Patch.15.MinKernel string
    set_plist Kernel.Patch.15.MinKernel string 17.0.0
    add_plist Kernel.Patch.15.Replace data
    set_plist Kernel.Patch.15.Replace data "25FC0000 000F1F00"
    add_plist Kernel.Patch.15.ReplaceMask data
    add_plist Kernel.Patch.15.Skip int
    set_plist Kernel.Patch.15.Skip int 0
    # Seventeenth Kernel Patch
    add_plist Kernel.Patch.16 dict
    add_plist Kernel.Patch.16.Arch string
    set_plist Kernel.Patch.16.Arch string x86_64
    add_plist Kernel.Patch.16.Base string
    set_plist Kernel.Patch.16.Base string __ZN11IOPCIBridge13probeBusGatedEP14probeBusParams
    add_plist Kernel.Patch.16.Comment string
    set_plist Kernel.Patch.16.Comment string "CaseySJ | probeBusGated | Disable 10 bit tags | 12.0+"
    add_plist Kernel.Patch.16.Count int
    set_plist Kernel.Patch.16.Count int 1
    add_plist Kernel.Patch.16.Enabled bool
    set_plist Kernel.Patch.16.Enabled bool True
    add_plist Kernel.Patch.16.Find data
    set_plist Kernel.Patch.16.Find data "E0117200"
    add_plist Kernel.Patch.16.Identifier string
    set_plist Kernel.Patch.16.Identifier string com.apple.iokit.IOPCIFamily
    add_plist Kernel.Patch.16.Limit int
    set_plist Kernel.Patch.16.Limit int 0
    add_plist Kernel.Patch.16.Mask data
    set_plist Kernel.Patch.16.Mask data "F0FFFFF0"
    add_plist Kernel.Patch.16.MaxKernel string
    set_plist Kernel.Patch.16.MaxKernel string 23.99.99
    add_plist Kernel.Patch.16.MinKernel string
    set_plist Kernel.Patch.16.MinKernel string 21.0.0
    add_plist Kernel.Patch.16.Replace data
    set_plist Kernel.Patch.16.Replace data "00000300"
    add_plist Kernel.Patch.16.ReplaceMask data
    add_plist Kernel.Patch.16.Skip int
    set_plist Kernel.Patch.16.Skip int 0
    # Eighteenth Kernel Patch
    add_plist Kernel.Patch.17 dict
    add_plist Kernel.Patch.17.Arch string
    set_plist Kernel.Patch.17.Arch string x86_64
    add_plist Kernel.Patch.17.Base string
    set_plist Kernel.Patch.17.Base string __ZN17IOPCIConfigurator18IOPCIIsHotplugPortEP16IOPCIConfigEntry
    add_plist Kernel.Patch.17.Comment string
    set_plist Kernel.Patch.17.Comment string "CaseySJ | IOPCIIsHotplugPort | Fix PCI bus enumeration on AM5 | 13.0+"
    add_plist Kernel.Patch.17.Count int
    set_plist Kernel.Patch.17.Count int 1
    add_plist Kernel.Patch.17.Enabled bool
    set_plist Kernel.Patch.17.Enabled bool False
    add_plist Kernel.Patch.17.Find data
    set_plist Kernel.Patch.17.Find data "8400754B"
    add_plist Kernel.Patch.17.Identifier string
    set_plist Kernel.Patch.17.Identifier string com.apple.iokit.IOPCIFamily
    add_plist Kernel.Patch.17.Limit int
    set_plist Kernel.Patch.17.Limit int 0
    add_plist Kernel.Patch.17.Mask data
    set_plist Kernel.Patch.17.Mask data FF00FFFF
    add_plist Kernel.Patch.17.MaxKernel string
    set_plist Kernel.Patch.17.MaxKernel string 23.99.99
    add_plist Kernel.Patch.17.MinKernel string
    set_plist Kernel.Patch.17.MinKernel string 22.0.0
    add_plist Kernel.Patch.17.Replace data
    set_plist Kernel.Patch.17.Replace data "0000EB00"
    add_plist Kernel.Patch.17.ReplaceMask data
    set_plist Kernel.Patch.17.ReplaceMask data "0000FF00"
    add_plist Kernel.Patch.17.Skip int
    set_plist Kernel.Patch.17.Skip int 0
    # Nineteenth Kernel Patch
    add_plist Kernel.Patch.18 dict
    add_plist Kernel.Patch.18.Arch string
    set_plist Kernel.Patch.18.Arch string x86_64
    add_plist Kernel.Patch.18.Base string
    add_plist Kernel.Patch.18.Comment string
    set_plist Kernel.Patch.18.Comment string "Visual | thread_quantum_expire, thread_unblock, thread_invoke | Remove non-monotonic time panic | 12.0+"
    add_plist Kernel.Patch.18.Count int
    set_plist Kernel.Patch.18.Count int 3
    add_plist Kernel.Patch.18.Enabled bool
    set_plist Kernel.Patch.18.Enabled bool True
    add_plist Kernel.Patch.18.Find data
    set_plist Kernel.Patch.18.Find data "48000000 02000048 00005800 00000F00 00000000"
    add_plist Kernel.Patch.18.Identifier string
    set_plist Kernel.Patch.18.Identifier string kernel
    add_plist Kernel.Patch.18.Limit int
    set_plist Kernel.Patch.18.Limit int 0
    add_plist Kernel.Patch.18.Mask data
    set_plist Kernel.Patch.18.Mask data "FF00000F FFFFFFFF 0000FF00 0000FF00 00000000"
    add_plist Kernel.Patch.18.MaxKernel string
    set_plist Kernel.Patch.18.MaxKernel string 23.99.99
    add_plist Kernel.Patch.18.MinKernel string
    set_plist Kernel.Patch.18.MinKernel string 21.0.0
    add_plist Kernel.Patch.18.Replace data
    set_plist Kernel.Patch.18.Replace data "00000000 00000000 00000000 00006690 66906690"
    add_plist Kernel.Patch.18.ReplaceMask data
    set_plist Kernel.Patch.18.ReplaceMask data "00000000 00000000 00000000 0000FFFF FFFFFFFF"
    add_plist Kernel.Patch.18.Skip int
    set_plist Kernel.Patch.18.Skip int 0
    # Twentieth Kernel Patch
    add_plist Kernel.Patch.19 dict
    add_plist Kernel.Patch.19.Arch string
    set_plist Kernel.Patch.19.Arch string x86_64
    add_plist Kernel.Patch.19.Base string
    add_plist Kernel.Patch.19.Comment string
    set_plist Kernel.Patch.19.Comment string "Visual | thread_invoke, thread_dispatch | Remove non-monotonic time panic | 12.0+"
    add_plist Kernel.Patch.19.Count int
    set_plist Kernel.Patch.19.Count int 2
    add_plist Kernel.Patch.19.Enabled bool
    set_plist Kernel.Patch.19.Enabled bool True
    add_plist Kernel.Patch.19.Find data
    set_plist Kernel.Patch.19.Find data "48000080 0400000F 00000000 00"
    add_plist Kernel.Patch.19.Identifier string
    set_plist Kernel.Patch.19.Identifier string kernel
    add_plist Kernel.Patch.19.Limit int
    set_plist Kernel.Patch.19.Limit int 0
    add_plist Kernel.Patch.19.Mask data
    set_plist Kernel.Patch.19.Mask data "480000F0 FFFFFFFF 00000000 00"
    add_plist Kernel.Patch.19.MaxKernel string
    set_plist Kernel.Patch.19.MaxKernel string 23.99.99
    add_plist Kernel.Patch.19.MinKernel string
    set_plist Kernel.Patch.19.MinKernel string 21.0.0
    add_plist Kernel.Patch.19.Replace data
    set_plist Kernel.Patch.19.Replace data "00000000 00000066 90669066 90"
    add_plist Kernel.Patch.19.ReplaceMask data
    set_plist Kernel.Patch.19.ReplaceMask data "00000000 000000FF FFFFFFFF FF"
    add_plist Kernel.Patch.19.Skip int
    set_plist Kernel.Patch.19.Skip int 0
    # Twenty-First Kernel Patch
    add_plist Kernel.Patch.20 dict
    add_plist Kernel.Patch.20.Arch string
    set_plist Kernel.Patch.20.Arch string x86_64
    add_plist Kernel.Patch.20.Base string
    add_plist Kernel.Patch.20.Comment string
    set_plist Kernel.Patch.20.Comment string "algrey | _mtrr_update_action | fix PAT | 10.13+"
    add_plist Kernel.Patch.20.Count int
    set_plist Kernel.Patch.20.Count int 0
    add_plist Kernel.Patch.20.Enabled bool
    set_plist Kernel.Patch.20.Enabled bool True
    add_plist Kernel.Patch.20.Find data
    set_plist Kernel.Patch.20.Find data "89C081E2 FFFF00FF 81CA0000 0100B977 020000"
    add_plist Kernel.Patch.20.Identifier string
    set_plist Kernel.Patch.20.Identifier string kernel
    add_plist Kernel.Patch.20.Limit int
    set_plist Kernel.Patch.20.Limit int 0
    add_plist Kernel.Patch.20.Mask data
    set_plist Kernel.Patch.20.Mask data "FFFFFFFF FFFF0FFF FFFFFFFF FFFFFFFF FFFFFF"
    add_plist Kernel.Patch.20.MaxKernel string
    set_plist Kernel.Patch.20.MaxKernel string 23.99.99
    add_plist Kernel.Patch.20.MinKernel string
    set_plist Kernel.Patch.20.MinKernel string 17.0.0
    add_plist Kernel.Patch.20.Replace data
    set_plist Kernel.Patch.20.Replace data "B9770200 00B80601 0700BA06 0107000F 1F4000"
    add_plist Kernel.Patch.20.ReplaceMask data
    add_plist Kernel.Patch.20.Skip int
    set_plist Kernel.Patch.20.Skip int 0
    # Twenty-Second Kernel Patch
    add_plist Kernel.Patch.21 dict
    add_plist Kernel.Patch.21.Arch string
    set_plist Kernel.Patch.21.Arch string x86_64
    add_plist Kernel.Patch.21.Base string
    add_plist Kernel.Patch.21.Comment string
    set_plist Kernel.Patch.21.Comment string "Shaneee | _mtrr_update_action | Fix PAT | 10.13+"
    add_plist Kernel.Patch.21.Count int
    set_plist Kernel.Patch.21.Count int 0
    add_plist Kernel.Patch.21.Enabled bool
    set_plist Kernel.Patch.21.Enabled bool False
    add_plist Kernel.Patch.21.Find data
    set_plist Kernel.Patch.21.Find data "89C081E2 FFFF00FF 81CA0000 0100B977 020000"
    add_plist Kernel.Patch.21.Identifier string
    set_plist Kernel.Patch.21.Identifier string kernel
    add_plist Kernel.Patch.21.Limit int
    set_plist Kernel.Patch.21.Limit int 0
    add_plist Kernel.Patch.21.Mask data
    set_plist Kernel.Patch.21.Mask data "FFFFFFFF FFFF0FFF FFFFFFFF FFFFFFFF FFFFFF"
    add_plist Kernel.Patch.21.MaxKernel string
    set_plist Kernel.Patch.21.MaxKernel string 23.99.99
    add_plist Kernel.Patch.21.MinKernel string
    set_plist Kernel.Patch.21.MinKernel string 17.0.0
    add_plist Kernel.Patch.21.Replace data
    set_plist Kernel.Patch.21.Replace data "B9770200 00B80606 0606BA06 0606060F 300F09"
    add_plist Kernel.Patch.21.ReplaceMask data
    add_plist Kernel.Patch.21.Skip int
    set_plist Kernel.Patch.21.Skip int 0
}