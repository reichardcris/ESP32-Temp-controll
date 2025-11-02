#include <WiFi.h>
#include <ESPmDNS.h>
#include <WebSocketsServer.h>
#include <IRremote.hpp>

// Hotspot credentials
const char* ssid = "ESP32-Hotspot";

const int IR_SEND_PIN = 4;

uint16_t rawDataOn[83] = {
  8950,4500,
  550,500, 550,550, 550,550, 550,1600,
  550,550, 550,500, 550,550, 550,550,
  550,500, 550,1650, 550,500, 550,1650,
  550,1600, 550,550, 550,500, 550,550,
  550,550, 550,500, 550,550, 550,1600,
  550,550, 550,550, 550,500, 550,550,
  550,550, 550,500, 550,550, 550,550,
  550,1600, 550,550, 500,550, 550,550,
  550,550, 500,550, 550,1650, 500,1650,
  550,550, 500,550, 550,550, 550,550,
  500
};

uint16_t rawDataOff[83] = {
  8950,4500,
  500,600, 500,550, 550,550, 500,600,
  500,550, 550,550, 500,600, 500,550,
  550,550, 500,1650, 550,1650, 500,1650,
  500,1650, 550,550, 500,550, 550,550,
  550,550, 500,550, 550,550, 550,1600,
  550,550, 500,600, 500,550, 550,550,
  500,600, 500,550, 550,550, 500,600,
  500,1650, 550,550, 500,550, 550,550,
  550,550, 500,550, 550,1650, 500,1650,
  500,550, 550,550, 550,550, 500,550,
  550
};

// This is the data for the "Down" key (Command 0x0D)
// Generated from the query data (0x08 0x1D 0x08 0x04 0x0C) by changing command to 0x0D
uint16_t rawDataDown[83] = {
  8900,4550,
  500,550, 550,550, 500,600, 500,1650,
  500,600, 500,550, 550,550, 500,550,
  550,550, 500,1650, 550,1650, 500,1650,
  500,1650, 550,550, 500,600, 500,550,
  550,550, 500,600, 450,600, 550,1650,
  500,550, 550,550, 500,600, 450,600,
  500,600, 500,600, 500,550, 500,600,
  500,1650, 500,600, 500,550, 550,550,
  500,600, 500,550, 550,1650, 500,1650,
  500,600, 500,550, 550,550, 500,600,
  500
};

// This is the data for the "Up" key
// Decoded from the new rawIRTimings provided
uint16_t rawDataUp[83] = {
  8950,4500,
  500,600, 500,550, 550,550, 500,1650,
  550,550, 500,600, 450,600, 550,550,
  500,600, 500,1650, 500,1650, 550,1650,
  500,1650, 500,600, 450,600, 550,550,
  500,600, 500,550, 500,600, 500,1650,
  500,600, 500,600, 500,550, 500,600,
  500,600, 500,550, 500,600, 500,550,
  550,1650, 500,550, 550,550, 500,600,
  500,550, 550,550, 500,1650, 550,1650,
  500,550, 550,550, 500,600, 500,550,
  550
};


WebSocketsServer webSocket = WebSocketsServer(8080);

void webSocketEvent(uint8_t num, WStype_t type, uint8_t * payload, size_t length) {
  Serial.println("WebSocket event received");
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
          if (strcmp((char*)payload, "temp_up") == 0) {
            Serial.println("Temperature up");
            sendCommand(rawDataUp, sizeof(rawDataUp) / sizeof(rawDataUp[0]));
          } else if (strcmp((char*)payload, "temp_down") == 0) {
            sendCommand(rawDataDown, sizeof(rawDataDown) / sizeof(rawDataDown[0]));
            Serial.println("Temperature down");
          } else if (strcmp((char*)payload, "power_on") == 0) {
            sendCommand(rawDataOn, sizeof(rawDataOn) / sizeof(rawDataOn[0]));
            Serial.println("Power on");
          } else if (strcmp((char*)payload, "power_off") == 0) {
            sendCommand(rawDataOff, sizeof(rawDataOff) / sizeof(rawDataOff[0]));
            Serial.println("Power off");
          }
          // Echo back the received message
          webSocket.sendTXT(num, (char*)payload);
          break;
  }
}

void setup() {
  Serial.begin(115200);

  IrSender.begin(IR_SEND_PIN);

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

void sendCommand(uint16_t data[], int size) {
  IrSender.sendRaw(data, size, 38);
}

void loop() {
  webSocket.loop();
}
