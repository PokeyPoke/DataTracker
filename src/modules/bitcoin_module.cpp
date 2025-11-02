#include "module_interface.h"
#include "config.h"
#include "network.h"
#include <ArduinoJson.h>

// External network manager (will be initialized in main)
extern NetworkManager network;

class BitcoinModule : public ModuleInterface {
public:
    BitcoinModule() {
        id = "bitcoin";
        displayName = "BTC/USD";
        defaultRefreshInterval = 300;  // 5 minutes
        minRefreshInterval = 60;       // 1 minute
    }

    bool fetch(String& errorMsg) override {
        const char* url = "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd&include_24hr_change=true";

        String response;
        if (!network.httpGet(url, response, errorMsg)) {
            return false;
        }

        return parseResponse(response, errorMsg);
    }

    bool parseResponse(String payload, String& errorMsg) {
        StaticJsonDocument<512> doc;
        DeserializationError error = deserializeJson(doc, payload);

        if (error) {
            errorMsg = "JSON parse error: " + String(error.c_str());
            return false;
        }

        if (!doc.containsKey("bitcoin")) {
            errorMsg = "Invalid response structure";
            return false;
        }

        float price = doc["bitcoin"]["usd"];
        float change = doc["bitcoin"]["usd_24h_change"];

        // Update cache
        JsonObject data = config["modules"]["bitcoin"].to<JsonObject>();
        data["value"] = price;
        data["change24h"] = change;
        data["lastUpdate"] = millis() / 1000;
        data["lastSuccess"] = true;

        Serial.print("Bitcoin price: $");
        Serial.print(price, 2);
        Serial.print(" (");
        Serial.print(change, 2);
        Serial.println("%)");

        return true;
    }

    String formatDisplay() override {
        JsonObject data = config["modules"]["bitcoin"];
        float price = data["value"] | 0.0;
        float change = data["change24h"] | 0.0;

        char buffer[64];
        snprintf(buffer, sizeof(buffer), "$%.2f | %+.1f%%", price, change);
        return String(buffer);
    }
};
