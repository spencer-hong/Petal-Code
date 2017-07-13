const int trays = 6;
int TRAY_PINS[trays];
int VALVE_PINS[trays];
int valves[trays];

// 0.D3..1.TX..2.D4..3.RX
void setup()
{
  Serial.begin(9600);
  for (int i = 0; i < trays; i++) {
  TRAY_PINS[i] = i + 2;
  VALVE_PINS[i] = i + trays + 2;
  valves[i] = 0;
  Serial.println(TRAY_PINS[i]);
  Serial.println(VALVE_PINS[i]);
  }
  
  for (int i = 0; i < trays; i++) {
    pinMode(TRAY_PINS[i], INPUT);
    pinMode(VALVE_PINS[i], OUTPUT);
  }
}

void loop() {
  delay(1000);
  for (int i = 0; i < trays; i++) {
    trayUpdate(i);
  }
}

void trayUpdate(int pin) {
  int waterVal = digitalRead(TRAY_PINS[pin]);
  Serial.println("Tray " + String(pin) + " water val = " + String(waterVal));
  if (waterVal == 0) {
    digitalWrite(VALVE_PINS[pin], HIGH);
    valves[pin] = 1;
    Serial.println("Valve " + String(pin) + " opened");
    return;
  }
  // If waterval > 0 and the valve is currently open
  if (valves[pin] == 1) {
    digitalWrite(VALVE_PINS[pin], LOW);
    valves[pin] = 0;
    Serial.println("Valve " + String(pin) + " closed");
  }
}

