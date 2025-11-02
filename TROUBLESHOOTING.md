# Troubleshooting Guide - ESP32-C3 Data Tracker

## Quick Diagnostics

Before diving into specific issues, run these quick checks:

```bash
# Connect to serial console
pio device monitor

# Check WiFi status
> wifi

# Check cached data
> cache

# Check configuration
> config

# Force a fetch to see errors
> fetch
```

---

## Common Issues

### 1. Display Not Working

#### Symptoms
- Display stays blank/black
- No text appears after power on

#### Solutions

**Check Wiring:**
```
Verify connections:
ESP32-C3 GPIO8 (SDA) → Display SDA
ESP32-C3 GPIO9 (SCL) → Display SCL
ESP32-C3 3.3V → Display VCC
ESP32-C3 GND → Display GND
```

**Check I2C Address:**
```bash
# Some displays use 0x3D instead of 0x3C
# Edit platformio.ini:
build_flags =
    -D I2C_ADDRESS=0x3D

# Rebuild and upload
pio run --target upload
```

**Verify Display Type:**
- Ensure you have SH1106, not SSD1306
- SSD1306 requires different initialization
- Check display datasheet

**Test I2C Scan:**
Add this to setup() temporarily:
```cpp
#include <Wire.h>

void setup() {
    Wire.begin(8, 9);  // SDA, SCL
    Serial.begin(115200);
    delay(1000);

    Serial.println("Scanning I2C...");
    for (uint8_t addr = 1; addr < 127; addr++) {
        Wire.beginTransmission(addr);
        if (Wire.endTransmission() == 0) {
            Serial.print("Device found at 0x");
            Serial.println(addr, HEX);
        }
    }
}
```

---

### 2. WiFi Connection Issues

#### Symptoms
- Display shows "Connecting to WiFi..." indefinitely
- Serial shows "WiFi connection failed"

#### Solutions

**A. Wrong Password**
```bash
# Enter config mode
> reset
# Or hold button 3 seconds

# Reconnect to DataTracker-XXXX AP
# Re-enter WiFi credentials carefully
```

**B. Hidden SSID**
```bash
# Hidden networks may not work with WiFi scan
# Manually edit config.json:
{
  "wifi": {
    "ssid": "YourHiddenNetwork",
    "password": "YourPassword"
  }
}

# Upload filesystem:
pio run --target uploadfs
```

**C. 5GHz Network**
```
ESP32-C3 only supports 2.4GHz WiFi
- Check router settings
- Create 2.4GHz network if needed
- Or use separate 2.4GHz SSID
```

**D. Weak Signal**
```bash
# Check signal strength
> wifi
RSSI: -75 dBm  ← Too weak (< -70 dBm)

# Solutions:
- Move device closer to router
- Use WiFi extender
- Reduce obstacles between device and router
```

**E. Router MAC Filtering**
```bash
# Get device MAC address from serial output
> wifi
MAC: AA:BB:CC:DD:EE:FF

# Add to router's allowed devices
```

---

### 3. Data Not Updating

#### Symptoms
- Display shows old data
- "!" indicator present (stale data)
- No updates after waiting

#### Solutions

**A. Check WiFi Connection**
```bash
> wifi
# If disconnected, troubleshoot WiFi first
```

**B. Check Last Fetch Time**
```bash
> cache
# Look at "lastUpdate" timestamps
# If very old (hours/days), issue with fetching
```

**C. Force Fetch to See Errors**
```bash
> fetch
# Watch serial output for specific error
```

**D. API Rate Limiting**
```bash
# Check scheduler logs
Fetch denied: module cooldown
# Solution: Wait for cooldown period

# Or check global cooldown
Fetch denied: global cooldown active
# Solution: Wait 10 seconds minimum between fetches
```

**E. API Service Down**
```bash
# Test API manually:
curl "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd"

# If fails, API is down - wait for service restoration
# Device will retry with exponential backoff
```

---

### 4. Display Shows "-- " or Error

#### Symptoms
- Price/value shows as `--`
- Display shows "ERROR" message

#### Solutions

**A. Invalid Stock Ticker**
```bash
> config
# Check "modules" → "stock" → "ticker"
# Verify ticker is valid (e.g., AAPL, TSLA, not APPL or TESA)

# Fix via config portal or serial
> reset
```

**B. Market Closed (Stocks)**
```
Stock prices only update during trading hours
- NYSE: 9:30 AM - 4:00 PM ET, Monday-Friday
- Device shows last known price with "X" indicator

# This is normal behavior, not an error
```

**C. Invalid Weather Coordinates**
```bash
> config
# Check "modules" → "weather" → "latitude" and "longitude"
# Valid ranges:
#   Latitude: -90 to 90
#   Longitude: -180 to 180

# Find correct coordinates: https://www.latlong.net/
```

**D. JSON Parse Error**
```bash
> fetch
JSON parse error: ...

# Possible causes:
# - API response format changed
# - Incomplete response (timeout)
# - Memory issue

# Solutions:
# 1. Increase HTTP timeout in network.cpp
# 2. Check heap memory: Serial.println(ESP.getFreeHeap());
# 3. Try different API endpoint
```

---

### 5. Button Not Responding

#### Symptoms
- Pressing button does nothing
- No serial output when button pressed

#### Solutions

**A. Button Not Enabled**
```bash
# Check platformio.ini:
build_flags =
    -D ENABLE_BUTTON=true  ← Must be true

# Rebuild and upload
pio run --target upload
```

**B. Wrong Pin**
```bash
# Verify button connected to GPIO2
# Or change pin in platformio.ini:
build_flags =
    -D BUTTON_PIN=3  ← Change to your pin

# Rebuild and upload
```

**C. Wiring Issue**
```
Correct wiring:
GPIO2 → Button → GND

Internal pull-up is enabled, so:
- Button released = HIGH
- Button pressed = LOW (connected to GND)

Verify with multimeter:
- Measure GPIO2 to GND
- Should be ~3.3V when released
- Should be ~0V when pressed
```

**D. Debounce Issue**
```
If button triggers randomly:
- Check for loose connections
- Use shielded wire if cable is long
- Add 0.1µF capacitor across button terminals
```

---

### 6. Device Keeps Restarting

#### Symptoms
- Continuous reboot loop
- Serial shows repeated "=== ESP32-C3 Data Tracker v1.0 ==="

#### Solutions

**A. Power Supply Issue**
```
Insufficient power causes brownouts
- Use quality USB cable (not just charging cable)
- Try different USB port or wall adapter
- Minimum: 500mA @ 5V
- Recommended: 1A @ 5V
```

**B. Memory Corruption**
```bash
# Check heap during operation
# Add to main.cpp loop():
Serial.print("Free heap: ");
Serial.println(ESP.getFreeHeap());

# If heap decreases over time:
# - Memory leak in code
# - Too many allocations

# Solutions:
# 1. Factory reset
> reset

# 2. Flash fresh firmware
pio run --target upload
```

**C. Watchdog Timeout**
```cpp
// If blocking operations too long, watchdog triggers reset
// Check for long delays in code
// Solutions:
// 1. Break up long operations
// 2. Add yield() calls
// 3. Increase watchdog timeout
```

**D. Corrupted Filesystem**
```bash
# Format and re-upload
pio run --target uploadfs

# Or factory reset from device
> reset
```

---

### 7. Captive Portal Not Opening

#### Symptoms
- Connected to DataTracker-XXXX AP
- Browser doesn't auto-redirect
- Can't access 192.168.4.1

#### Solutions

**A. Manual Navigation**
```
1. Connect to DataTracker-XXXX WiFi
2. Manually open browser
3. Go to: http://192.168.4.1
4. Or try: http://192.168.4.1/
```

**B. DNS Cache**
```
Clear browser cache and DNS:
- Chrome: chrome://net-internals/#dns → Clear
- Firefox: about:networking#dns → Clear
- Safari: Empty Caches
- Or use Incognito/Private mode
```

**C. Firewall/VPN**
```
Some firewalls block captive portals
- Disable VPN temporarily
- Disable firewall temporarily
- Try different device (phone vs laptop)
```

**D. Wrong IP**
```bash
# Verify AP IP from serial output
> wifi
AP IP address: 192.168.4.1

# Use that exact IP in browser
```

---

### 8. Module Not Displaying Correctly

#### Symptoms
- Text cut off or overlapping
- Values not formatted properly
- Strange characters on display

#### Solutions

**A. Font Size Issue**
```cpp
// If values too large for display
// Edit display.cpp, reduce font size
// For example, change:
u8g2.setFont(u8g2_font_logisoso32_tn);
// To:
u8g2.setFont(u8g2_font_logisoso24_tn);
```

**B. String Too Long**
```cpp
// Ticker names or location names may be too long
// Edit module to truncate:
String ticker = stockData["ticker"] | "AAPL";
if (ticker.length() > 6) {
    ticker = ticker.substring(0, 6);
}
```

**C. UTF-8 Characters**
```cpp
// Weather symbols may not display
// Ensure UTF-8 is enabled:
u8g2.enableUTF8Print();

// Or use ASCII alternatives:
// Instead of "↑", use "^"
// Instead of "↓", use "v"
```

---

## Advanced Diagnostics

### Enable Debug Logging

Edit `platformio.ini`:
```ini
build_flags =
    -D DEBUG_MODE=true
    -D CORE_DEBUG_LEVEL=5
```

Rebuild and monitor serial for verbose output.

### Check Memory Usage

Add to `loop()`:
```cpp
static unsigned long lastMemCheck = 0;
if (millis() - lastMemCheck > 10000) {  // Every 10s
    Serial.print("Free heap: ");
    Serial.println(ESP.getFreeHeap());
    lastMemCheck = millis();
}
```

Watch for decreasing heap (memory leak indicator).

### Test Network Independently

```cpp
// Add temporary test to setup()
WiFiClientSecure *client = new WiFiClientSecure;
client->setInsecure();
HTTPClient https;
https.begin(*client, "https://api.coingecko.com/api/v3/ping");
int code = https.GET();
Serial.print("Test ping response: ");
Serial.println(code);  // Should be 200
https.end();
delete client;
```

---

## Getting Help

If issue persists after trying solutions above:

### 1. Gather Information

```bash
# Run diagnostics
> wifi
> config
> cache
> fetch

# Copy all output
```

### 2. Check Serial Output

```bash
# Capture full boot sequence
pio device monitor > boot_log.txt

# Include in issue report
```

### 3. Open GitHub Issue

Include:
- **Problem description** (what's wrong, what did you expect)
- **Hardware** (ESP32-C3 board model, display model)
- **Serial output** (full log from boot)
- **Configuration** (output of `config` command, remove WiFi password!)
- **Steps to reproduce**
- **What you've already tried**

Template:
```markdown
**Problem:** Display not updating

**Hardware:**
- ESP32-C3 Super Mini
- SH1106 128x64 OLED (I2C address 0x3C)

**Serial Output:**
```
[paste serial log here]
```

**Configuration:**
```
[paste config output, remove password]
```

**Steps to Reproduce:**
1. Flash firmware
2. Configure WiFi
3. Select Bitcoin module
4. Wait 10 minutes - no update

**Already Tried:**
- Factory reset
- Different WiFi network
- Force fetch via serial - same issue
```

---

## Still Stuck?

- **Discord/Slack**: [Link to community chat]
- **GitHub Discussions**: [Link to discussions]
- **Email**: support@example.com

---

**Most issues can be solved with factory reset + reconfiguration!**

```bash
# Last resort: Nuclear option
> reset
# Hold button 10+ seconds
# Or send 'reset' via serial
```
