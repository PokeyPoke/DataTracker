# Button/Touch Sensor Guide

## Hardware Setup

**Your Setup**: External capacitive touch module on GPIO2 (ESP32-C3 doesn't have built-in touch sensors)

**Common Modules**:
- TTP223 (most common)
- AT42QT1011
- MPR121 (I2C)
- Any module that outputs digital HIGH/LOW signal

## How It Works

### Capacitive Touch Module Behavior
Most external capacitive touch modules output:
- **HIGH (3.3V)** when touched
- **LOW (0V)** when not touched

The firmware now correctly detects this active-HIGH behavior.

## Button Functions

| Touch Duration | Function | Description |
|---------------|----------|-------------|
| **< 1 second** | **Cycle Module** | Switch to next data module (Bitcoin → Ethereum → Stock → Weather → Custom) |
| **3-10 seconds** | **Config Mode** | Enter WiFi configuration mode (clears WiFi settings and restarts in AP mode) |
| **10+ seconds** | **Factory Reset** | Complete factory reset with 3-second countdown |

## Testing the Button

### 1. Flash New Firmware

Use the web flasher with **Quick Flash** to update:
```
http://localhost:8080/flash.html
```

### 2. Check Serial Console

After flashing, watch the serial console (115200 baud) for:

```
Initializing capacitive touch module on GPIO2
Touch sensor ready (active HIGH)
```

This confirms the touch sensor is initialized.

### 3. Test Short Press (Cycle Module)

1. **Quick tap** the touch button (< 1 second)
2. **Serial output should show**:
   ```
   Button touched
   Button released after XXX ms
   Short press triggered (cycle module)
   Cycling from bitcoin to ethereum
   ```
3. **Display should update** showing the next module

### 4. Test Long Press (Config Mode)

1. **Hold** the touch button for 3-5 seconds
2. **Serial output should show**:
   ```
   Button touched
   Button released after XXXX ms
   Long press triggered (config mode)
   Entering configuration mode...
   ```
3. **Device restarts** in AP mode for WiFi configuration

### 5. Test Factory Reset

1. **Hold** the touch button for 10+ seconds
2. **Serial output should show**:
   ```
   Button touched
   Button released after XXXXX ms
   Factory reset triggered
   FACTORY RESET INITIATED
   Resetting in 3...
   Resetting in 2...
   Resetting in 1...
   Formatting filesystem...
   ```
3. **All settings erased** and device restarts fresh

## Troubleshooting

### Button Not Responding

**Check serial console for touch sensor initialization:**
```
Initializing capacitive touch module on GPIO2
Touch sensor ready (active HIGH)
```

**If not appearing**, button support might be disabled in config.

### Always Triggering / Constantly Pressed

**Symptom**: Device keeps reporting "Button touched" continuously

**Possible causes**:
1. Touch module might be **active-LOW** instead of active-HIGH
2. Loose connection
3. Module needs power

**Solution**: We can add a configuration option to invert the logic if needed.

### Triggers Wrong Function

**Symptom**: Quick tap triggers factory reset instead of cycling modules

**This was the original problem!** The new firmware should fix this. The issue was:
- Old code expected LOW for button press (pull-up resistor)
- Capacitive touch module outputs HIGH when touched
- This caused inverted logic → immediate factory reset

**New firmware** correctly detects HIGH as touched for capacitive modules.

### Module-Specific Issues

#### TTP223
- Some TTP223 modules have solder jumper to configure active-HIGH/LOW
- Default is usually active-HIGH (HIGH when touched)
- If your module is active-LOW, let me know and I'll add a config option

#### AT42QT1011
- Similar behavior to TTP223
- Active-HIGH by default

## Wiring

Typical capacitive touch module wiring:
```
Touch Module    ESP32-C3
-----------     --------
VCC       -->   3.3V
GND       -->   GND
OUT/SIG   -->   GPIO2
```

## Serial Debugging

To see detailed button behavior, watch serial console:

```bash
/home/happyllama/.local/pipx/venvs/platformio/bin/pio device monitor --baud 115200
```

**You should see**:
- "Button touched" when you touch
- "Button released after XXX ms" when you release
- Corresponding function triggered based on duration

## Advanced Configuration

If you need to invert the touch logic (active-LOW instead of active-HIGH), I can add a build flag:

```ini
# In platformio.ini
build_flags =
    -D TOUCH_ACTIVE_LOW=true
```

Let me know if this is needed based on your testing!

## Expected Behavior Summary

✅ **Quick tap** (< 1s): Cycles through data modules
✅ **Long hold** (3-10s): Enters config mode (for changing WiFi)
✅ **Very long hold** (10s+): Factory reset with countdown

The key fix: Capacitive touch modules output HIGH when touched, not LOW like regular buttons with pull-up resistors.
