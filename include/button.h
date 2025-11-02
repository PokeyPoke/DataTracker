#ifndef BUTTON_H
#define BUTTON_H

#include <Arduino.h>

// Button timing constants
#define DEBOUNCE_DELAY 50          // ms
#define SHORT_PRESS_MAX 1000       // ms
#define LONG_PRESS_MIN 3000        // ms
#define FACTORY_RESET_MIN 10000    // ms

// Button events
enum ButtonEvent {
    NONE,
    SHORT_PRESS,    // < 1s: Cycle to next module
    LONG_PRESS,     // 3-10s: Enter config mode
    FACTORY_RESET   // 10s+: Clear all settings
};

class ButtonHandler {
private:
    uint8_t pin;
    bool lastState;
    unsigned long pressStartTime;
    unsigned long lastDebounceTime;
    bool isPressed;

public:
    ButtonHandler(uint8_t buttonPin);

    void init();
    ButtonEvent check();
    bool isCurrentlyPressed();
    unsigned long getCurrentPressDuration();
};

#endif // BUTTON_H
