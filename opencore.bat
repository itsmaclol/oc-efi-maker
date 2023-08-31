@echo off
:: checks and other stuff
:: todo: add help screen, dependencies, and arguments
set "temp_dir=%temp%\tempdir"

:check_dependencies
set "set_dependencies=curl git python3 jq"

for %%d in (%set_dependencies%) do (
    where /q %%d || (
        echo %%d is not installed, please install it and run this tool again.
        exit /b 1
    )
)

:internet_check
ping -n 1 google.com >nul
if %errorlevel% equ 0 (
    goto :continue
) else (
    echo You do not seem to have an internet connection, please connect to the internet and try again, or if you are completely sure that you have internet, use the --ignore-internet-check flag.
    exit /b 1
)

:continue
if not "%os%"=="Windows_NT" goto not_windows

:: calmly steals code from riiconnect24
set "string1=Welcome to OpenCore EFI Maker! Now, we'll start by downloading some files."
set "string2="

:: intro
title OpenCore EFI Maker  Made with love by gumi and Mac ^<3
echo %string1%

:: colors here
:: me when i have no clue what the fuck im doing
:: errors
goto :EOF

:not_windows
cls
echo why the hell are you running this on MS-DOS this is only for windows silly
pause
exit