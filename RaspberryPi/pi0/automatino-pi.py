# Automatino-Pi
# Created by: Bhai Jaiveer Singh
# First implementation of the automated petal box using AWS and RaspberryPi
# This program will publish and subscribe mqtt messages using the AWS IoT hub as a broker

import paho.mqtt.client as paho
import os
import socket
# TODO: CHANGE THIS to ssl
import backports.ssl as ssl
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

# AWS credentials
awshost = "a12szm1anpuc6o.iot.us-east-2.amazonaws.com"
awsport = 8883
clientId = "pi0"
thingName = "pi0"
caPath = "aws-iot-rootCA.crt"
certPath = "cert.pem"
keyPath = "privkey.pem"

timer = 0

# output pins
light_pin = 3
fan_pin = 15
heat_pin = 18
blue_pin = 23
# input pins
DHT_PIN = 2

# initialize GPIO
GPIO.setwarnings(False)
GPIO.setmode(GPIO.BCM)
GPIO.cleanup()
GPIO.setup(light_pin, GPIO.OUT)
GPIO.setup(fan_pin, GPIO.OUT)
GPIO.setup(heat_pin, GPIO.OUT)
GPIO.setup(blue_pin, GPIO.OUT)

# initialize pwm
light_pwm = GPIO.PWM(light_pin, 500)
light_pwm.start(50)
fan_pwm = GPIO.PWM(fan_pin, 500)
fan_pwm.start(50)
heat_pwm = GPIO.PWM(heat_pin, 500)
heat_pwm.start(50)
blue_pwm = GPIO.PWM(blue_pin, 500)
blue_pwm.start(50)
# variables
temperature = 0
humidity = 0
heater = 0
fan = 0
light = 0
blue = 0
custom_fan = 0
custom_heater = 0
custom_light = 0
custom_blue = 0
auto = 1
buffer_val = 0.5
light_override = 0  # For non-developer MVP. overrides auto mode also. 0 = False...

# environment control profiles
profiles = [
    {'name': 'day', 'temperature': 24, 'humidity': 50, 'light': 100, 'blue': 0}, 
    {'name': 'night','temperature': 19, 'humidity': 50, 'light': 0, 'blue': 0},
    {'name': 'germ','temperature': 24, 'humidity': 50, 'light': 0, 'blue': 100}
]
current_profile = profiles[0]
last_profile = profiles[0]
# schedule = profile + start time
schedule = [['day','0400'],['night','2200']]

# network settings
connflag = False
def on_connect(client, userdata, flags, rc):
    global connflag
    connflag = True
    print("Connection returned result: " + str(rc) )
    client.subscribe(thingName + "/led" , 1 )
    client.subscribe(thingName + "/profile", 1)
    client.subscribe(thingName + "/schedule", 1)
    client.subscribe(thingName + "/auto", 1)
    client.subscribe(thingName + "/changeLight", 1)
    client.subscribe(thingName + "/light_override", 1)
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
        if (msg.topic == thingName + "/led"):
            ledToggle(payload)
        elif (msg.topic == thingName + "/profile"):
            addProfile(payload)
        elif (msg.topic == thingName + "/schedule"):
            changeSchedule(payload)
        elif (msg.topic == thingName + "/auto"):
            setAuto(payload)
        elif (msg.topic == thingName + "/changeLight"):
            changeCustomLight(payload)
        elif (msg.topic == thingName + "/light_override"):
            light_override = payload
    except (ValueError, TypeError, SyntaxError, RuntimeError):
        print("Bad Message")

#def on_log(client, userdata, level, buf):
#    print(msg.topic+" "+str(msg.payload))

mqttc = paho.Client()
mqttc.on_connect = on_connect
mqttc.on_message = on_message
#mqttc.on_log = on_log

mqttc.tls_set(caPath, certfile=certPath, keyfile=keyPath, cert_reqs=ssl.CERT_REQUIRED, tls_version=ssl.PROTOCOL_TLSv1_2, ciphers=None)

mqttc.connect(awshost, awsport, keepalive=60)

mqttc.loop_start()

# Some sick methods
def digitalWrite(pin, val):
    if (val >= 1 or val == True or val == "HIGH"):
        GPIO.output(pin, True)
    else:
        GPIO.output(pin, False)

def analogWrite(pin, duty):
    # pin.start(duty)
    pin.ChangeDutyCycle(duty)

def ledToggle(payload):
    if (int(payload) == 1):
        analogWrite(blue_pwm, 100)
    if (int(payload) == 0):
        analogWrite(blue_pwm, 0)

def getTime():
    time = str(datetime.datetime.now(timezone('US/Eastern')).time())
    time = time[0:2] + time[3:5]
    return time

# Return true if time1 is before (or equal to) time2
# Inputs time1 and time2 are strings
def before(time1, time2):
    hr1 = int(time1[0:2])
    min1 = int(time1[2:4])
    hr2 = int(time2[0:2])
    min2 = int(time2[2:4])
    if hr1 < hr2:
        return True
    elif hr2 < hr1:
        return False
    # hr1 = hr2
    elif min2 < min1:
        return False
    else:
        return True

# Setter for auto variable
def setAuto(val):
    global auto
    if (int(val) >= 1 or val == True or val == "HIGH"):
        auto = 1
    else:
        auto = 0

# Add a new profile to profiles or update an existing one
# Input must be a valid profile (must have 'name' as a key)
def addProfile(profile):
    global profiles
    indices = [profiles.index(x) for x in profiles if x['name'] == profile['name']]
    if len(indices) == 0:
        print("adding new profile \"" + profile['name'] + "\": " + str(profile))
        profiles.append(profile)
    else:
        print("updating existing profile \"" + profile['name'] + "\": " + str(profile))
        profiles[indices[0]] = profile
    updateCurrentProfile(True)

# Changes the schedule of profiles and times
# Input must be a schedule in the correct format
# Sorts the schedule according to start times of profiles
# Updates the current profile as well
def changeSchedule(new_schedule):
    global schedule
    if len(new_schedule) == 0:
        print('Not a valid schedule 2')
        return
    for x in new_schedule:
        print x
        # check if profile exists in profiles
        # any way of making this not o(n^2) ??
        indices = False
        for y in profiles:
            if y['name'] == x[0]:
                indices or True
        if indices:
            print('Profile ' + x[0] + ' has not been created yet')
            return
        if (len(x) != 2) or (not isinstance(x[1],str)):
            print('Not a valid schedule')
            return
    else:
        # sort the schedule
        for i in range(len(new_schedule) - 1):
            min = i
            for j in range(i,len(new_schedule)):
                if before(new_schedule[j][1], new_schedule[min][1]):
                    min = j;
                temp = new_schedule[i];
                new_schedule[i] = new_schedule[min];
                new_schedule[min] = temp;
        # change schedule
        print('New schedule: ' + str(new_schedule))
        schedule = new_schedule
        updateCurrentProfile(True)

# Check the current time to figure out what the current profile is (amongst the ones in the schedule)
# Don't assume schedule is sorted
def updateCurrentProfile(arg = False):
    global current_profile
    time = getTime()
    if len(profiles) == 1:
        current_profile = profiles[0]
    else:
        maximin = None  # an index of the schedule
        last = 0
        for i in range(len(schedule)):
            if before(schedule[i][1], time):
                if maximin is None:
                    maximin = i
                elif before(schedule[maximin][1], schedule[i][1]):
                    maximin = i
            if before(schedule[last][1], schedule[i][1]):
                last = i
        if maximin is None:
            maximin = last
        indices = [profiles.index(x) for x in profiles if x['name'] == schedule[maximin][0]]
        if len(indices) >= 1:
            if not current_profile.get("name") == (profiles[indices[0]].get("name")):
                # turn off the light override if we are switching schedules
                light_override = 0
                mqttc.publish("$aws/things/" + thingName + "/shadow/update",
                    "{\"state\":{\"reported\":{\"light_override\": 0" + "}}}", qos=1)
                current_profile = profiles[indices[0]]
        if arg:
            print("current profile is \"" + current_profile['name'] + "\"")

def automate():
    global heater; global fan; global light; global blue
    tempSP = current_profile['temperature']
    if (temperature < tempSP - buffer_val):
        analogWrite(heat_pwm, 100)
        analogWrite(fan_pwm, 0)
        heater = 100
        fan = 0
    elif (temperature > tempSP + buffer_val):
        analogWrite(heat_pwm, 0)
        analogWrite(fan_pwm, 100)
        heater = 0
        fan = 100
    elif (temperature < tempSP + 0.2) & (temperature > tempSP - 0.2):
        analogWrite(heat_pwm, 0)
        analogWrite(fan_pwm, 0)
        heater = 0
        fan = 0
    if (light_override):
        analogWrite(light_pwm, custom_light)
    else:
        analogWrite(light_pwm, current_profile['light'])
    analogWrite(blue_pwm, current_profile['blue'])
    blue = current_profile['blue']
    light = current_profile['light']

def changeCustomLight(val):
    global custom_light
    global light_override
    if (val >= 0) & (val <= 100):
        custom_light = val
        light_override = 1
        mqttc.publish("$aws/things/" + thingName + "/shadow/update",
            "{\"state\":{\"desired\":{\"custom_light\": null" + "}}}", qos=1)


def resolveDeltas(json):
    print(json)
    if 'desired' in json["state"]:
        print("resolving deltas")
        if 'custom_light' in json["state"]["desired"]:
            val = json["state"]["desired"]["custom_light"]
            changeCustomLight(val)

while True:
    global timer
    sleep(1)
    timer = timer + 1
    # check for outstanding deltas every 7.5 seconds
    if timer >= 5:
        mqttc.publish("$aws/things/" + thingName + "/shadow/get","", qos=1)
        timer = 0
    # mqttc.loop(timeout=1.0, max_packets=1)
    updateCurrentProfile()
    humreading, tempreading = Adafruit_DHT.read_retry(Adafruit_DHT.DHT22, DHT_PIN)
    print(str(humreading))
    if humreading is not None and tempreading is not None:
        temperature = tempreading
        humidity = humreading
    
    if auto == True:
        automate()
    else:
        analogWrite(fan_pwm, custom_fan)
        analogWrite(heat_pwm, custom_heater);
        analogWrite(light_pwm, custom_light);
        analogWrite(blue_pwm, custom_blue);
    
    if connflag == True:
        if humreading is not None and tempreading is not None:
            mqttc.publish("$aws/things/" + thingName + "/shadow/update",
                "{\"state\":{\"reported\":{\"temperature\": " + str(tempreading) + ", \"humidity\":" + str(humreading) +
                ", \"tempSP\":" + str(current_profile['temperature']) + 
                ", \"custom_light\":" + str(custom_light) + 
                ", \"light_override\":" + str(light_override) + 
                ", \"auto\":" + str(auto) + 
                ", \"heater\":" + str(heater) + ", \"fan\":" + str(fan) + "}}}", qos=1)
            print("msg sent: temperature  %.2f; humidity %.2f" % (tempreading, humreading))
        else:
            print("Failed to read sensor")
            # publish a message saying sensor isn't working
    else:
        print("waiting for connection...")
        mqttc.reconnect()

GPIO.cleanup()
