#define sensor A0 
#define LED 0 //d3

int val = 0;

void setup() {
  // put your setup code here, to run once:
  pinMode(sensor,INPUT);
  pinMode(LED,OUTPUT);
  Serial.begin(9600);
}

void loop() {
  // put your main code here, to run repeatedly:
  val = analogRead(sensor);
  analogWrite(val/4)
  Serial.println(String(val));
  delay(200);
}
