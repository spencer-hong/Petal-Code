import paho.mqtt.client as mqtt
import AWSIoTPythonSDK
import ssl
import ast
from automatino_oo import Tier

MQTT_PORT = 8883
MQTT_KEEPALIVE_INTERVAL = 45

MQTT_HOST = "a3nxzzc72rdj05.iot.us-east-2.amazonaws.com"
CA_ROOT_CERT_FILE = "aws-iot-rootCA.crt"
THING_CERT_FILE = "cert.pem"
THING_PRIVATE_KEY = "privkey.pem"

class Client(mqtt.Client):
    def __init__(self, tiers):
        mqtt.Client.__init__(self)
        self.connflag = False
        self.tiers = tiers
        self.tls_set(CA_ROOT_CERT_FILE, certfile=THING_CERT_FILE, keyfile=THING_PRIVATE_KEY, cert_reqs=ssl.CERT_REQUIRED, tls_version=ssl.PROTOCOL_TLSv1_2, ciphers=None)
        self.connect(MQTT_HOST, MQTT_PORT, MQTT_KEEPALIVE_INTERVAL)
        self.loop_start()

    def on_connect(self, client, userdata, flags, rc):
        self.connflag = True
        print("Connection returned result: " + str(rc) )
        for tier in self.tiers:
            self.subscribe(tier.name + "/led" , 1 )
            self.subscribe(tier.name + "/profile", 1)
            self.subscribe(tier.name + "/schedule", 1)
            self.subscribe(tier.name + "/auto", 1)
            self.subscribe(tier.name + "/change_light", 1)
            self.subscribe(tier.name + "/light_override", 1)
            self.subscribe("$aws/things/" + tier.name + "/shadow/get/accepted")
            # mqttc.subscribe("$aws/things/" + thingName + "/shadow/update/delta")
            # mqttc.subscribe("$aws/things/" + thingName + "/shadow/update/documents", 1)

    def on_message(self, mosq, obj, msg):
        try:
            print("Topic: "+msg.topic)
            print("Payload: "+str(msg.payload))
            payload = ast.literal_eval(msg.payload)
            for tier in self.tiers:
                if (msg.topic == "$aws/things/" + tier.name + "/shadow/update/delta"):
                    # resolve_deltas(json.loads(msg.payload))
                    pass
                # if (msg.topic == "$aws/things/" + thingName + "/shadow/get/accepted"):
                #     resolve_deltas(json.loads(msg.payload))
                #     return
                
                elif (msg.topic == tier.name + "/led"):
                    tier.led_toggle(payload)
                elif (msg.topic == tier.name + "/profile"):
                    tier.add_profile(payload)
                elif (msg.topic == tier.name + "/schedule"):
                    tier.change_schedule(payload)
                elif (msg.topic == tier.name + "/auto"):
                    tier.set_auto(payload)
                elif (msg.topic == tier.name + "/change_light"):
                    tier.change_light(payload)
                elif (msg.topic == tier.name + "/light_override"):
                    tier.light_override = payload
        except (ValueError, TypeError, SyntaxError, RuntimeError):
            print("Bad Message")

    def on_disconnect(self, client, userdata, rc):
        self.connflag = False
        print("DISCONNECTED")

