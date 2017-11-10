import RPi.GPIO as GPIO
from time import sleep
# output pins in GPIO
FAN_PIN = 14
EXHAUST_PIN = 15 # RXD
HEAT_PIN = 23

# BLUE_PIN = 23;
VALVE_PIN = 18
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

while True:
	sleep(2)
	trayVal = GPIO.input(TRAY_LEVEL_PIN)
	highVal = GPIO.input(HIGH_WATER_PIN)
	mediumVal = GPIO.input(MEDIUM_WATER_PIN)
	print("Tray Val is: " + str(trayVal))
	print("Medium Val is: " + str(mediumVal))
	print("High Val is: " + str(highVal))
	print('\n')