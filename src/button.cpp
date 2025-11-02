#include "button.h"

ButtonHandler::ButtonHandler(uint8_t buttonPin)
    : pin(buttonPin), lastState(HIGH), pressStartTime(0),
      lastDebounceTime(0), isPressed(false) {
}

void ButtonHandler::init() {
    pinMode(pin, INPUT_PULLUP);
    lastState = digitalRead(pin);
    Serial.print("Button initialized on pin ");
    Serial.println(pin);
}

ButtonEvent ButtonHandler::check() {
    bool currentState = digitalRead(pin);
    unsigned long now = millis();

    // Debounce
    if (currentState != lastState) {
        lastDebounceTime = now;
    }

    if ((now - lastDebounceTime) > DEBOUNCE_DELAY) {
        // Button pressed (LOW due to pull-up)
        if (currentState == LOW && !isPressed) {
            isPressed = true;
            pressStartTime = now;
            Serial.println("Button pressed");
        }

        // Button released
        if (currentState == HIGH && isPressed) {
            isPressed = false;
            unsigned long pressDuration = now - pressStartTime;

            Serial.print("Button released after ");
            Serial.print(pressDuration);
            Serial.println(" ms");

            if (pressDuration >= FACTORY_RESET_MIN) {
                Serial.println("Factory reset triggered");
                return FACTORY_RESET;
            } else if (pressDuration >= LONG_PRESS_MIN) {
                Serial.println("Long press triggered");
                return LONG_PRESS;
            } else if (pressDuration >= DEBOUNCE_DELAY && pressDuration < SHORT_PRESS_MAX) {
                Serial.println("Short press triggered");
                return SHORT_PRESS;
            }
        }
    }

    lastState = currentState;
    return NONE;
}

bool ButtonHandler::isCurrentlyPressed() {
    return isPressed;
}

unsigned long ButtonHandler::getCurrentPressDuration() {
    if (!isPressed) return 0;
    return millis() - pressStartTime;
}
