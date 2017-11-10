# Automatino-Pi
# Created by: Bhai Jaiveer Singh
# First implementation of the automated petal box using AWS and RaspberryPi
# This program will publish and subscribe mqtt messages using the AWS IoT hub as a broker

# TODO: change it so that most up to date temp,hum is sent every x seconds and in the background data is being polled
# TODO: Saying msg sent even when not connected to internet
# TODO: Offline mode

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
# import pigpio
# import Adafruit_GPIO.SPI as SPI
# import Adafruit_MCP3008


def cleanup():
    GPIO.cleanup()

atexit.register(cleanup)

# AWS credentials
awshost = "a3nxzzc72rdj05.iot.us-east-2.amazonaws.com"
awsport = 8883
clientId = "pi2"
thingName = "pi2"
caPath = "aws-iot-rootCA.crt"
certPath = "cert.pem"
keyPath = "privkey.pem"

timer = 0

# output pins in GPIO
FAN_PIN = 14
EXHAUST_PIN = 15 # RXD
HEAT_PIN = 18
# BLUE_PIN = 23;
VALVE_PIN = 23
LIGHT_PIN = 24

# input pins in GPIO
DHT_PIN = 2
HIGH_WATER_PIN = 16
MEDIUM_WATER_PIN = 20
TRAY_LEVEL_PIN = 21
# RIBBON
# RESERVOIR_SENSOR

# initialize GPIO
GPIO.setwarnings(False)
GPIO.setmode(GPIO.BCM)
GPIO.cleanup()
GPIO.setup(LIGHT_PIN, GPIO.OUT)
GPIO.setup(FAN_PIN, GPIO.OUT)
GPIO.setup(HEAT_PIN, GPIO.OUT)
GPIO.setup(EXHAUST_PIN, GPIO.OUT)
GPIO.setup(VALVE_PIN, GPIO.OUT)
GPIO.output(LIGHT_PIN, False)
GPIO.output(FAN_PIN, False)
GPIO.output(HEAT_PIN, False)
GPIO.output(EXHAUST_PIN, False)
GPIO.output(VALVE_PIN, False)
GPIO.setup(TRAY_LEVEL_PIN, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
GPIO.setup(HIGH_WATER_PIN, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
GPIO.setup(MEDIUM_WATER_PIN, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
light_pwm = GPIO.PWM(LIGHT_PIN, 100)
light_pwm.start(0)
fan_pwm = GPIO.PWM(FAN_PIN, 100);
fan_pwm.start(0)
heat_pwm = GPIO.PWM(HEAT_PIN, 100);
heat_pwm.start(0)
exhaust_pwm = GPIO.PWM(EXHAUST_PIN, 100);
exhaust_pwm.start(0)

# MCP setup
# SPI_PORT   = 0
# SPI_DEVICE = 0
# mcp = Adafruit_MCP3008.MCP3008(spi=SPI.SpiDev(SPI_PORT, SPI_DEVICE))

# variables
temperature = 0
humidity = 0
heater = 0
fan = 0
light = 0
blue = 0
buffer_val = 0.5
light_override = 0  # For non-developer MVP. overrides auto mode also. 0 = False...
fan_override = 0
heater_override = 0
blue_override = 0
# auto = light_override + fan_override + heater_override + blue_override
auto = 1
valve = 0
mode = 0 # 0 = neutral, 1 = heating, 2 = cooling
#dont actually need custom_light etc. we'll just assign when called

class Tier(object):
    """Instances represent individually controlled tiers of the system.
    Instance Attributes:
        temperature:
        humidity:
        light:
        blue:
        auto:
        light_override:
        fan_override:
        heater_override:
        blue_override:
        auto:
        schedule:"""

# environment control profiles
profiles = [
    {'name': 'day', 'temperatureSP': 24, 'humiditySP': 50, 'light': 100, 'blue': 0}, 
    {'name': 'night','temperatureSP': 19, 'humiditySP': 50, 'light': 0, 'blue': 0},
    {'name': 'germ','temperatureSP': 24, 'humiditySP': 50, 'light': 0, 'blue': 100}
]
current_profile = profiles[0]
last_profile = profiles[0]
schedule = [['day','0400'],['night','2200']]

# network settings
connflag = False
def on_connect(client, userdata, flags, rc):
    global connflag
    connflag = True
    print("Connection returned result: " + str(rc) )
    mqttc.subscribe(thingName + "/led" , 1 )
    mqttc.subscribe(thingName + "/profile", 1)
    mqttc.subscribe(thingName + "/schedule", 1)
    mqttc.subscribe(thingName + "/auto", 1)
    mqttc.subscribe(thingName + "/change_light", 1)
    mqttc.subscribe(thingName + "/light_override", 1)
    mqttc.subscribe("$aws/things/" + thingName + "/shadow/get/accepted")
    # mqttc.subscribe("$aws/things/" + thingName + "/shadow/update/delta")
    # mqttc.subscribe("$aws/things/" + thingName + "/shadow/update/documents", 1)

def on_disconnect(client, userdata, rc):
    global connflag
    connflag = False
    print("DISCONNECTED")

def on_message(mosq, obj, msg):
    global light
    global light_override
    try:
        print("Topic: "+msg.topic)
        print("Payload: "+str(msg.payload))
        if (msg.topic == "$aws/things/" + thingName + "/shadow/update/delta"):
            # resolve_deltas(json.loads(msg.payload))
            pass
        # if (msg.topic == "$aws/things/" + thingName + "/shadow/get/accepted"):
        #     resolve_deltas(json.loads(msg.payload))
        #     return
        payload = ast.literal_eval(msg.payload)
        if (msg.topic == thingName + "/led"):
            led_toggle(payload)
        elif (msg.topic == thingName + "/profile"):
            add_profile(payload)
        elif (msg.topic == thingName + "/schedule"):
            change_schedule(payload)
        elif (msg.topic == thingName + "/auto"):
            set_auto(payload)
        elif (msg.topic == thingName + "/change_light"):
            change_light(payload)
        elif (msg.topic == thingName + "/light_override"):
            light_override = payload
    except (ValueError, TypeError, SyntaxError, RuntimeError):
        print("Bad Message")

#def on_log(client, userdata, level, buf):
#    print(msg.topic+" "+str(msg.payload))

mqttc = paho.Client()
mqttc.on_connect = on_connect
mqttc.on_message = on_message
mqttc.on_disconnect = on_disconnect
#mqttc.on_log = on_log

mqttc.tls_set(caPath, certfile=certPath, keyfile=keyPath, cert_reqs=ssl.CERT_NONE, tls_version=ssl.PROTOCOL_TLSv1_2, ciphers=None)
mqttc.tls_insecure_set(True)

mqttc.connect(awshost, awsport, keepalive=60)

mqttc.loop_start()

# Some sick methods
def digital_write(pin, val):
    if (val >= 1 or val == True or val == "HIGH"):
        GPIO.output(pin, True)
    else:
        GPIO.output(pin, False)

def analog_write(pin, duty):
    # pin.start(duty)
    pin.ChangeDutyCycle(duty)

def led_toggle(payload):
    if (int(payload) == 1):
        analog_write(light_pwm, 100)
    if (int(payload) == 0):
        analog_write(light_pwm, 0)

def get_time():
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
def set_auto(val):
    global auto
    if (int(val) >= 1 or val == True or val == "HIGH"):
        auto = 1
    else:
        auto = 0

# Add a new profile to profiles or update an existing one
# Input must be a valid profile (must have 'name' as a key)
def add_profile(profile):
    global profiles
    indices = [profiles.index(x) for x in profiles if x['name'] == profile['name']]
    if len(indices) == 0:
        print("adding new profile \"" + profile['name'] + "\": " + str(profile))
        profiles.append(profile)
    else:
        print("updating existing profile \"" + profile['name'] + "\": " + str(profile))
        profiles[indices[0]] = profile
    update_current_profile(True)

# Changes the schedule of profiles and times
# Input must be a schedule in the correct format
# Sorts the schedule according to start times of profiles
# Updates the current profile as well
def change_schedule(new_schedule):
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
        update_current_profile(True)

# Check the current time to figure out what the current profile is (amongst the ones in the schedule)
# Don't assume schedule is sorted
def update_current_profile(arg = False):
    global current_profile
    global light_override
    time = get_time()
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
            if not (current_profile['name'] == profiles[indices[0]]["name"]):
                # turn off the light override if we are switching schedules
                light_override = 0
                print("override 0")
                mqttc.publish("light_override",
                    "0", qos=1)
            current_profile = profiles[indices[0]]
        if arg:
            print("current profile is \"" + str(current_profile) + "\"")

def automate():
    global heater; global fan; global light; global blue; global mode; global temperature; global humidity
    tempSP = current_profile['temperatureSP']
    if (temperature < tempSP - buffer_val):
        analog_write(heat_pwm, 100)
        analog_write(fan_pwm, 0)
        heater = 100
        fan = 0
        mode = 1
    elif (temperature > tempSP + buffer_val):
        analog_write(heat_pwm, 0)
        analog_write(fan_pwm, 100)
        heater = 0
        fan = 100
        mode = 2
    elif ((temperature < tempSP + 0.2) & (temperature > tempSP - 0.2)):
        analog_write(heat_pwm, 0)
        analog_write(fan_pwm, 0)
        heater = 0
        fan = 0
        mode = 0
    if not light_override:
        print("here")
        analog_write(light_pwm, current_profile['light'])
        light = current_profile['light']
    # analog_write(blue_pwm, current_profile['blue'])
    blue = current_profile['blue']

def change_light(val):
    global light
    global light_override
    if (val >= 0) and (val <= 100):
        if val != light:
            light = val
            analog_write(light_pwm, light)
            light_override = 1
            # Clear the delta
            mqttc.publish("$aws/things/" + thingName + "/shadow/update",
                "{\"state\":{\"reported\":{\"light\": " + str(light) + "}}}", qos=1)
    else:
        print("Light value should be between 0 and 100")

def resolve_deltas(json):
    print(json)
    if 'light' in json["state"]:
        val = json["state"]["light"]
        change_light(val)

def get_readings():
    global humidity
    global temperature
    # checks 5 times
    humreading = None
    tempreading = None
    reading_counter = 0
    while (humreading is None or tempreading is None) and reading_counter < 5:
        print("reading")
        reading_counter = reading_counter + 1
        humreading, tempreading = Adafruit_DHT.read(Adafruit_DHT.DHT22, DHT_PIN)
    if (humreading is not None and tempreading is not None):
        humidity = humreading
        temperature = tempreading
        return True
    else:
        return False

def tray_update():
    global valve
    waterVal = GPIO.input(TRAY_LEVEL_PIN)
    if (waterVal == 0):
        digital_write(VALVE_PIN, True)
        valve = 1
        print("valve opened")
        return
    # If waterval > 10 and the valve is currently open
    if (valve == 1):
        digital_write(VALVE_PIN, False)
        valve = 0
        print("valve closed")

def reservoir_update():
    waterHigh = GPIO.input(HIGH_WATER_PIN)
    if (waterHigh == 1):
        return 2
    waterMedium = GPIO.input(MEDIUM_WATER_PIN)
    if (waterMedium == 1):
        return 1
    else:
        return 0

# while True:
#     sleep(1)
#     value = mcp.read_adc(0)
#     change_light(value/100 * 10)

while True:
    global timer
    sleep(3)
    timer = timer + 1
    # check for outstanding deltas every 7.5 seconds
    if timer >= 5:
        mqttc.publish("$aws/things/" + thingName + "/shadow/get","", qos=1)
        timer = 0
    # mqttc.loop(timeout=1.0, max_packets=1)
    update_current_profile()
    tray_update()
    water_level = reservoir_update()
    could_read = get_readings()

    # maybe only do the below things if there's a change in something?
    if auto == 1:
        automate()
    else:
        # custom write
        pass
    if light > 0 or fan > 0:
        analog_write(exhaust_pwm, 50)
    if connflag == True:
        if (could_read):
            mqttc.publish("$aws/things/" + thingName + "/shadow/update",
                "{\"state\":{\"reported\":{\"temperature\": " + str(temperature) + ", \"humidity\":" + str(humidity) +
                ", \"tempSP\":" + str(current_profile['temperatureSP']) + 
                ", \"light\":" + str(light) + 
                ", \"light_override\":" + str(light_override) + 
                ", \"mode\":" + str(mode) + 
                ", \"auto\":" + str(auto) + 
                ", \"water\":" + str(water_level) + 
                ", \"heater\":" + str(heater) + ", \"fan\":" + str(fan) + "}}}", qos=1)
            print("msg sent: temperature  %.2f; humidity %.2f" % (temperature, humidity))
        else:
            print("Failed to read sensor")
            # publish a message saying sensor isn't working
    else:
        print("waiting for connection...")
        mqttc.reconnect()

GPIO.cleanup()
