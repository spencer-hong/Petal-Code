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
#include <DHT.h>

// Go to the Project Settings (nut icon).
char auth[] = "c9b58dd1fda24f1f9de659987ead6893";

char ssid[] = "116.5 Heights Court";
char pass[] = "courtcourtheights";

#define DHTPIN 2          // What digital pin we're connected to
#define LED_PIN 15
#define HEAT_PIN 12
#define FAN_PIN 13
#define DHTTYPE DHT22   // DHT 22, AM2302, AM2321

int customTemp;
int customLight;
int mode;     // 0 = custom, 1 = day, 2 = night

int dayTemp = 21;
int nightTemp = 19;
int buffer = 1;
int tempArray[3] = {dayTemp, dayTemp, nightTemp};

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
    return;
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
  Blynk.virtualWrite(V7, tempArray[mode]);
  
  // You can send any value at any time.
  // Please don't send more that 10 values per second.
  Blynk.virtualWrite(V5, h);
  Blynk.virtualWrite(V6, t);
  Serial.print("Humidity: ");
  Serial.println(h);
  Serial.print("Temperature: ");
  Serial.println(t);
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

  dht.begin();

  // Setup a function to be called every second
  timer.setInterval(500L, sendSensor);
}

BLYNK_WRITE(2)
{
   customLight = param.asInt();
   Serial.print("V1 Slider value is:");
   Serial.print(customLight);
   if (mode == 0) {
      analogWrite(LED_PIN, customLight); 
   }
}

BLYNK_WRITE(3)
{
   tempArray[0] = param.asInt();
}

BLYNK_WRITE(1)
{
   if (param.asInt() == 0) {
      mode = 0;
      analogWrite(LED_PIN, customLight);
   }
   else if (param.asInt() == 1) {
      mode = 1;
      analogWrite(LED_PIN, 1023);
   }
   else if (param.asInt() == 2) {
      mode = 2;
      analogWrite(LED_PIN, 0);
   }
}

void loop()
{
  Blynk.run();
  timer.run(); // Initiates SimpleTimer
}
