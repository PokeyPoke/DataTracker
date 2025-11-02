#!/bin/bash
# Quick Start Script for ESP32-C3 Data Tracker
# This script helps you build and flash the firmware quickly

set -e  # Exit on error

echo "==================================="
echo "ESP32-C3 Data Tracker - Quick Start"
echo "==================================="
echo ""

# Check if PlatformIO is installed
if ! command -v pio &> /dev/null; then
    echo "❌ PlatformIO not found!"
    echo ""
    echo "Please install PlatformIO:"
    echo "  pip install platformio"
    echo ""
    echo "Or install PlatformIO IDE extension for VS Code"
    exit 1
fi

echo "✓ PlatformIO found"

# Check if we're in the right directory
if [ ! -f "platformio.ini" ]; then
    echo "❌ platformio.ini not found!"
    echo "Please run this script from the DataTracker project directory"
    exit 1
fi

echo "✓ Project directory verified"
echo ""

# Menu
echo "What would you like to do?"
echo ""
echo "1) Build firmware"
echo "2) Build and upload firmware"
echo "3) Upload and monitor serial"
echo "4) Monitor serial only"
echo "5) Clean build"
echo "6) Full rebuild (clean + build + upload + monitor)"
echo ""
read -p "Enter choice [1-6]: " choice

case $choice in
    1)
        echo ""
        echo "Building firmware..."
        pio run
        echo ""
        echo "✓ Build complete!"
        echo "Binary location: .pio/build/esp32-c3-devkitm-1/firmware.bin"
        ;;
    2)
        echo ""
        echo "Building and uploading firmware..."
        pio run --target upload
        echo ""
        echo "✓ Upload complete!"
        ;;
    3)
        echo ""
        echo "Building, uploading, and monitoring..."
        pio run --target upload && pio device monitor
        ;;
    4)
        echo ""
        echo "Opening serial monitor..."
        echo "Press Ctrl+C to exit"
        echo ""
        pio device monitor
        ;;
    5)
        echo ""
        echo "Cleaning build files..."
        pio run --target clean
        echo ""
        echo "✓ Clean complete!"
        ;;
    6)
        echo ""
        echo "Full rebuild in progress..."
        echo ""
        echo "Step 1/4: Cleaning..."
        pio run --target clean
        echo ""
        echo "Step 2/4: Building..."
        pio run
        echo ""
        echo "Step 3/4: Uploading..."
        pio run --target upload
        echo ""
        echo "Step 4/4: Monitoring serial..."
        echo "Press Ctrl+C to exit"
        echo ""
        pio device monitor
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo ""
echo "Done!"
