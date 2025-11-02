# Build Guide - ESP32-C3 Data Tracker

Complete instructions for building and flashing the firmware.

## Prerequisites

### Required Software

1. **PlatformIO**
   - Recommended: VS Code + PlatformIO IDE extension
   - Alternative: PlatformIO CLI

2. **Git** (optional, for cloning)

3. **USB Drivers** (if needed)
   - Windows: CH340/CP2102 drivers
   - macOS/Linux: Usually pre-installed

### Required Hardware

- ESP32-C3 Super Mini development board
- SH1106 OLED display (128×64, I2C)
- USB-C cable (data capable, not charge-only)
- Breadboard and jumper wires (or soldering equipment)
- Optional: Push button

---

## Setup Development Environment

### Option 1: VS Code + PlatformIO (Recommended)

1. **Install VS Code**
   ```bash
   # Download from https://code.visualstudio.com/
   ```

2. **Install PlatformIO Extension**
   - Open VS Code
   - Go to Extensions (Ctrl+Shift+X)
   - Search for "PlatformIO IDE"
   - Click Install
   - Restart VS Code

3. **Verify Installation**
   - Click PlatformIO icon in sidebar
   - Should see "PIO Home" button

### Option 2: PlatformIO CLI

```bash
# Install Python 3.6+ first
python3 --version

# Install PlatformIO Core
pip install platformio

# Verify installation
pio --version
```

---

## Get the Code

### Method 1: Clone Repository

```bash
git clone https://github.com/yourusername/DataTracker.git
cd DataTracker
```

### Method 2: Download ZIP

1. Download ZIP from GitHub
2. Extract to desired location
3. Open folder in terminal/VS Code

---

## Hardware Assembly

### Wiring Connections

```
ESP32-C3 Super Mini    →    SH1106 OLED
─────────────────────────────────────────
3.3V                   →    VCC
GND                    →    GND
GPIO8 (SDA)            →    SDA
GPIO9 (SCL)            →    SCL

Optional Button:
GPIO2                  →    Button → GND
```

### Assembly Tips

**Breadboard Setup:**
1. Insert ESP32-C3 in center of breadboard
2. Connect display using jumper wires
3. If using button, connect one terminal to GPIO2, other to GND
4. Double-check all connections before powering on

**Soldering (Permanent):**
1. Solder header pins to ESP32-C3 and display
2. Use solid core wire for connections
3. Heat shrink tubing for insulation
4. Optional: Design and 3D print enclosure

**Important:**
- Do NOT connect 5V to display (will damage it!)
- Use 3.3V output from ESP32-C3
- Verify pinout of your specific ESP32-C3 board

---

## Configure Build Settings

### Edit platformio.ini

Before building, review and adjust settings:

```ini
[env:esp32-c3-devkitm-1]
platform = espressif32
board = esp32-c3-devkitm-1
framework = arduino

monitor_speed = 115200
monitor_filters = esp32_exception_decoder

build_flags =
    -D ENABLE_BUTTON=true      ; Set to false if no button
    -D DEBUG_MODE=false        ; Set to true for verbose logging
    -D BUTTON_PIN=2            ; Change if using different GPIO
    -D SDA_PIN=8               ; I2C SDA pin
    -D SCL_PIN=9               ; I2C SCL pin
    -D I2C_ADDRESS=0x3C        ; Display I2C address (try 0x3D if 0x3C doesn't work)

lib_deps =
    bblanchon/ArduinoJson@^6.21.3
    olikraus/U8g2@^2.35.7
    ESP Async WebServer@^1.2.3
    asynctcp@^1.1.1

board_build.filesystem = littlefs
board_build.partitions = min_spiffs.csv
```

### Common Customizations

**Different I2C Pins:**
```ini
build_flags =
    -D SDA_PIN=10
    -D SCL_PIN=11
```

**Different Display Address:**
```ini
build_flags =
    -D I2C_ADDRESS=0x3D
```

**No Button:**
```ini
build_flags =
    -D ENABLE_BUTTON=false
```

---

## Build the Firmware

### VS Code + PlatformIO

1. **Open Project**
   - File → Open Folder → Select DataTracker folder
   - PlatformIO will auto-detect project

2. **Install Dependencies**
   - PlatformIO automatically installs libraries
   - Wait for "PlatformIO: Build" task to complete

3. **Build**
   - Click checkmark icon in bottom toolbar (PlatformIO: Build)
   - Or press Ctrl+Alt+B
   - Or open Command Palette (Ctrl+Shift+P) → "PlatformIO: Build"

4. **Verify Success**
   ```
   SUCCESS ✓
   RAM:   [===       ]  15.2% (used 49824 bytes)
   Flash: [=====     ]  46.8% (used 614692 bytes)
   ```

### PlatformIO CLI

```bash
# Navigate to project folder
cd DataTracker

# Build
pio run

# Expected output:
# ...
# RAM:   [===       ]  15.2%
# Flash: [=====     ]  46.8%
# ========================= [SUCCESS] =========================
```

### Troubleshooting Build Errors

**Error: "Platform 'espressif32' not installed"**
```bash
pio platform install espressif32
```

**Error: Library not found**
```bash
pio lib install
```

**Error: Board not recognized**
```ini
# Try alternative board definition:
board = esp32-c3-devkitc-02
# or
board = lolin_c3_mini
```

---

## Upload Firmware

### Connect Hardware

1. **Plug in ESP32-C3** via USB-C cable
2. **Verify Connection**

   **Windows:**
   - Check Device Manager → Ports (COM & LPT)
   - Should see "USB Serial Device (COMx)"

   **macOS:**
   ```bash
   ls /dev/tty.usbserial-*
   # or
   ls /dev/tty.wchusbserial*
   ```

   **Linux:**
   ```bash
   ls /dev/ttyUSB*
   # or
   ls /dev/ttyACM*
   ```

### Upload via VS Code

1. **Select Upload**
   - Click arrow icon in bottom toolbar (PlatformIO: Upload)
   - Or press Ctrl+Alt+U
   - Or Command Palette → "PlatformIO: Upload"

2. **Wait for Upload**
   ```
   Writing at 0x00040000... (100 %)
   Hash of data verified.
   Leaving...
   Hard resetting via RTS pin...
   ========================= [SUCCESS] =========================
   ```

### Upload via CLI

```bash
pio run --target upload
```

### Upload Troubleshooting

**Error: "Serial port not found"**
```bash
# List available ports
pio device list

# Specify port manually
pio run --target upload --upload-port /dev/ttyUSB0
# or Windows:
pio run --target upload --upload-port COM3
```

**Error: "Failed to connect"**
- Unplug and replug USB cable
- Try different USB port
- Hold BOOT button while plugging in (enter bootloader mode)
- Check USB cable is data-capable (not charge-only)

**Error: "Permission denied" (Linux)**
```bash
# Add user to dialout group
sudo usermod -a -G dialout $USER
# Log out and back in

# Or use sudo (not recommended)
sudo pio run --target upload
```

---

## Monitor Serial Output

### VS Code

1. Click plug icon in bottom toolbar (PlatformIO: Serial Monitor)
2. Or Command Palette → "PlatformIO: Serial Monitor"

### CLI

```bash
pio device monitor
```

### Expected Output

```
=== ESP32-C3 Data Tracker v1.0 ===
Initializing...

LittleFS mounted successfully
Config file not found, creating default config
Default configuration created
Configuration saved successfully
Display initialized
No WiFi configuration found
Starting configuration AP mode...
Starting AP: DataTracker-A3F2
AP IP address: 192.168.4.1
Web server started

=== Setup Complete ===
Type 'help' for available commands
```

---

## Optional: Upload Filesystem

If you have a pre-configured `data/config.json`:

### VS Code

1. Command Palette (Ctrl+Shift+P)
2. "PlatformIO: Upload Filesystem Image"

### CLI

```bash
pio run --target uploadfs
```

**Note:** This will overwrite existing configuration on device!

---

## Verify Installation

### 1. Check Display

- Should show splash screen briefly
- Then show "SETUP MODE"
- Instructions to connect to WiFi AP

### 2. Connect to AP

- WiFi network: `DataTracker-XXXX`
- Open browser → should auto-redirect

### 3. Configure Device

- Follow on-screen instructions
- Save configuration
- Device reboots

### 4. Verify Data Fetching

```bash
# Connect to serial monitor
pio device monitor

# Wait for first fetch or force one
> fetch

# Should see:
Fetching data for: bitcoin
HTTP GET: https://api.coingecko.com/api/v3/simple/price...
Bitcoin price: $43250.67 (2.34%)
Fetch successful
```

---

## Next Steps

1. **Customize Configuration**
   - Try different modules (stock, weather, etc.)
   - Adjust refresh interval
   - Test button functionality

2. **Enclose in Case** (optional)
   - Design 3D printable case
   - Or use off-the-shelf project box
   - Ensure ventilation for ESP32-C3

3. **Mount Permanently**
   - USB power from wall adapter
   - Or power from 5V power supply
   - Position for visibility

---

## Building for Production

### Optimize for Size

```ini
build_flags =
    -D DEBUG_MODE=false
    -D CORE_DEBUG_LEVEL=0
    -Os  ; Optimize for size
```

### Disable Unused Features

```ini
build_flags =
    -D ENABLE_BUTTON=false  ; If no button
```

### Create Release Binary

```bash
# Build optimized release
pio run --environment esp32-c3-devkitm-1

# Binary location:
# .pio/build/esp32-c3-devkitm-1/firmware.bin

# Can be flashed with esptool:
esptool.py --chip esp32c3 write_flash 0x0 firmware.bin
```

---

## Version Control

### Recommended .gitignore

Already included in project:
```
.pio/
.vscode/
config.json
*.log
```

### Branching Strategy

```bash
# Main branch for stable releases
git checkout main

# Development branch
git checkout -b develop

# Feature branches
git checkout -b feature/new-module
```

---

## Continuous Integration (Optional)

### GitHub Actions Example

Create `.github/workflows/build.yml`:

```yaml
name: PlatformIO CI

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: actions/cache@v3
      with:
        path: |
          ~/.cache/pip
          ~/.platformio/.cache
        key: ${{ runner.os }}-pio
    - uses: actions/setup-python@v4
      with:
        python-version: '3.9'
    - name: Install PlatformIO Core
      run: pip install --upgrade platformio
    - name: Build firmware
      run: pio run
```

---

## Additional Resources

- **PlatformIO Docs**: https://docs.platformio.org/
- **ESP32-C3 Docs**: https://docs.espressif.com/projects/esp-idf/en/latest/esp32c3/
- **U8g2 Reference**: https://github.com/olikraus/u8g2/wiki
- **ArduinoJson**: https://arduinojson.org/

---

## Support

If you encounter build issues:

1. Clean build folder: `pio run --target clean`
2. Update PlatformIO: `pio upgrade`
3. Delete `.pio` folder and rebuild
4. Check GitHub Issues for similar problems
5. Open new issue with build log

---

**Happy Building! 🚀**
