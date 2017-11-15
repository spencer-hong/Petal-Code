# Automatino-Pi
# Created by: Bhai Jaiveer Singh
# First implementation of the automated petal box using AWS and RaspberryPi
# This program will publish and subscribe mqtt messages using the AWS IoT hub as a broker

# TODO: change it so that most up to date temp,hum is sent every x seconds and in the background data is being polled

import paho.mqtt.client as mqtt
import AWSIoTPythonSDK
import os
import socket
import ssl
import RPi.GPIO as GPIO
import string
import Adafruit_DHT
import time
import datetime
import ast
import json
import atexit
from time import sleep
from random import uniform
from pytz import timezone
import client

MQTT_PORT = 8883
MQTT_KEEPALIVE_INTERVAL = 45
MQTT_HOST = "a3nxzzc72rdj05.iot.us-east-2.amazonaws.com"
CA_ROOT_CERT_FILE = "aws-iot-rootCA.crt"
THING_CERT_FILE = "cert.pem"
THING_PRIVATE_KEY = "privkey.pem"

timer = 0
box_type = 'styro'
num_tiers = 1

# RPi zeroW has 26 GPIO pins, 2...27

LIGHT_PINS = [14,15,18,23,24]
FAN_PINS = [25,8,7,12,16]
EXHAUST_PINS = [20,21,26,19,13] # RXD
HEAT_PINS = [6,5,11,9,10]
DHT_PINS = [22,27,17,4,3]

if box_type != 'styro':
    VALVE_PIN = 23
    HIGH_WATER_PIN = 16
    MEDIUM_WATER_PIN = 20
    TRAY_LEVEL_PIN = 21
    GPIO.setup(VALVE_PIN, GPIO.OUT)
    GPIO.output(VALVE_PIN, False)
    GPIO.setup(TRAY_LEVEL_PIN, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
    GPIO.setup(HIGH_WATER_PIN, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
    GPIO.setup(MEDIUM_WATER_PIN, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)

# initialize GPIO
GPIO.setwarnings(False)
GPIO.setmode(GPIO.BCM)
GPIO.cleanup()
light_pwm = fan_pwm = heater_pwm = exhaust_pwm = [None for x in range(num_tiers)]
for i in range(num_tiers):
    GPIO.setup(LIGHT_PINS[i], GPIO.OUT)
    GPIO.setup(FAN_PINS[i], GPIO.OUT)
    GPIO.setup(HEAT_PINS[i], GPIO.OUT)
    GPIO.setup(EXHAUST_PINS[i], GPIO.OUT)
    GPIO.output(LIGHT_PINS[i], False)
    GPIO.output(FAN_PINS[i], False)
    GPIO.output(HEAT_PINS[i], False)
    GPIO.output(EXHAUST_PIN[i], False)
    light_pwm[i] = GPIO.PWM(LIGHT_PINS[i], 100)
    light_pwm[i].start(0)
    fan_pwm[i] = GPIO.PWM(FAN_PINS[i], 100);
    fan_pwm[i].start(0)
    heater_pwm[i] = GPIO.PWM(HEAT_PIN[i], 100);
    heater_pwm[i].start(0)
    exhaust_pwm[i] = GPIO.PWM(EXHAUST_PIN[i], 100);
    exhaust_pwm[i].start(0)

# Some sick methods
def digital_write(pin, val):
    if (val >= 1 or val == True or val == "HIGH"):
        GPIO.output(pin, True)
    else:
        GPIO.output(pin, False)

# GPIO.input(pin)

def set_pwm(pwm_object, val):
    pwm_object.ChangeDutyCycle(val)

def get_pwm(pwm_object):
    return pwm_object.dutycycle

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

def reservoir_update():
    waterHigh = GPIO.input(HIGH_WATER_PIN)
    if (waterHigh == 1):
        return 2
    waterMedium = GPIO.input(MEDIUM_WATER_PIN)
    if (waterMedium == 1):
        return 1
    else:
        return 0

class Tier(object):
    def __init__(self, name, dht_pin, fan=None,light=None,heater=None,exhaust=None,blue=0,buffer_val=0.5,light_override=0,fan_override=0,heater_override=0,blue_override=0,auto=1,valve=0,mode=0):
        self.name = name
        self.temperature = None
        self.humidity = None
        self.blue,self.light_override,self.heater_override,self.blue_override = blue,light_override,heater_override,blue_override   
        self.light, self.fan, self.heater, self.exhaust = light, fan, heater, exhaust
        self.buffer_val,self.auto,self.valve,self.mode= buffer_val,auto,valve,mode
        self.dht_pin = dht_pin
        self.profiles = [
            {'name': 'day', 'temperatureSP': 24, 'humiditySP': 50, 'light': 100, 'blue': 0}, 
            {'name': 'night','temperatureSP': 19, 'humiditySP': 50, 'light': 0, 'blue': 0},
            {'name': 'germ','temperatureSP': 24, 'humiditySP': 50, 'light': 0, 'blue': 100}
        ]
        self.current_profile = profiles[0]
        self.last_profile = profiles[0]
        self.schedule = [['day','0400'],['night','2200']]

    def set_light(self, val):
        self.light.ChangeDutyCycle(val)

    def get_light(self):
        return self.light.dutycycle

    def set_fan(self, val):
        self.fan.ChangeDutyCycle(val)

    def get_fan(self):
        return self.fan.dutycycle

    def set_heater(self, val):
        self.heater.ChangeDutyCycle(val)

    def get_heater(self):
        return self.heater.dutycycle

    def set_exhaust(self, val):
        self.exhaust.ChangeDutyCycle(val)

    def get_exhaust(self):
        return self.exhaust.dutycycle

    def set_auto(self, val):
        if (int(val) >= 1 or val == True or val == "HIGH"):
            self.auto = 1
        else:
            self.auto = 0

    # Add a new profile to profiles or update an existing one
    # Input must be a valid profile (must have 'name' as a key)
    def add_profile(self, profile):
        indices = [self.profiles.index(x) for x in self.profiles if x['name'] == self.profile['name']]
        if len(indices) == 0:
            print("adding new profile \"" + self.profile['name'] + "\": " + str(profile))
            self.profiles.append(profile)
        else:
            print("updating existing profile \"" + self.profile['name'] + "\": " + str(profile))
            self.profiles[indices[0]] = profile
        self.update_current_profile(True)

    # Changes the schedule of profiles and times
    # Input must be a schedule in the correct format
    # Sorts the schedule according to start times of profiles
    # Updates the current profile as well
    def change_schedule(self, new_schedule):
        if len(new_schedule) == 0:
            print('Not a valid schedule 2')
            return
        for x in new_schedule:
            print x
            # check if profile exists in profiles
            # any way of making this not o(n^2) ??
            indices = False
            for y in self.profiles:
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
            self.schedule = new_schedule
            self.update_current_profile(True)

    # Check the current time to figure out what the current profile is (amongst the ones in the schedule)
    # Don't assume schedule is sorted
    def update_current_profile(self, arg = False):
        time = get_time()
        if len(self.profiles) == 1:
            self.current_profile = self.profiles[0]
        else:
            maximin = None  # an index of the schedule
            last = 0
            for i in range(len(self.schedule)):
                if before(self.schedule[i][1], time):
                    if maximin is None:
                        maximin = i
                    elif before(self.schedule[maximin][1], self.schedule[i][1]):
                        maximin = i
                if before(self.schedule[last][1], self.schedule[i][1]):
                    last = i
            if maximin is None:
                maximin = last
            indices = [self.profiles.index(x) for x in self.profiles if x['name'] == self.schedule[maximin][0]]
            if len(indices) >= 1:
                if not (self.current_profile['name'] == self.profiles[indices[0]]["name"]):
                    # turn off the light override if we are switching schedules
                    self.light_override = 0
                    print("override 0")
                    mqttc.publish("light_override",
                        "0", qos=1)
                self.current_profile = profiles[indices[0]]
            if arg:
                print("current profile is \"" + str(current_profile) + "\"")

    def automate(self):
        tempSP = self.current_profile['temperatureSP']
        if (self.temperature < tempSP - self.buffer_val):
            self.set_heater(100)
            self.set_fan(100)
            self.set_exhaust(0)
            self.mode = 1
        elif (temperature > tempSP + buffer_val):
            self.set_heater(0)
            self.set_fan(100)
            self.set_exhaust(100)
            self.mode = 2
        elif ((temperature < tempSP + 0.2) & (temperature > tempSP - 0.2)):
            self.set_heater(0)
            self.set_fan(0)
            self.set_exhaust(0)
            self.mode = 0
        if not self.light_override:
            self.set_light(self.current_profile['light'])
        self.blue = self.current_profile['blue']

    def change_light(self, val):
        if (val >= 0) and (val <= 100):
            if val != self.light:
                self.set_light(val)
                self.light_override = 1
                # Clear the delta
                mqttc.publish("$aws/things/" + thingName + "/shadow/update",
                    "{\"state\":{\"reported\":{\"light\": " + str(light) + "}}}", qos=1)
        else:
            print("Light value should be between 0 and 100")

    def resolve_deltas(self, json):
        print(json)
        if 'light' in json["state"]:
            val = json["state"]["light"]
            self.change_light(val)

    def get_readings(self):
        # checks 5 times
        humreading = None
        tempreading = None
        reading_counter = 0
        while (humreading is None or tempreading is None) and reading_counter < 5:
            print("reading")
            reading_counter = reading_counter + 1
            humreading, tempreading = Adafruit_DHT.read(Adafruit_DHT.DHT22, self.dht_pin)
        if (humreading is not None and tempreading is not None):
            self.humidity = humreading
            self.temperature = tempreading
            return True
        else:
            return False

    def tray_update(self):
        waterVal = GPIO.input(TRAY_LEVEL_PIN)
        if (waterVal == 0):
            digital_write(VALVE_PIN, True)
            self.valve = 1
            print("valve opened")
            return
        # If waterval > 10 and the valve is currently open
        if (self.valve == 1):
            digital_write(VALVE_PIN, False)
            self.valve = 0
            print("valve closed")

    def big_loop(self):
        global timer
        sleep(3)
        timer = timer + 1
        # check for outstanding deltas every 7.5 seconds
        if timer >= 5:
            mqttc.publish("$aws/things/" + thingName + "/shadow/get","", qos=1)
            timer = 0
        # mqttc.loop(timeout=1.0, max_packets=1)
        self.update_current_profile()
        if self.valve != None:
            self.tray_update()
        # water_level = reservoir_update()
        could_read = self.get_readings()

        # Maybe only do the below things if there's a change in something?
        if self.auto == 1:
            self.automate()
        else:
            # Custom write
            pass

    def update_cloud(self):
        if self.get_readings():
            mqttc.publish("$aws/things/" + thingName + "/shadow/update",
                "{\"state\":{\"reported\":{\"temperature\": " + str(self.temperature) + ", \"humidity\":" + str(self.humidity) +
                ", \"tempSP\":" + str(self.current_profile['temperatureSP']) + 
                ", \"light\":" + str(self.get_light) + 
                ", \"light_override\":" + str(self.light_override) + 
                ", \"mode\":" + str(self.mode) + 
                ", \"auto\":" + str(self.auto) + 
                ", \"heater\":" + str(self.get_heater) + ", \"fan\":" + str(self.get_fan) + "}}}", qos=1)
            print("msg sent: temperature  %.2f; humidity %.2f" % (self.temperature, self.humidity))
        else:
            print("Failed to read sensor")
            # Publish a message saying sensor isn't working

if __name__ == '__main__':
    tiers = [None for x in range(num_tiers)]
    for i in range(num_tiers):
        tiers[i] = Tier('pi6.'+str(i+1), DHT_PINS[i], light=light_pwm[i],fan=fan_pwm[i],heater=heater_pwm[i],exhaust=exhaust_pwm[i])
    mqttc = client.Client(tiers)
    while True:
        if mqttc.connflag == False:
            mqttc.reconnect
        for tier in tiers:
            tier.big_loop()
            tier.update_cloud()
    GPIO.cleanup()
    mqttc.disconnect()
