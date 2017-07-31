import paho.mqtt.client as paho
import os
import socket
import ssl
import RPi.GPIO as GPIO
import string
import Adafruit_DHT
from time import sleep
from random import uniform
import datetime
import ast
from pytz import timezone
import json
import atexit

DHT_PIN = 2
LIGHT_PIN = 3

# AWS credentials
awshost = "a3nxzzc72rdj05.iot.us-east-2.amazonaws.com"
awsport = 8883
clientId = "pi3"
thingName = "pi3"
caPath = "aws-iot-rootCA.crt"
certPath = "cert.pem"
keyPath = "privkey.pem"

# network settings
connflag = False
def on_connect(client, userdata, flags, rc):
    global connflag
    connflag = True
    print("Connection returned result: " + str(rc) )
    client.subscribe("led" , 1 )
    client.subscribe("profile", 1)
    client.subscribe("schedule", 1)
    client.subscribe("auto", 1)
    client.subscribe("changeLight", 1)
    client.subscribe("light_override", 1)
    client.subscribe("$aws/things/" + thingName + "/shadow/get/accepted")
    # client.subscribe("$aws/things/" + thingName + "/shadow/update/documents", 1)

def on_disconnect(client, userdata, rc):
    global connflag
    connflag = False
    print("DISCONNECTED")

def on_message(client, userdata, msg):
    global custom_light
    global light_override
    try:
        print("Topic: "+msg.topic)
        # if (msg.topic == "$aws/things/" + thingName + "/shadow/update/delta"):
            # do whatever and then send back an update
        if (msg.topic == "$aws/things/" + thingName + "/shadow/get/accepted"):
            resolveDeltas(json.loads(msg.payload))
            return
        print("Payload: "+str(msg.payload))
        payload = ast.literal_eval(msg.payload)
        if (msg.topic == "led"):
            ledToggle(payload)
        elif (msg.topic == "profile"):
            addProfile(payload)
        elif (msg.topic == "schedule"):
            changeSchedule(payload)
        elif (msg.topic == "auto"):
            setAuto(payload)
        elif (msg.topic == "changeLight"):
            changeCustomLight(payload)
        elif (msg.topic == "light_override"):
            light_override = payload
    except (ValueError, TypeError, SyntaxError, RuntimeError):
        print("Bad Message")

mqttc = paho.Client()
mqttc.on_connect = on_connect
mqttc.on_message = on_message

mqttc.tls_set(caPath, certfile=certPath, keyfile=keyPath, cert_reqs=ssl.CERT_REQUIRED, tls_version=ssl.PROTOCOL_TLSv1_2, ciphers=None)

mqttc.connect(awshost, awsport, keepalive=60)

mqttc.loop_start()

# initialize GPIO
GPIO.setwarnings(False)
GPIO.setmode(GPIO.BCM)
GPIO.cleanup()
GPIO.setup(LIGHT_PIN, GPIO.OUT)
GPIO.output(LIGHT_PIN, True)
while True:
	print("reading")
	humreading, tempreading = Adafruit_DHT.read_retry(Adafruit_DHT.DHT22, DHT_PIN)
	print(str(humreading))
	if connflag == True:
		mqttc.publish("testing",str(humreading) + "; " + str(tempreading),qos=1)
		print("msg sent: temperature  %.2f; humidity %.2f" % (tempreading, humreading))
