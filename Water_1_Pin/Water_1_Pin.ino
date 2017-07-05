#include <ESP8266WiFi.h>

#define WATER_TRAY 4  // D2
#define VALVE_PIN 0 // D3
int valve = 0;

void setup()
{
  Serial.begin(9600);
  pinMode(WATER_TRAY, INPUT);
  pinMode(VALVE_PIN, OUTPUT);
}

void loop() {
  delay(1000);
  int waterVal = analogRead(WATER_TRAY);
  Serial.println("water val = " + String(waterVal));
  if (waterVal == 0) {
    digitalWrite(VALVE_PIN, HIGH);
    valve = 1;
    Serial.println("valve opened");
    return;
  }
  // If waterval > 0 and the valve is currently open
  if (valve == 1) {
    digitalWrite(VALVE_PIN, LOW);
    valve = 0;
    Serial.println("valve closed");
  }
}
