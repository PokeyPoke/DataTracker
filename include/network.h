#ifndef NETWORK_H
#define NETWORK_H

#include <Arduino.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <WebServer.h>

class NetworkManager {
private:
    WebServer* server;
    String apName;
    bool isAPMode;
    unsigned long lastReconnectAttempt;

    // WiFi scan caching
    String cachedScanResults;
    unsigned long lastScanTime;
    bool scanInProgress;

    // Web server handlers
    void setupWebServer();
    void handleRoot();
    void handleScan();
    void handleSave();

    // WiFi scanning
    void startWiFiScan();
    void updateScanResults();

public:
    NetworkManager();
    ~NetworkManager();

    // WiFi management
    bool connectWiFi(const char* ssid, const char* password, uint16_t timeout = 15000);
    void startConfigAP();
    void stopConfigAP();
    bool isConnected();
    void reconnect();

    // HTTP requests
    bool httpGet(const char* url, String& response, String& errorMsg);

    // Accessors
    String getAPName() { return apName; }
    bool isInAPMode() { return isAPMode; }

    // Server handling
    void handleClient();
};

#endif // NETWORK_H
