/*************************************************************
  Blynk is a platform with iOS and Android apps to control
  Arduino, Raspberry Pi and the likes over the Internet.
  You can easily build graphic interfaces for all your
  projects by simply dragging and dropping widgets.
    Downloads, docs, tutorials: http://www.blynk.cc
    Blynk community:            http://community.blynk.cc
    Social networks:            http://www.fb.com/blynkapp
                                http://twitter.com/blynk_app
  Blynk library is licensed under MIT license
  This example code is in public domain.
 *************************************************************
  This example shows how value can be pushed from Arduino to
  the Blynk App.
  WARNING :
  For this example you'll need SimpleTimer library:
    https://github.com/jfturcot/SimpleTimer
  and Adafruit DHT sensor libraries:
    https://github.com/adafruit/Adafruit_Sensor
    https://github.com/adafruit/DHT-sensor-library
  App project setup:
    Value Display widget attached to V5
    Value Display widget attached to V6
 *************************************************************/

/* Comment this out to disable prints and save space */
#define BLYNK_PRINT Serial

#include <ESP8266WiFi.h>
#include <BlynkSimpleEsp8266.h>
#include <SimpleTimer.h>
#include <TimeLib.h>
#include <WidgetRTC.h>
#include <DHT.h>

WidgetRTC rtc;

// Go to the Project Settings (nut icon).
char auth[] = "989e37df439141cc9fcfe2dbde95cee8";

char ssid[] = "Rev Member";
char pass[] = "incubator";

#define DHTPIN 2  // D4
#define LED_PIN 15  // D8
#define BLUE_PIN 13 // D7
#define HEAT_PIN 5  // D1
#define FAN_PIN 12  // D6
#define WATER_TRAY 4  // D2
#define WATER_ADD 0 // D3
#define RESERVOIR A0
#define DHTTYPE DHT11
#define WATER_ADD_LED 14 // D5

// V1 - mode
// V2 - auto
// V3 - customTemp
// V4 - customLight
// V5 - customBlue
// V6 - currentHumidity
// V7 - currentTemp
// V8 - target temp
// V9 - day timer
// V10 - germination start
// V11 - germination end
// V14 - reservoir level (RESERVOIR)
// V15 - water tray (current pins)
// V16 - water addition (current pins)

int customTemp;
int customLight;
int customBlue;
int mode;     // 0 = custom, 1 = day, 2 = night, 3 = germinate
int automate;
int timerMode; // the mode the timer wants you to have

int lastWaterAdd = 0; // if the water was being added in the last loop
int reservoirVal = 0;
int sensorValue = 0;

int nightHour;
int nightMin;
int dayHour;
int dayMin;
int germinationEnd;
int germinationStart;

int dayTemp = 24;
int nightTemp = 19;
int germTemp = 21;
int buffer = 1;
int tempArray[4] = {dayTemp, dayTemp, nightTemp, germTemp};

DHT dht(DHTPIN, DHTTYPE);
SimpleTimer timer;

// This function sends Arduino's up time every second to Virtual Pin (5).
// In the app, Widget's reading frequency should be set to PUSH. This means
// that you define how often to send data to Blynk App.
void sendSensor()
{
  float h = dht.readHumidity();
  float t = dht.readTemperature(); // or dht.readTemperature(true) for Fahrenheit

  if (isnan(h) || isnan(t)) {
    Serial.println("Failed to read from DHT sensor!");
    //return;
  }

  if (t < tempArray[mode] - buffer) {
    digitalWrite(HEAT_PIN, HIGH);
    digitalWrite(FAN_PIN, LOW);
  }
  else if (t > tempArray[mode] + buffer) {
    digitalWrite(HEAT_PIN, LOW);
    digitalWrite(FAN_PIN, HIGH);
  }
  else if (t < tempArray[mode] + 0.2 && t > tempArray[mode] - 0.2) {
    digitalWrite(HEAT_PIN, LOW);
    digitalWrite(FAN_PIN, LOW);
  }
  Blynk.virtualWrite(V8, tempArray[mode]);

  // You can send any value at any time.
  // Please don't send more that 10 values per second.
  Blynk.virtualWrite(V6, h);
  Blynk.virtualWrite(V7, t);
}

void updateTime() {
  int hr = hour();
  int min = minute();
  int d = day();
  if ((germinationEnd > germinationStart) && (d >= germinationStart && d < germinationEnd)) {
    timerMode = 3;
  }
  else if ((germinationEnd < germinationStart) && !(d >= germinationEnd && d < germinationStart)) {
    timerMode = 3;
  }
  else if (nightHour > dayHour) {
    if (hr >= dayHour && hr < nightHour) {
      timerMode = 1;
    }
    else if (hr == nightHour && min < nightMin) {
      timerMode = 1;
    }
    else timerMode = 2;
  }
  else if (dayHour > nightHour) {
    if (hr >= nightHour && hr < dayHour) {
      timerMode = 2;
    }
    else if (hr == dayHour && min < dayMin) {
      timerMode = 2;
    }
    else timerMode = 1;
  }
  else if (nightMin > dayMin) {
    if (min >= dayMin && min < nightMin) {
      timerMode = 1;
    }
    else timerMode = 2;
  }
  else {
    if (min >= nightMin && min < dayMin) {
      timerMode = 2;
    }
    else timerMode = 1;
  }
  if (automate == 1) {
    if (mode != timerMode) {
      mode = timerMode;
      modeUpdate();
    }
  }
}

void lightUpdate() {
  if (mode == 0) {
    analogWrite(LED_PIN, customLight);
    analogWrite(BLUE_PIN, customBlue);
  }
  else if (mode == 1) {
    analogWrite(LED_PIN, 1023);
    analogWrite(BLUE_PIN, 1023);
  }
  else if (mode == 2) {
    analogWrite(LED_PIN, 0);
    analogWrite(BLUE_PIN, 0);
  }
  else if (mode == 3) {
    analogWrite(LED_PIN, 0);
    analogWrite(BLUE_PIN, 1023);
  }
}

void modeUpdate() {
  lightUpdate();
  Blynk.virtualWrite(V1, mode);
}

void reservoirUpdate() {
  sensorValue = analogRead(RESERVOIR);
  reservoirVal = map(sensorValue, 0, 1023, 0, 500);
  Blynk.virtualWrite(V14, reservoirVal);

  // print the results to the serial monitor:
  Serial.print("pressure sensor = ");
  Serial.print(sensorValue);
  Serial.print("\n ");
  Serial.print("voltage = ");
  Serial.print(reservoirVal);
  Serial.print("\n ");
}

void trayUpdate() {
  int waterVal = digitalRead(WATER_TRAY);
  Blynk.virtualWrite(V15, waterVal);
}


void waterAdd() {
  int waterAddAnalog = 0;
  int waterAddDigital = digitalRead(WATER_ADD);
  if (waterAddDigital == 1) {
    if (lastWaterAdd == 0) {
      // started adding water
      waterAddAnalog = 1024;
    }
    else {
      // continued adding water
      waterAddAnalog = reservoirVal;
    }
  }
  // if we stopped adding water (i.e. waterAdd == 0 && lastWaterAdd == 1) then waterAddAnalog will still be 0
  lastWaterAdd = waterAddDigital;
  Blynk.virtualWrite(V16, waterAddAnalog);
  int temp = map(waterAddAnalog, 0, 500, 0, 1024);
  analogWrite(WATER_ADD_LED, waterAddAnalog);
}

void setup()
{
  // Debug console
  Serial.begin(9600);

  Blynk.begin(auth, ssid, pass);
  // You can also specify server:
  //Blynk.begin(auth, ssid, pass, "blynk-cloud.com", 8442);
  //Blynk.begin(auth, ssid, pass, IPAddress(192,168,1,100), 8442);

  pinMode(LED_PIN, OUTPUT);
  pinMode(HEAT_PIN, OUTPUT);
  pinMode(FAN_PIN, OUTPUT);
  pinMode(BLUE_PIN, OUTPUT);
  pinMode(RESERVOIR, INPUT);
  pinMode(WATER_TRAY, INPUT);
  pinMode(WATER_ADD, INPUT);

  dht.begin();
  rtc.begin();

  // Setup a function to be called every second
  timer.setInterval(500L, sendSensor);
  timer.setInterval(500L, updateTime);
  timer.setInterval(500L, lightUpdate);
  timer.setInterval(500L, reservoirUpdate);
  timer.setInterval(500L, trayUpdate);
  timer.setInterval(500L, waterAdd);
}

BLYNK_WRITE(1) {
  mode = param.asInt();
  if (automate == 1 && (mode != timerMode)) {
    mode = timerMode;
  }
  modeUpdate();
}

BLYNK_WRITE(2) {
  automate = param.asInt();
  if (automate == 1) {
    updateTime();
    mode = timerMode;
    modeUpdate();
  }
}

BLYNK_WRITE(3) {
  tempArray[0] = param.asInt();
}

BLYNK_WRITE(4) {
  customLight = param.asInt();
}
BLYNK_WRITE(5) {
  customBlue = param.asInt();
}

BLYNK_WRITE(9) {
  TimeInputParam t(param);
  dayHour = t.getStartHour();
  dayMin = t.getStartMinute();
  nightHour = t.getStopHour();
  nightMin = t.getStopMinute();
  updateTime();
}

BLYNK_WRITE(10) {
  germinationStart = param.asInt();
  updateTime();
}

BLYNK_WRITE(11) {
  germinationEnd = param.asInt();
  updateTime();
}

void loop()
{
  Blynk.run();
  timer.run(); // Initiates SimpleTimer 
}

