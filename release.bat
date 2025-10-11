@echo off

echo Choose platform for build:
echo 1. Windows
echo 2. Android
echo 3. Windows MSIX

set /p choice="Enter number: "

if "%choice%"=="1" (
    echo Building for Windows...
    fastforge package --platform windows --targets exe
) else (
    if "%choice%"=="2" (
        echo Building for Android...
        fastforge package --platform android --targets apk
    ) else (
        if "%choice%"=="3" (
            echo Building for Windows MSIX...
            fastforge package --platform windows --targets msix
        ) else (
            echo Invalid choice. Please try again.
            goto :eof
    )
)

echo Build completed.
pause


