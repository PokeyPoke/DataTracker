#!/bin/bash
# Full erase and flash script for ESP32-C3

set -e

echo "======================================"
echo "ESP32-C3 Full Erase and Flash Script"
echo "======================================"
echo ""
echo "This will:"
echo "1. Erase ALL flash memory (including LittleFS)"
echo "2. Flash the new firmware"
echo ""
echo "Make sure your ESP32-C3 is connected via USB"
echo ""
read -p "Press ENTER to continue or Ctrl+C to cancel..."

ESPTOOL="/home/happyllama/.platformio/packages/tool-esptoolpy/esptool.py"
FIRMWARE="/home/happyllama/DataTracker/.pio/build/esp32-c3-devkitm-1/firmware.bin"
BOOTLOADER="/home/happyllama/DataTracker/.pio/build/esp32-c3-devkitm-1/bootloader.bin"
PARTITIONS="/home/happyllama/DataTracker/.pio/build/esp32-c3-devkitm-1/partitions.bin"
BOOT_APP0="/home/happyllama/.platformio/packages/framework-arduinoespressif32/tools/partitions/boot_app0.bin"

# Detect ESP32-C3 port
PORT=$(ls /dev/ttyACM* 2>/dev/null | head -1)
if [ -z "$PORT" ]; then
    PORT=$(ls /dev/ttyUSB* 2>/dev/null | head -1)
fi

if [ -z "$PORT" ]; then
    echo "ERROR: No ESP32 device found on /dev/ttyACM* or /dev/ttyUSB*"
    exit 1
fi

echo ""
echo "Found ESP32-C3 on: $PORT"
echo ""

# Step 1: Erase all flash
echo "Step 1/2: Erasing ALL flash memory..."
python3 "$ESPTOOL" --chip esp32c3 --port "$PORT" erase_flash

echo ""
echo "Step 2/2: Flashing firmware..."
python3 "$ESPTOOL" --chip esp32c3 --port "$PORT" --baud 460800 \
    --before default_reset --after hard_reset write_flash -z \
    --flash_mode dio --flash_freq 80m --flash_size 4MB \
    0x0 "$BOOTLOADER" \
    0x8000 "$PARTITIONS" \
    0xe000 "$BOOT_APP0" \
    0x10000 "$FIRMWARE"

echo ""
echo "======================================"
echo "Flash complete!"
echo "======================================"
echo ""
echo "The device will reboot now."
echo "Open a serial monitor to see the output:"
echo "  minicom -D $PORT -b 115200"
echo "or use the Arduino IDE Serial Monitor"
