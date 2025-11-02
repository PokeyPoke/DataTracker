#include "network.h"
#include "config.h"

// Minimal HTML for configuration (ultra-compact)
const char PORTAL_HTML[] PROGMEM = R"rawliteral(<!DOCTYPE html>
<html><head><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Setup</title><style>body{font-family:Arial;margin:20px}input,select{width:100%;padding:8px;margin:5px 0}
button{background:#4CAF50;color:#fff;padding:12px;border:none;width:100%;margin-top:15px}</style></head>
<body><h2>DataTracker Setup</h2><label>WiFi:</label><select id="ssid"></select>
<label>Password:</label><input type="password" id="pwd"><label>Module:</label>
<select id="mod"><option value="bitcoin">Bitcoin</option><option value="ethereum">Ethereum</option>
<option value="stock">Stock</option><option value="weather">Weather</option></select>
<div id="cfg"></div><button onclick="save()">Save</button><script>
function save(){var c={ssid:document.getElementById('ssid').value,password:document.getElementById('pwd').value,
module:document.getElementById('mod').value};fetch('/save',{method:'POST',body:JSON.stringify(c)}).then(()=>alert('Saved!'));}
fetch('/scan').then(r=>r.json()).then(n=>{var s=document.getElementById('ssid');n.forEach(x=>s.innerHTML+=
'<option value="'+x.ssid+'">'+x.ssid+'</option>')});
</script></body></html>)rawliteral";

NetworkManager::NetworkManager()
    : server(nullptr), isAPMode(false), lastReconnectAttempt(0),
      cachedScanResults("[]"), lastScanTime(0), scanInProgress(false) {
}

NetworkManager::~NetworkManager() {
    if (server) delete server;
}

bool NetworkManager::connectWiFi(const char* ssid, const char* password, uint16_t timeout) {
    Serial.print("Connecting to WiFi: ");
    Serial.println(ssid);

    WiFi.mode(WIFI_STA);
    WiFi.begin(ssid, password);

    unsigned long startTime = millis();
    while (WiFi.status() != WL_CONNECTED && (millis() - startTime) < timeout) {
        delay(500);
        Serial.print(".");
    }
    Serial.println();

    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("WiFi connected!");
        Serial.print("IP: ");
        Serial.println(WiFi.localIP());
        isAPMode = false;
        return true;
    } else {
        Serial.println("WiFi connection failed");
        return false;
    }
}

void NetworkManager::startConfigAP() {
    // Generate AP name
    uint8_t mac[6];
    WiFi.macAddress(mac);
    char macStr[5];
    snprintf(macStr, sizeof(macStr), "%02X%02X", mac[4], mac[5]);
    apName = "DataTracker-" + String(macStr);

    Serial.print("Starting AP: ");
    Serial.println(apName);

    WiFi.mode(WIFI_AP);
    WiFi.softAP(apName.c_str());

    IPAddress IP = WiFi.softAPIP();
    Serial.print("AP IP: ");
    Serial.println(IP);

    delay(1000);

    // Switch to AP+STA for scanning
    WiFi.mode(WIFI_AP_STA);

    // Setup web server
    setupWebServer();

    cachedScanResults = "[]";
    scanInProgress = false;
    lastScanTime = millis();

    Serial.println("AP ready. Connect and go to 192.168.4.1");

    isAPMode = true;
}

void NetworkManager::setupWebServer() {
    server = new WebServer(80);

    // Root page
    server->on("/", [this]() {
        server->send_P(200, "text/html", PORTAL_HTML);
    });

    // Scan endpoint
    server->on("/scan", [this]() {
        handleScan();
    });

    // Save endpoint
    server->on("/save", HTTP_POST, [this]() {
        handleSave();
    });

    server->begin();
    Serial.println("Web server started");
}

void NetworkManager::handleScan() {
    server->sendHeader("Access-Control-Allow-Origin", "*");
    server->send(200, "application/json", cachedScanResults);
}

void NetworkManager::handleSave() {
    if (server->hasArg("plain")) {
        String body = server->arg("plain");

        StaticJsonDocument<512> doc;
        DeserializationError error = deserializeJson(doc, body);

        if (!error) {
            config["wifi"]["ssid"] = doc["ssid"].as<String>();
            config["wifi"]["password"] = doc["password"].as<String>();
            config["device"]["activeModule"] = doc["module"].as<String>();

            saveConfiguration();

            server->send(200, "text/plain", "OK");

            delay(1000);
            ESP.restart();
        } else {
            server->send(400, "text/plain", "Invalid JSON");
        }
    } else {
        server->send(400, "text/plain", "No data");
    }
}

void NetworkManager::stopConfigAP() {
    if (server) {
        delete server;
        server = nullptr;
    }
    WiFi.softAPdisconnect(true);
    isAPMode = false;
}

bool NetworkManager::isConnected() {
    return WiFi.status() == WL_CONNECTED;
}

void NetworkManager::reconnect() {
    if (isAPMode) return;

    unsigned long now = millis();
    if (now - lastReconnectAttempt < 30000) return;

    lastReconnectAttempt = now;

    String ssid = config["wifi"]["ssid"] | "";
    String password = config["wifi"]["password"] | "";

    if (ssid.length() == 0) return;

    Serial.println("Reconnecting to WiFi...");
    WiFi.disconnect();
    WiFi.begin(ssid.c_str(), password.c_str());
}

void NetworkManager::handleClient() {
    if (server) {
        server->handleClient();
    }

    if (isAPMode) {
        updateScanResults();
    }
}

bool NetworkManager::httpGet(const char* url, String& response, String& errorMsg) {
    WiFiClientSecure* client = new WiFiClientSecure;
    if (!client) {
        errorMsg = "Out of memory";
        return false;
    }

    client->setInsecure();

    HTTPClient https;
    https.begin(*client, url);
    https.setTimeout(15000);

    int httpCode = https.GET();

    if (httpCode == HTTP_CODE_OK) {
        response = https.getString();
        https.end();
        delete client;
        return true;
    } else {
        errorMsg = "HTTP " + String(httpCode);
        https.end();
        delete client;
        return false;
    }
}

void NetworkManager::startWiFiScan() {
    Serial.println("Starting WiFi scan...");

    if (WiFi.getMode() != WIFI_AP_STA) {
        WiFi.mode(WIFI_AP_STA);
        delay(500);
    }

    WiFi.setTxPower(WIFI_POWER_19_5dBm);

    // Increased to 500ms per channel for more reliable scanning
    int result = WiFi.scanNetworks(true, false, false, 500);

    if (result == WIFI_SCAN_RUNNING) {
        scanInProgress = true;
        lastScanTime = millis();
        Serial.println("Scan started");
    } else {
        Serial.println("Scan failed to start");
    }
}

void NetworkManager::updateScanResults() {
    if (!scanInProgress) {
        unsigned long timeSinceLastScan = millis() - lastScanTime;
        // Wait 10 seconds after boot for WiFi to stabilize, then rescan every 30 seconds
        if ((lastScanTime < 10000 && millis() > 10000) || timeSinceLastScan > 30000) {
            startWiFiScan();
        }
        return;
    }

    int n = WiFi.scanComplete();

    if (n == WIFI_SCAN_RUNNING) {
        unsigned long scanDuration = millis() - lastScanTime;
        if (scanDuration > 15000) {
            Serial.println("Scan timeout");
            WiFi.scanDelete();
            cachedScanResults = "[]";
            scanInProgress = false;
        }
        return;
    }

    if (n == WIFI_SCAN_FAILED) {
        Serial.println("Scan failed");
        cachedScanResults = "[]";
        scanInProgress = false;
        WiFi.scanDelete();
        return;
    }

    if (n >= 0) {
        Serial.print("Found ");
        Serial.print(n);
        Serial.println(" networks");

        String json = "[";
        for (int i = 0; i < n && i < 20; i++) {
            if (i > 0) json += ",";
            String ssid = WiFi.SSID(i);
            ssid.replace("\"", "\\\"");
            json += "{\"ssid\":\"" + ssid + "\",";
            json += "\"rssi\":" + String(WiFi.RSSI(i)) + "}";
        }
        json += "]";

        cachedScanResults = json;
        scanInProgress = false;
        lastScanTime = millis();

        Serial.println("Scan complete");
        WiFi.scanDelete();
    }
}
