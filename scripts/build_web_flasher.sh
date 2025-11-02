#!/bin/bash
# Build script for generating web flasher binaries
# This script builds the firmware and prepares all necessary files for web-based flashing

set -e  # Exit on error

echo "=========================================="
echo "ESP32-C3 Data Tracker - Web Flasher Build"
echo "=========================================="
echo ""

# Check if PlatformIO is installed
if ! command -v pio &> /dev/null; then
    echo "❌ ERROR: PlatformIO not found!"
    echo "Please install PlatformIO: pip install platformio"
    exit 1
fi

echo "✓ PlatformIO found"

# Check if we're in the right directory
if [ ! -f "platformio.ini" ]; then
    echo "❌ ERROR: platformio.ini not found!"
    echo "Please run this script from the DataTracker project root directory"
    exit 1
fi

echo "✓ Project directory verified"
echo ""

# Clean previous build
echo "Step 1/4: Cleaning previous build..."
pio run --target clean > /dev/null 2>&1 || true
echo "✓ Clean complete"
echo ""

# Build the firmware
echo "Step 2/4: Building firmware..."
echo "(This may take a few minutes...)"
pio run

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✓ Build successful"
echo ""

# Create firmware directory
echo "Step 3/4: Preparing web flasher binaries..."
mkdir -p docs/firmware

# PlatformIO build output directory
BUILD_DIR=".pio/build/esp32-c3-devkitm-1"
FIRMWARE_DIR="docs/firmware"

# Copy bootloader
if [ -f "$BUILD_DIR/bootloader.bin" ]; then
    cp "$BUILD_DIR/bootloader.bin" "$FIRMWARE_DIR/"
    echo "✓ Copied bootloader.bin"
else
    echo "⚠️  bootloader.bin not found, searching in platform directory..."
    # Try to find bootloader in platform packages
    BOOTLOADER=$(find ~/.platformio/packages/framework-arduinoespressif32 -name "bootloader*.bin" -path "*/esp32c3/*" | head -n 1)
    if [ -n "$BOOTLOADER" ]; then
        cp "$BOOTLOADER" "$FIRMWARE_DIR/bootloader.bin"
        echo "✓ Copied bootloader.bin from platform"
    else
        echo "❌ ERROR: Could not find bootloader.bin"
        exit 1
    fi
fi

# Copy partitions
if [ -f "$BUILD_DIR/partitions.bin" ]; then
    cp "$BUILD_DIR/partitions.bin" "$FIRMWARE_DIR/"
    echo "✓ Copied partitions.bin"
else
    echo "❌ ERROR: partitions.bin not found"
    exit 1
fi

# Copy boot_app0
if [ -f "$BUILD_DIR/boot_app0.bin" ]; then
    cp "$BUILD_DIR/boot_app0.bin" "$FIRMWARE_DIR/"
    echo "✓ Copied boot_app0.bin"
else
    echo "⚠️  boot_app0.bin not found, searching in platform directory..."
    BOOT_APP0=$(find ~/.platformio/packages/framework-arduinoespressif32 -name "boot_app0.bin" | head -n 1)
    if [ -n "$BOOT_APP0" ]; then
        cp "$BOOT_APP0" "$FIRMWARE_DIR/boot_app0.bin"
        echo "✓ Copied boot_app0.bin from platform"
    else
        echo "❌ ERROR: Could not find boot_app0.bin"
        exit 1
    fi
fi

# Copy main firmware
if [ -f "$BUILD_DIR/firmware.bin" ]; then
    cp "$BUILD_DIR/firmware.bin" "$FIRMWARE_DIR/"
    echo "✓ Copied firmware.bin"
else
    echo "❌ ERROR: firmware.bin not found"
    exit 1
fi

# Get file sizes
echo ""
echo "Step 4/4: Verifying binaries..."
echo ""
echo "Binary sizes:"
echo "  bootloader.bin:  $(du -h "$FIRMWARE_DIR/bootloader.bin" | cut -f1)"
echo "  partitions.bin:  $(du -h "$FIRMWARE_DIR/partitions.bin" | cut -f1)"
echo "  boot_app0.bin:   $(du -h "$FIRMWARE_DIR/boot_app0.bin" | cut -f1)"
echo "  firmware.bin:    $(du -h "$FIRMWARE_DIR/firmware.bin" | cut -f1)"
echo ""

# Create README in firmware directory
cat > "$FIRMWARE_DIR/README.md" << 'EOF'
# Web Flasher Firmware Binaries

These binaries are used by the web-based flasher tool.

## Files

- **bootloader.bin** (offset 0x0000) - ESP32-C3 bootloader
- **partitions.bin** (offset 0x8000) - Partition table
- **boot_app0.bin** (offset 0xe000) - Boot application
- **firmware.bin** (offset 0x10000) - Main application firmware

## Flash Manually

If you want to flash manually using esptool:

```bash
esptool.py --chip esp32c3 --port /dev/ttyUSB0 --baud 460800 \
  --before default_reset --after hard_reset write_flash -z \
  --flash_mode dio --flash_freq 80m --flash_size 4MB \
  0x0 bootloader.bin \
  0x8000 partitions.bin \
  0xe000 boot_app0.bin \
  0x10000 firmware.bin
```

Replace `/dev/ttyUSB0` with your serial port (COM3 on Windows, etc.)

## Web Flasher

Instead of manual flashing, you can use the web-based flasher:
https://yourusername.github.io/DataTracker/flash.html

Just click and flash - no software installation required!
EOF

echo "✓ Created firmware README"
echo ""

# Success message
echo "=========================================="
echo "✅ SUCCESS!"
echo "=========================================="
echo ""
echo "Web flasher binaries are ready in: docs/firmware/"
echo ""
echo "Next steps:"
echo "1. Test the web flasher locally:"
echo "   cd docs && python3 -m http.server 8000"
echo "   Open: http://localhost:8000/flash.html"
echo ""
echo "2. Or commit and push to GitHub Pages:"
echo "   git add docs/"
echo "   git commit -m 'Add web flasher'"
echo "   git push"
echo "   Enable GitHub Pages in repo settings (source: docs folder)"
echo "   Access at: https://yourusername.github.io/DataTracker/flash.html"
echo ""
echo "=========================================="
