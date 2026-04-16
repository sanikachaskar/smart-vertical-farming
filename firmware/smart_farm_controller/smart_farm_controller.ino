/* Smart Vertical Farming System - Arduino Firmware */ 
#include <DHT.h> 
#define DHTPIN 2 
#define SOIL_PIN A0 
#define PUMP_RELAY 4 
#define LED_RELAY 5 
#define FAN_RELAY 6 
#define DHTTYPE DHT22 
DHT dht(DHTPIN, DHTTYPE); 
void setup() { Serial.begin(115200); dht.begin(); pinMode(PUMP_RELAY, OUTPUT); pinMode(LED_RELAY, OUTPUT); pinMode(FAN_RELAY, OUTPUT); } 
void loop() { float t = dht.readTemperature(); float h = dht.readHumidity(); int s = analogRead(SOIL_PIN); Serial.print(t); Serial.print(","); Serial.print(h); Serial.print(","); Serial.println(s); delay(2000); } 
