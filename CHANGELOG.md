# Changelog

All notable changes to the ESP32-C3 Data Tracker project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-01-15

### Added
- Initial release of ESP32-C3 Data Tracker firmware
- Support for SH1106 OLED display (128×64, I2C)
- Five metric modules:
  - Bitcoin price (CoinGecko API)
  - Ethereum price (CoinGecko API)
  - Stock prices (Yahoo Finance API)
  - Weather data (Open-Meteo API)
  - Custom numeric values (manual entry)
- Captive portal for WiFi and module configuration
- Smart caching with automatic retry and exponential backoff
- Rate limiting to prevent API abuse
- Optional button support for metric cycling
- Serial console commands for debugging and control
- Comprehensive documentation (README, USAGE, TROUBLESHOOTING, BUILD guides)
- LittleFS-based configuration storage
- Automatic WiFi reconnection
- Stale data indicators on display

### Features
- **Display System**
  - Dynamic module-specific layouts
  - Status indicators (WiFi, update time, stale data)
  - UTF-8 support for special characters
  - Splash screen on boot

- **Network Layer**
  - HTTPS support for all APIs
  - Automatic WiFi reconnection
  - DNS-based captive portal
  - Responsive web interface for configuration

- **Scheduler**
  - Global rate limiting (10s minimum between fetches)
  - Per-module rate limiting
  - Exponential backoff on failures (60s → 3600s max)
  - Configurable refresh intervals

- **Button Controls**
  - Short press: Cycle modules
  - Long press: Enter config mode
  - Very long press: Factory reset

- **Serial Console**
  - Real-time debugging
  - Manual fetch triggering
  - Configuration viewing/editing
  - Cache inspection

### Technical Details
- Platform: ESP32-C3 (ESP-IDF via Arduino framework)
- Display Driver: U8g2
- JSON Parsing: ArduinoJson v6
- Web Server: ESPAsyncWebServer
- Filesystem: LittleFS
- Memory Usage: ~50KB RAM, ~1.2MB Flash

### Known Limitations
- Single metric display (no multi-panel view)
- No historical data/graphs
- HTTPS certificate validation disabled
- No OTA updates
- Stock prices only during market hours
- No deep sleep mode (continuous USB power required)

---

## [Unreleased]

### Planned for v1.1.0
- [ ] Deep sleep mode for battery operation
- [ ] Battery voltage monitoring
- [ ] Configurable timezone support
- [ ] Additional crypto currencies (Cardano, Solana, etc.)
- [ ] Home Assistant MQTT integration

### Planned for v1.2.0
- [ ] OTA firmware updates via web interface
- [ ] Web dashboard for viewing historical data
- [ ] Alerts/notifications for threshold crossing
- [ ] Email notifications via SMTP

### Planned for v2.0.0
- [ ] BLE configuration (alternative to WiFi AP)
- [ ] Mobile app for remote configuration
- [ ] Multi-display support (show multiple metrics)
- [ ] E-ink display support
- [ ] Historical data graphs on display

### Under Consideration
- [ ] Support for SSD1306 displays
- [ ] Support for larger displays (e.g., 128×128, 256×64)
- [ ] Voice output via I2S speaker
- [ ] IR remote control support
- [ ] RGB LED status indicators
- [ ] Buzzer/speaker for alerts

---

## Version History

### [1.0.0] - 2024-01-15
- Initial public release

---

## Upgrade Notes

### Upgrading to v1.0.0
First release - no upgrade path needed.

Future upgrade instructions will be added here.

---

## Breaking Changes

None yet - this is the first release.

Future breaking changes will be documented here with migration guides.

---

## Deprecation Warnings

None yet.

---

## Security Fixes

None yet.

Security vulnerabilities will be documented here with severity ratings.

---

## Contributors

- **Lead Developer**: [Your Name]
- **Contributors**: See [CONTRIBUTORS.md](CONTRIBUTORS.md)

---

## Links

- [GitHub Repository](https://github.com/yourusername/DataTracker)
- [Issue Tracker](https://github.com/yourusername/DataTracker/issues)
- [Discussions](https://github.com/yourusername/DataTracker/discussions)
- [Releases](https://github.com/yourusername/DataTracker/releases)

---

**Note**: This project follows semantic versioning. For details on version numbering, see [semver.org](https://semver.org/).
