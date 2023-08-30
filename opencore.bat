@echo off
rem checks and other stuff
rem todo: add help screen, dependencies, and arguments
temp_dir=$(mktemp -d)
:check_dependencies
set_dependencies=(curl git python3 jq)

for%%d in %set_dependencies% do (
    if not exist %d (
        echo %d is not installed, please install it and run this tool again.
        exit /b 1
    )
)
:internet_check
ping -n 1 google.com >nul
:if %errorlevel% equ 0 (
) else (
    echo You do not seem to have an internet connection, please connect to the internet and try again, or if you are completely sure that you have internet, use the --ignore-internet-check flag.
    exit /b 1
)
if not "%os%"=="Windows_NT" goto not_windows
:: calmly steals code from riiconnect24 
set string1=Welcome to OpenCore EFI Maker! Now, we'll start by downloading some files.
rem intro
title OpenCore EFI Maker   Made with love by gumi and Mac <3
echo %string1%
rem colors here
rem error
:not_windows
cls
echo why the hell are you running this on MS-DOS this is only for windows silly
pause
exit
goto not_windows

