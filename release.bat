@echo off
setlocal enabledelayedexpansion

echo ============================================
echo   Hoplixi Release Builder
echo ============================================
echo.
echo Choose platform for build:
echo   [1] Windows (EXE)
echo   [2] Android (APK)
echo   [3] Windows (MSIX)
echo   [Q] Quit
echo.

set /p choice="Enter your choice: "

if /i "%choice%"=="q" (
    echo Cancelled.
    goto :end
)

if "%choice%"=="1" (
    echo.
    echo [BUILD] Starting Windows EXE build...
    echo ----------------------------------------
    fastforge package --platform windows --targets exe
    if !errorlevel! neq 0 (
        echo [ERROR] Build failed with code !errorlevel!
        goto :error
    )
    echo [SUCCESS] Windows EXE build completed.
) else if "%choice%"=="2" (
    echo.
    echo [BUILD] Starting Android APK build...
    echo ----------------------------------------
    fastforge package --platform android --targets apk
    if !errorlevel! neq 0 (
        echo [ERROR] Build failed with code !errorlevel!
        goto :error
    )
    echo [SUCCESS] Android APK build completed.
) else if "%choice%"=="3" (
    echo.
    echo [BUILD] Starting Windows MSIX build...
    echo ----------------------------------------
    fastforge package --platform windows --targets msix
    if !errorlevel! neq 0 (
        echo [ERROR] Build failed with code !errorlevel!
        goto :error
    )
    echo [SUCCESS] Windows MSIX build completed.
) else (
    echo.
    echo [ERROR] Invalid choice '%choice%'. Please enter 1, 2, 3, or Q.
    goto :error
)

echo.
echo ============================================
echo   Build completed successfully!
echo ============================================
goto :end

:error
echo.
echo ============================================
echo   Build failed or cancelled.
echo ============================================
exit /b 1

:end
echo.
pause
exit /b 0


