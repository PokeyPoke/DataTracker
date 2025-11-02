#include "module_interface.h"
#include "config.h"
#include "network.h"
#include <ArduinoJson.h>

extern NetworkManager network;

class EthereumModule : public ModuleInterface {
public:
    EthereumModule() {
        id = "ethereum";
        displayName = "ETH/USD";
        defaultRefreshInterval = 300;  // 5 minutes
        minRefreshInterval = 60;       // 1 minute
    }

    bool fetch(String& errorMsg) override {
        const char* url = "https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd&include_24hr_change=true";

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

        if (!doc.containsKey("ethereum")) {
            errorMsg = "Invalid response structure";
            return false;
        }

        float price = doc["ethereum"]["usd"];
        float change = doc["ethereum"]["usd_24h_change"];

        // Update cache
        JsonObject data = config["modules"]["ethereum"].to<JsonObject>();
        data["value"] = price;
        data["change24h"] = change;
        data["lastUpdate"] = millis() / 1000;
        data["lastSuccess"] = true;

        Serial.print("Ethereum price: $");
        Serial.print(price, 2);
        Serial.print(" (");
        Serial.print(change, 2);
        Serial.println("%)");

        return true;
    }

    String formatDisplay() override {
        JsonObject data = config["modules"]["ethereum"];
        float price = data["value"] | 0.0;
        float change = data["change24h"] | 0.0;

        char buffer[64];
        snprintf(buffer, sizeof(buffer), "$%.2f | %+.1f%%", price, change);
        return String(buffer);
    }
};
