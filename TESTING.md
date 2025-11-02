# Testing Guide - Lightweight Firmware v2.0

## What Changed

**Complete architectural redesign** to fix persistent heap corruption on ESP32-C3:

### Removed (Heavy Components)
- ❌ ESP Async WebServer (~15-20KB RAM)
- ❌ AsyncTCP library
- ❌ DNSServer (no auto-captive portal)
- ❌ Display driver (temporarily disabled)

### Added (Lightweight Components)
- ✅ Synchronous WebServer (built-in, minimal RAM)
- ✅ Ultra-compact HTML (<1KB)
- ✅ Improved WiFi scanning (500ms per channel)
- ✅ 10-second WiFi stabilization delay

### Memory Results
```
RAM:   13.1% (42,836 bytes) - Saved 1,336 bytes
Flash: 53.7% (1.0MB)        - Saved 44KB
```

## How to Test

### 1. Flash the Firmware
```bash
# Start the web flasher (if not already running)
cd /home/happyllama/DataTracker/docs
python3 -m http.server 8080
```

Then open: `http://localhost:8080/flash.html`

**IMPORTANT**: Use the **🔄 Factory Reset & Install** button to erase all existing data and start fresh.

### 2. Expected Boot Sequence

**Serial Console Output:**
```
=== ESP32-C3 Data Tracker v1.0 ===
Initializing...

Initializing LittleFS...
LittleFS mounted successfully
Configuration loaded successfully
Display disabled to conserve memory
Button support enabled
No WiFi configuration found
Starting configuration AP mode...
Starting AP: DataTracker-XXXX
AP IP: 192.168.4.1
Web server started
AP ready. Connect and go to 192.168.4.1

=== Setup Complete ===
Type 'help' for available commands
```

**After 10 seconds, you should see:**
```
Starting WiFi scan...
Scan started
Found X networks
Scan complete
```

### 3. Configuration Steps

1. **Connect to WiFi AP**: Look for network named `DataTracker-XXXX` on your phone/computer
2. **Open browser manually**: Navigate to `http://192.168.4.1` (no auto-redirect)
3. **Wait 10 seconds**: Allow time for WiFi scan to complete
4. **Reload page**: If network list is empty, wait and refresh
5. **Configure**:
   - Select your WiFi network
   - Enter password
   - Choose data module (Bitcoin, Ethereum, etc.)
   - Click "Save"
6. **Device restarts**: Should connect to your WiFi and start fetching data

### 4. What to Check

✅ **No heap corruption** - Device should boot cleanly without restarting
✅ **AP mode starts** - Access point appears in WiFi list
✅ **Web interface loads** - Configuration page loads at 192.168.4.1
✅ **Networks appear** - WiFi scan finds your networks (after 10 second delay)
✅ **Save works** - Configuration saves and device restarts

### 5. Known Limitations

- **No captive portal**: Must manually navigate to `192.168.4.1` (no auto-redirect)
- **No display**: OLED disabled to conserve RAM (serial console shows everything)
- **First scan delayed**: WiFi networks appear after ~10 seconds (intentional)

### 6. Troubleshooting

**If heap corruption returns:**
```
assert failed: remove_free_block heap_tlsf.c:205
```
→ This would indicate the issue wasn't fully resolved. Report immediately.

**If no networks found after 20+ seconds:**
1. Check serial console for "Scan complete" message
2. Try refreshing the webpage
3. Check if device is in an area with WiFi coverage
4. Report the exact serial console output

**If webpage doesn't load:**
1. Verify you're connected to the `DataTracker-XXXX` AP
2. Try `http://192.168.4.1` (not https)
3. Check serial console for "Web server started" message

## Success Criteria

The firmware is working correctly if:
1. ✅ Device boots without restarting (no heap corruption)
2. ✅ AP mode starts successfully
3. ✅ Web configuration interface loads
4. ✅ WiFi scan finds networks
5. ✅ Configuration can be saved

## Next Steps After Successful Test

If basic functionality works, we can consider:
- Re-enabling display (if RAM permits)
- Testing actual data modules (Bitcoin, Weather, etc.)
- Optimizing further if needed
