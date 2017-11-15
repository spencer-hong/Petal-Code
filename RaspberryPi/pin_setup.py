import RPi.GPIO as GPIO

LIGHT_PINS = [14,25,20,6,22]
FAN_PINS = [15,8,21,5,27]
EXHAUST_PINS = [18,7,26,11,19]
HEAT_PINS = [23,12,19,9,4]
DHT_PINS = [24,16,13,10,3]

GPIO.setwarnings(False)
GPIO.cleanup()
GPIO.setmode(GPIO.BCM)

VALVE_PIN = HIGH_WATER_PIN = MEDIUM_WATER_PIN = TRAY_LEVEL_PIN = None
light_pwm = fan_pwm = heater_pwm = exhaust_pwm = []

def setup_gpios(num_tiers):
	global light_pwm
	global fan_pwm
	global heater_pwm
	global exhaust_pwm
	light_pwm = fan_pwm = heater_pwm = exhaust_pwm = [None for x in range(num_tiers)]
	for i in range(num_tiers):
		GPIO.setup(LIGHT_PINS[i], GPIO.OUT)
		GPIO.setup(FAN_PINS[i], GPIO.OUT)
		GPIO.setup(HEAT_PINS[i], GPIO.OUT)
		GPIO.setup(EXHAUST_PINS[i], GPIO.OUT)
		GPIO.output(LIGHT_PINS[i], False)
		GPIO.output(FAN_PINS[i], False)
		GPIO.output(HEAT_PINS[i], False)
		GPIO.output(EXHAUST_PINS[i], False)
		light_pwm[i] = GPIO.PWM(LIGHT_PINS[i], 100)
		light_pwm[i].start(0)
		fan_pwm[i] = GPIO.PWM(FAN_PINS[i], 100);
		fan_pwm[i].start(0)
		heater_pwm[i] = GPIO.PWM(HEAT_PINS[i], 100);
		heater_pwm[i].start(0)
		exhaust_pwm[i] = GPIO.PWM(EXHAUST_PINS[i], 100);
		exhaust_pwm[i].start(0)

def setup_valve():
	global VALVE_PIN
	VALVE_PIN = 23
	GPIO.setup(VALVE_PIN, GPIO.OUT)
	GPIO.output(VALVE_PIN, False)

def setup_reservoir():
	global HIGH_WATER_PIN
	global MEDIUM_WATER_PIN
	global TRAY_LEVEL_PIN
	HIGH_WATER_PIN = 16
	MEDIUM_WATER_PIN = 20
	TRAY_LEVEL_PIN = 21
	GPIO.setup(TRAY_LEVEL_PIN, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
	GPIO.setup(HIGH_WATER_PIN, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
	GPIO.setup(MEDIUM_WATER_PIN, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)