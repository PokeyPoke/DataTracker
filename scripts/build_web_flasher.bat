@echo off
REM Build script for generating web flasher binaries (Windows)
REM This script builds the firmware and prepares all necessary files for web-based flashing

echo ==========================================
echo ESP32-C3 Data Tracker - Web Flasher Build
echo ==========================================
echo.

REM Check if PlatformIO is installed
where pio >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: PlatformIO not found!
    echo Please install PlatformIO: pip install platformio
    exit /b 1
)

echo [OK] PlatformIO found

REM Check if we're in the right directory
if not exist "platformio.ini" (
    echo ERROR: platformio.ini not found!
    echo Please run this script from the DataTracker project root directory
    exit /b 1
)

echo [OK] Project directory verified
echo.

REM Clean previous build
echo Step 1/4: Cleaning previous build...
pio run --target clean >nul 2>&1
echo [OK] Clean complete
echo.

REM Build the firmware
echo Step 2/4: Building firmware...
echo (This may take a few minutes...)
pio run

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Build failed!
    exit /b 1
)

echo [OK] Build successful
echo.

REM Create firmware directory
echo Step 3/4: Preparing web flasher binaries...
if not exist "docs\firmware" mkdir docs\firmware

REM PlatformIO build output directory
set BUILD_DIR=.pio\build\esp32-c3-devkitm-1
set FIRMWARE_DIR=docs\firmware

REM Copy bootloader
if exist "%BUILD_DIR%\bootloader.bin" (
    copy /Y "%BUILD_DIR%\bootloader.bin" "%FIRMWARE_DIR%\" >nul
    echo [OK] Copied bootloader.bin
) else (
    echo WARNING: bootloader.bin not found in build directory
    REM Try to find in platform packages
    for /f "delims=" %%i in ('dir /s /b "%USERPROFILE%\.platformio\packages\framework-arduinoespressif32\*bootloader*.bin" 2^>nul ^| findstr /i "esp32c3" ^| findstr /v "bootloader_dio" ^| findstr /v "bootloader_qio"') do (
        copy /Y "%%i" "%FIRMWARE_DIR%\bootloader.bin" >nul
        echo [OK] Copied bootloader.bin from platform
        goto :bootloader_done
    )
    echo ERROR: Could not find bootloader.bin
    exit /b 1
)
:bootloader_done

REM Copy partitions
if exist "%BUILD_DIR%\partitions.bin" (
    copy /Y "%BUILD_DIR%\partitions.bin" "%FIRMWARE_DIR%\" >nul
    echo [OK] Copied partitions.bin
) else (
    echo ERROR: partitions.bin not found
    exit /b 1
)

REM Copy boot_app0
if exist "%BUILD_DIR%\boot_app0.bin" (
    copy /Y "%BUILD_DIR%\boot_app0.bin" "%FIRMWARE_DIR%\" >nul
    echo [OK] Copied boot_app0.bin
) else (
    echo WARNING: boot_app0.bin not found in build directory
    for /f "delims=" %%i in ('dir /s /b "%USERPROFILE%\.platformio\packages\framework-arduinoespressif32\boot_app0.bin" 2^>nul') do (
        copy /Y "%%i" "%FIRMWARE_DIR%\boot_app0.bin" >nul
        echo [OK] Copied boot_app0.bin from platform
        goto :boot_app0_done
    )
    echo ERROR: Could not find boot_app0.bin
    exit /b 1
)
:boot_app0_done

REM Copy main firmware
if exist "%BUILD_DIR%\firmware.bin" (
    copy /Y "%BUILD_DIR%\firmware.bin" "%FIRMWARE_DIR%\" >nul
    echo [OK] Copied firmware.bin
) else (
    echo ERROR: firmware.bin not found
    exit /b 1
)

REM Verify binaries
echo.
echo Step 4/4: Verifying binaries...
echo.
echo Binary sizes:
for %%F in ("%FIRMWARE_DIR%\bootloader.bin") do echo   bootloader.bin:  %%~zF bytes
for %%F in ("%FIRMWARE_DIR%\partitions.bin") do echo   partitions.bin:  %%~zF bytes
for %%F in ("%FIRMWARE_DIR%\boot_app0.bin") do echo   boot_app0.bin:   %%~zF bytes
for %%F in ("%FIRMWARE_DIR%\firmware.bin") do echo   firmware.bin:    %%~zF bytes
echo.

REM Create README in firmware directory
(
echo # Web Flasher Firmware Binaries
echo.
echo These binaries are used by the web-based flasher tool.
echo.
echo ## Files
echo.
echo - **bootloader.bin** ^(offset 0x0000^) - ESP32-C3 bootloader
echo - **partitions.bin** ^(offset 0x8000^) - Partition table
echo - **boot_app0.bin** ^(offset 0xe000^) - Boot application
echo - **firmware.bin** ^(offset 0x10000^) - Main application firmware
echo.
echo ## Flash Manually
echo.
echo If you want to flash manually using esptool:
echo.
echo ```bash
echo esptool.py --chip esp32c3 --port COM3 --baud 460800 \
echo   --before default_reset --after hard_reset write_flash -z \
echo   --flash_mode dio --flash_freq 80m --flash_size 4MB \
echo   0x0 bootloader.bin \
echo   0x8000 partitions.bin \
echo   0xe000 boot_app0.bin \
echo   0x10000 firmware.bin
echo ```
echo.
echo Replace `COM3` with your serial port.
echo.
echo ## Web Flasher
echo.
echo Instead of manual flashing, use the web-based flasher:
echo https://yourusername.github.io/DataTracker/flash.html
echo.
echo Just click and flash - no software installation required!
) > "%FIRMWARE_DIR%\README.md"

echo [OK] Created firmware README
echo.

REM Success message
echo ==========================================
echo SUCCESS!
echo ==========================================
echo.
echo Web flasher binaries are ready in: docs\firmware\
echo.
echo Next steps:
echo 1. Test the web flasher locally:
echo    cd docs
echo    python -m http.server 8000
echo    Open: http://localhost:8000/flash.html
echo.
echo 2. Or commit and push to GitHub Pages:
echo    git add docs/
echo    git commit -m "Add web flasher"
echo    git push
echo    Enable GitHub Pages in repo settings (source: docs folder^)
echo    Access at: https://yourusername.github.io/DataTracker/flash.html
echo.
echo ==========================================

pause
