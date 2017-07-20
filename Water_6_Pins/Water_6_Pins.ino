const int trays = 6;
int TRAY_PINS[trays];
int VALVE_PINS[trays];
int MODE_PIN = A0;
int valves[trays];
int test_mode = 0;
int valve_open_time = 20; // in seconds
int valve_close_time = 18000; // in seconds
int open_timer[trays];
int close_timer[trays];

// 0.D3..1.TX..2.D4..3.RX
void setup()
{
  Serial.begin(9600);
  for (int i = 0; i < trays; i++) {
    TRAY_PINS[i] = i + 2;
    VALVE_PINS[i] = i + trays + 2;
    valves[i] = 0;
    open_timer[i] = 0;
    close_timer[i] = 0;
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
  for (int pin = 0; pin < trays; pin++) {
    if (open_timer[pin] > valve_open_time) {
      open_timer[pin] = 0;
      closeAndWait(pin);
    }
    else if (close_timer[pin] > valve_close_time) {
      close_timer[pin] = 0;
    }
    else if (open_timer[pin] > 0) {
      open_timer[pin]++;
    }
    else if (close_timer[pin] > 0) {
      open_timer[pin]++;
    }
    else {
      test_mode = digitalRead(MODE_PIN);
      if (test_mode != 0) {
        trayUpdate(pin);
      }
      else {
        trayUpdateLong(pin);
      }
    }
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

void trayUpdateLong(int pin) {
  // if there's no water in the system, open the valve and set the open timer
  int waterVal = digitalRead(TRAY_PINS[pin]);
  Serial.println("Tray " + String(pin) + " water val = " + String(waterVal));
  if (waterVal == 0) {
    digitalWrite(VALVE_PINS[pin], HIGH);
    open_timer[pin] = 1;
    valves[pin] = 1;
    Serial.println("Valve " + String(pin) + " opened");
    return;
  }
}

void closeAndWait(int pin) {
  // close valve and start close timer
  digitalWrite(VALVE_PINS[pin], LOW);
  close_timer[pin] = 1;
  valves[pin] = 0;
  Serial.println("Valve " + String(pin) + " closed");
}
