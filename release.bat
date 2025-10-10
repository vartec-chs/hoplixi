@echo off

echo Choose platform for build:
echo 1. Windows
echo 2. Android

set /p choice="Enter number: "

if "%choice%"=="1" (
    echo Building for Windows...
    flutter build windows
) else (
    if "%choice%"=="2" (
        echo Building for Android...
        flutter build apk --release
    ) else (
        echo Invalid choice. Please try again.
        goto :eof
    )
)

echo Build completed.
pause


