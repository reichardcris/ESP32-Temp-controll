#include <WiFi.h>
#include <ESPmDNS.h>
#include <WebSocketsServer.h>
#include <IRremote.hpp>

// Hotspot credentials
const char* ssid = "ESP32-Hotspot";

WebSocketsServer webSocket = WebSocketsServer(8080);

void webSocketEvent(uint8_t num, WStype_t type, uint8_t * payload, size_t length) {
    switch(type) {
        case WStype_DISCONNECTED:
            Serial.printf("[%u] Disconnected!\n", num);
            break;
        case WStype_CONNECTED: {
            IPAddress ip = webSocket.remoteIP(num);
            Serial.printf("[%u] Connected from %d.%d.%d.%d url: %s\n", num, ip[0], ip[1], ip[2], ip[3], payload);
            webSocket.sendTXT(num, "Connected to ESP32 Hotspot");
        }
            break;
        case WStype_TEXT:
            Serial.printf("[%u] get Text: %s\n", num, payload);
            // Echo back the received message
            webSocket.sendTXT(num, payload);
            break;
    }
}

void setup() {
  Serial.begin(1152200);

  // Start ESP32 in Access Point mode
  WiFi.softAP(ssid);
  IPAddress myIP = WiFi.softAPIP();
  Serial.print("AP IP address: ");
  Serial.println(myIP);

  // Start mDNS with a unique hostname
  if (MDNS.begin("esp32-hotspot")) {
    Serial.println("MDNS responder started");
    // Advertise the WebSocket service
    MDNS.addService("_esp32ws", "_tcp", 8080);
    Serial.println("mDNS service added: _esp32ws._tcp.local");
  } else {
    Serial.println("Error setting up MDNS responder!");
  }

  // Start WebSocket server
  webSocket.begin();
  webSocket.onEvent(webSocketEvent);
  Serial.println("WebSocket server started");
}

void loop() {
  webSocket.loop();
}
