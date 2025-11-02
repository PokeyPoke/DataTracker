# Button Debug Mode - Visual Display Testing

## Easy Way to Test Your Button Without Serial Console!

The display now shows real-time button status so you can see exactly what GPIO2 is reading.

## How to Use

### 1. Flash the New Firmware
Use Quick Flash at: `http://localhost:8080/flash.html`

### 2. Connect to Serial Console (Just to send ONE command)

**Option A - Using PlatformIO:**
```bash
# Plug in USB cable, then:
/home/happyllama/.local/pipx/venvs/platformio/bin/pio device monitor --baud 115200
```

**Option B - Using screen (if available):**
```bash
screen /dev/ttyACM0 115200
```

**Option C - Using Web Serial:**
Open Chrome/Edge browser and use Web Serial to connect

### 3. Enable Button Debug Mode

In the serial console, type:
```
button
```

Press Enter.

### 4. Watch the Display!

The OLED display will now show:

```
   BUTTON DEBUG

      ON/OFF       ← Large text shows status

   Digital: 0 (LOW)   ← Raw GPIO reading
   Analog: 0          ← Analog value
```

### 5. Test Your Button

Press and hold the capacitive touch button:

**What to look for:**

#### Scenario 1: Active-HIGH (Expected)
- **Not touched**: `OFF` + `Digital: 0 (LOW)`
- **Touched**: `ON` + `Digital: 1 (HIGH)` + Red LED lights up

#### Scenario 2: Active-LOW (Inverted)
- **Not touched**: `ON` + `Digital: 1 (HIGH)`
- **Touched**: `OFF` + `Digital: 0 (LOW)` + Red LED lights up

#### Scenario 3: Not Working
- Display always shows same value
- No change when pressing

### 6. Exit Debug Mode

Go back to serial console and type:
```
button
```

This toggles debug mode off, returning to normal operation.

## What the Values Mean

### Digital Value
- `0 (LOW)` = 0V on GPIO2
- `1 (HIGH)` = 3.3V on GPIO2

### Analog Value
- `0` = 0V
- `4095` = 3.3V (maximum)
- Anything in between = partial voltage

### Expected Behavior

**Most capacitive touch modules (TTP223):**
- Output HIGH (3.3V) when touched
- Output LOW (0V) when not touched
- Red LED turns on when touched

## After Testing - Report Results

Tell me what you see:

1. **When NOT touching**: Does it show `ON` or `OFF`?
2. **When touching**: Does it show `ON` or `OFF`?
3. **Red LED**: Does it turn on when you touch?

### If Results Show Active-LOW

If the display shows:
- Not touched = `ON` / `HIGH`
- Touched = `OFF` / `LOW`

Then your module is **active-LOW** and I need to invert the logic in the code.

### If Results Show Active-HIGH

If the display shows:
- Not touched = `OFF` / `LOW`
- Touched = `ON` / `HIGH`

Then the code is already correct! The button should work.

## Troubleshooting

### Can't connect to serial console

Don't worry! You can also:
1. Flash the firmware
2. Wait 10 seconds for boot
3. The device might already be in debug mode by default (I can make it auto-start)

Let me know if you need this option.

### Display stays blank

Check connections:
- SDA → GPIO8
- SCL → GPIO9
- VCC → 3.3V
- GND → GND

### Display shows wrong info

The debug mode updates every 50ms, so it's very responsive. If you see garbled text, try reflashing.

## Quick Reference

| Command | Action |
|---------|--------|
| `button` | Toggle debug mode ON/OFF |
| `help` | Show all commands |
| `switch` | Manually cycle modules (to test if button works) |

## Next Steps

After you report what the display shows:

1. **If active-HIGH is correct**: I'll investigate why button events aren't triggering
2. **If active-LOW**: I'll flip the logic and rebuild
3. **If not working at all**: We'll check wiring/connections

The visual feedback makes this MUCH easier than reading serial console logs!
