# Usage Guide - ESP32-C3 Data Tracker

## Table of Contents
1. [First Time Setup](#first-time-setup)
2. [Changing Metrics](#changing-metrics)
3. [Button Usage](#button-usage)
4. [Serial Console Commands](#serial-console-commands)
5. [Understanding the Display](#understanding-the-display)
6. [Advanced Configuration](#advanced-configuration)

---

## First Time Setup

### Step 1: Flash the Firmware

```bash
# Navigate to project directory
cd DataTracker

# Build and upload
pio run --target upload

# Open serial monitor to see boot messages
pio device monitor
```

### Step 2: Connect to Configuration Portal

1. **Power on the device**
   - Serial output will show: `Starting configuration AP mode...`
   - Look for SSID: `DataTracker-XXXX` (XXXX = last 4 MAC digits)

2. **Connect to the WiFi AP**
   - Use your phone or computer
   - Network name: `DataTracker-XXXX`
   - No password required

3. **Access the web interface**
   - Most devices auto-redirect to setup page
   - If not, manually browse to: `http://192.168.4.1`

### Step 3: Configure WiFi and Metric

1. **WiFi Setup**
   - Select your home WiFi network from dropdown
   - Enter WiFi password
   - Click "Next" or scroll down

2. **Choose Metric**
   - Select one of: Bitcoin, Ethereum, Stock, Weather, or Custom
   - Configure metric-specific settings:

   **For Stock:**
   - Enter ticker symbol (e.g., `AAPL`, `TSLA`, `GOOGL`)

   **For Weather:**
   - Enter latitude (e.g., `37.7749`)
   - Enter longitude (e.g., `-122.4194`)
   - Optional: Enter location name (e.g., `San Francisco`)
   - Use [latlong.net](https://www.latlong.net/) to find coordinates

   **For Custom:**
   - Enter numeric value
   - Enter label (displayed as title)
   - Optional: Enter unit (e.g., `kg`, `mph`, `units`)

3. **Set Refresh Interval**
   - Drag slider to choose update frequency
   - Range: 1-30 minutes
   - Recommended: 5 minutes (300 seconds)

4. **Save & Restart**
   - Click "Save & Restart" button
   - Device will reboot and connect to your WiFi
   - Display will show the selected metric

---

## Changing Metrics

### Method 1: Button (if enabled)

1. **Short press** (< 1 second) to cycle through metrics
2. Display immediately shows cached value
3. Fresh data fetched in background (respects rate limits)

**Cycle order:**
Bitcoin → Ethereum → Stock → Weather → Custom → Bitcoin

### Method 2: Serial Console

```bash
# Connect to serial port at 115200 baud
pio device monitor

# Type command:
switch
```

### Method 3: Re-enter Config Mode

1. **Long press button** (3 seconds) OR send `reset` serial command
2. Device restarts in AP mode
3. Follow setup steps again with new settings

---

## Button Usage

Button is optional but provides convenient control without serial connection.

| Press Duration | Action | Visual Feedback |
|---------------|--------|-----------------|
| **< 1 second** | Cycle to next metric | Display changes immediately |
| **3-10 seconds** | Enter config mode | Shows "Entering Setup" |
| **10+ seconds** | Factory reset | Shows countdown: "Reset in 3..." |

**Tips:**
- Hold button firmly until action completes
- Watch display for confirmation
- Release after seeing feedback

---

## Serial Console Commands

### Connecting to Serial

**PlatformIO:**
```bash
pio device monitor
```

**Arduino IDE:**
- Open Serial Monitor
- Set baud rate to 115200
- Set line ending to "Newline"

**Other tools:**
```bash
# Windows
putty COM3 115200

# macOS/Linux
screen /dev/ttyUSB0 115200
# or
minicom -D /dev/ttyUSB0 -b 115200
```

### Available Commands

```
help      - Show all available commands
config    - Display full configuration (JSON format)
wifi      - Show WiFi connection status and signal strength
fetch     - Force immediate data fetch (ignores cooldown)
cache     - Display all cached module data
modules   - List all available modules with descriptions
switch    - Cycle to next module
reset     - Factory reset (WARNING: erases all settings)
restart   - Reboot device
```

### Example Usage

```bash
# Check WiFi connection
> wifi
=== WiFi Status ===
Status: CONNECTED
SSID: MyHomeNetwork
IP: 192.168.1.42
RSSI: -45 dBm
===================

# Force update current metric
> fetch
Forcing fetch for: bitcoin
Fetching data for: bitcoin
HTTP GET: https://api.coingecko.com/api/v3/simple/price...
Bitcoin price: $43250.67 (2.34%)
Fetch successful

# View cached data
> cache
=== Cached Module Data ===
bitcoin: {"value":43250.67,"change24h":2.34,"lastUpdate":1234567,"lastSuccess":true}
ethereum: {"value":2280.50,"change24h":-1.25,"lastUpdate":1234500,"lastSuccess":true}
...
==========================

# Switch to next module
> switch
Cycling from bitcoin to ethereum
```

---

## Understanding the Display

### Display Layout

```
┌────────────────────────────────┐
│ MODULE NAME            [ICON]  │  ← Header (8px font)
├────────────────────────────────┤
│                                │
│        MAIN VALUE              │  ← Large (24-32px font)
│        subtext                 │  ← Medium (12px font)
│                                │
├────────────────────────────────┤
│ [W] Updated: 2m ago         !  │  ← Status bar
└────────────────────────────────┘
```

### Status Indicators

| Symbol | Meaning |
|--------|---------|
| **W** | WiFi connected |
| **X** | WiFi disconnected |
| **!** | Data is stale (> 2× refresh interval) |
| **^** | Value increased |
| **v** | Value decreased |

### Display Examples

**Bitcoin:**
```
  BITCOIN

  $43,250.67
  ^ 2.3% (24h)

  W Updated: 2m ago
```

**Weather:**
```
  WEATHER

  18.5°C
  Cloudy

  San Francisco
  W Updated: 5m ago
```

**Stock:**
```
  AAPL

  $175.43
  v 0.8% (today)

  W Updated: 1m ago
```

---

## Advanced Configuration

### Manually Editing Config

If you have the device connected via serial and want to modify settings:

1. Connect to serial console
2. Type `config` to view current settings
3. Use config portal or edit `/data/config.json` and upload filesystem

### Uploading Filesystem

```bash
# Edit data/config.json with your settings
nano data/config.json

# Upload to device
pio run --target uploadfs
```

### Changing I2C Pins

Edit `platformio.ini`:
```ini
build_flags =
    -D SDA_PIN=10    ; Change to your SDA pin
    -D SCL_PIN=11    ; Change to your SCL pin
```

Then rebuild and upload.

### Changing Display Address

Some SH1106 displays use address `0x3D` instead of `0x3C`.

Edit `platformio.ini`:
```ini
build_flags =
    -D I2C_ADDRESS=0x3D
```

### Disabling Button

Edit `platformio.ini`:
```ini
build_flags =
    -D ENABLE_BUTTON=false
```

### Adjusting Rate Limits

Edit `src/modules/bitcoin_module.cpp` (or other module):
```cpp
BitcoinModule() {
    id = "bitcoin";
    displayName = "BTC/USD";
    defaultRefreshInterval = 600;  // 10 minutes
    minRefreshInterval = 120;      // 2 minutes minimum
}
```

**Note:** Respect API rate limits!
- CoinGecko: 50 calls/minute (free tier)
- Yahoo Finance: Generally unlimited
- Open-Meteo: Unlimited

---

## Tips & Best Practices

### Battery Usage (if using battery)
- Shorter refresh intervals = more power consumption
- Recommended: 15-30 minute intervals for battery operation
- Deep sleep mode not yet implemented (future feature)

### WiFi Signal
- Device needs stable WiFi to fetch data
- Weak signal may cause fetch failures
- Check signal strength: `wifi` command (RSSI > -70 dBm is good)

### Data Accuracy
- Stock prices only update during market hours
- Cryptocurrency prices are delayed ~1-5 minutes
- Weather updates every 15 minutes from source

### Reliability
- Device caches last known value
- Survives temporary network outages
- Automatic retry with exponential backoff

---

## Next Steps

- [Troubleshooting Guide](TROUBLESHOOTING.md) - Fix common issues
- [README.md](README.md) - Project overview
- [GitHub Issues](https://github.com/yourusername/DataTracker/issues) - Report bugs

---

**Questions?** Open an issue or discussion on GitHub!
