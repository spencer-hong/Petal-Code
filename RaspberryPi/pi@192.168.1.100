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
light_pwm.start(100)
fan_pwm = GPIO.PWM(FAN_PIN, 100);
fan_pwm.start(0)
heater_pwm = GPIO.PWM(HEAT_PIN, 100);
heater_pwm.start(0)
exhaust_pwm = GPIO.PWM(EXHAUST_PIN, 100);
exhaust_pwm.start(0)
