#include <WiFi.h>
#include <ESPmDNS.h>
#include <WebSocketsServer.h>
#include <IRremote.hpp>
#include <LiquidCrystal_I2C.h>

// Hotspot credentials
const char* ssid = "ESP32-Hotspot";

// LCD display settings
LiquidCrystal_I2C lcd(0x27, 16, 2);

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

// This is the data for the "Low" setting
uint16_t rawDataLow[83] = {
  8900,4550,
  450,600, 500,600, 500,600, 500,1650,
  500,600, 450,600, 550,550, 500,600,
  450,1700, 500,1650, 500,1700, 500,1650,
  500,1650, 550,550, 500,600, 450,600,
  500,600, 500,600, 500,550, 500,1700,
  450,650, 500,600, 450,600, 500,600,
  500,550, 500,600, 500,600, 450,600,
  500,1700, 500,600, 450,600, 500,600,
  500,600, 450,600, 500,1650, 500,1700,
  500,550, 550,550, 500,600, 500,550,
  550
};

// This is the data for the "Medium" setting
uint16_t rawDataMedium[83] = {
  8950,4500,
  500,550, 550,550, 500,600, 500,1650,
  500,600, 500,600, 500,550, 500,600,
  500,1650, 550,1650, 500,550, 550,1650,
  500,1650, 500,600, 500,550, 550,550,
  500,600, 500,550, 550,550, 500,1650,
  550,550, 500,600, 500,550, 550,550,
  500,600, 500,550, 550,550, 500,600,
  500,1650, 500,600, 500,550, 550,550,
  500,600, 500,550, 550,1650, 500,1650,
  500,550, 550,550, 500,600, 500,550,
  550
};

// This is the data for the "High" setting
uint16_t rawDataHigh[83] = {
  8950,4500,
  500,600, 500,600, 450,600, 500,1700,
  450,600, 500,600, 500,600, 500,550,
  550,1650, 500,550, 550,550, 500,600,
  500,1650, 500,600, 500,550, 550,550,
  500,600, 500,550, 550,550, 500,1650,
  550,550, 500,600, 500,550, 550,550,
  500,600, 500,550, 500,600, 500,600,
  500,1650, 500,600, 500,600, 500,550,
  500,600, 500,600, 500,1650, 500,1650,
  500,550, 550,550, 500,600, 500,550,
  550
};


WebSocketsServer webSocket = WebSocketsServer(8080);

void webSocketEvent(uint8_t num, WStype_t type, uint8_t * payload, size_t length) {
  Serial.println("WebSocket event received");
  switch(type) {
    case WStype_DISCONNECTED:
        Serial.printf("[%u] Disconnected!\n", num);
        lcd.setCursor(0, 1);
        lcd.print("Device disconnected");
        break;
    case WStype_CONNECTED: {
        IPAddress ip = webSocket.remoteIP(num);
        lcd.setCursor(0, 1);
        lcd.print("Device connected");
        Serial.printf("[%u] Connected from %d.%d.%d.%d url: %s\n", num, ip[0], ip[1], ip[2], ip[3], payload);
        webSocket.sendTXT(num, "Connected to ESP32 Hotspot");
    }
        break;
    case WStype_TEXT:
      Serial.printf("[%u] get Text: %s\n", num, payload);
      if (strcmp((char*)payload, "on") == 0) {
        lcd.setCursor(0, 1);
        lcd.print("Power ON        ");
        Serial.println("Power on");
        sendCommand(rawDataOn, sizeof(rawDataOn) / sizeof(rawDataOn[0]));
      } else if (strcmp((char*)payload, "off") == 0) {
        lcd.setCursor(0, 1);
        lcd.print("Power OFF       ");
        Serial.println("Power off");
        sendCommand(rawDataOff, sizeof(rawDataOff) / sizeof(rawDataOff[0]));
      } else if (strcmp((char*)payload, "temp_low") == 0) {
        lcd.setCursor(0, 1);
        lcd.print("Temp set to Low ");
        Serial.println("Low setting");
        sendCommand(rawDataLow, sizeof(rawDataLow) / sizeof(rawDataLow[0]));
      } else if (strcmp((char*)payload, "temp_medium") == 0) {
        Serial.println("Medium setting");
        lcd.setCursor(0, 1);
        lcd.print("Temp set to Med ");
        sendCommand(rawDataMedium, sizeof(rawDataMedium) / sizeof(rawDataMedium[0]));
      } else if (strcmp((char*)payload, "temp_high_freeze") == 0) {
        Serial.println("High setting");
        lcd.setCursor(0, 1);
        lcd.print("Temp set to High");
        sendCommand(rawDataHigh, sizeof(rawDataHigh) / sizeof(rawDataHigh[0]));
      }
      // Echo back the received message
      webSocket.sendTXT(num, (char*)payload);
      break;
  }
}

void setup() {
  Serial.begin(115200);

  IrSender.begin(IR_SEND_PIN);


    // LCD init
    lcd.init();
    lcd.backlight();
    lcd.setCursor(0, 0);
    lcd.print("ESP32 Hotspot");


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
