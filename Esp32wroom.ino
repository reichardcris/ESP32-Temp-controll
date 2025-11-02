#include <WiFi.h>
#include <LiquidCrystal_I2C.h>

// WiFi credentials
const char* ssid = "Starlink";
const char* password = "rs150150";

// LCD setup
LiquidCrystal_I2C lcd(0x27, 16, 2);  // Common I2C address is 0x27 or 0x3F

WiFiServer server(80);
int counter = 0;

void setup() {
  Serial.begin(115200);

  // LCD init
  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("Connecting...");

  // WiFi connect
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\nConnected!");
  Serial.print("IP: ");
  Serial.println(WiFi.localIP());

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("WiFi Connected!");
  lcd.setCursor(0, 1);
  lcd.print(WiFi.localIP());

  delay(2000);
  lcd.clear();
  server.begin();
}

void loop() {
  WiFiClient client = server.available();
  if (client) {
    while (!client.available()) delay(1);
    String request = client.readStringUntil('\r');
    client.flush();

    if (request.indexOf("/inc") != -1) counter++;
    if (request.indexOf("/dec") != -1) counter--;
    if (counter < 0) counter = 0;
    if (counter > 9999) counter = 9999;

    // Update LCD
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Counter:");
    lcd.setCursor(0, 1);
    lcd.print(counter);

    // Create HTML interface
    String html = "<html><head><meta name='viewport' content='width=device-width, initial-scale=1'>";
    html += "<style>body{font-family:sans-serif;text-align:center;}button{font-size:40px;margin:20px;padding:10px 30px;}</style></head><body>";
    html += "<h1>ESP32 Counter</h1>";
    html += "<h2>" + String(counter) + "</h2>";
    html += "<button onclick=\"location.href='/inc'\"> + </button>";
    html += "<button onclick=\"location.href='/dec'\"> - </button>";
    html += "</body></html>";

    // Send to browser
    client.println("HTTP/1.1 200 OK");
    client.println("Content-type:text/html");
    client.println("Connection: close");
    client.println();
    client.println(html);
    client.stop();
  }
}
