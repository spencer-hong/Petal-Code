#!/bin/bash
# A simple script
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install python-pip
sudo pip install paho-mqtt
sudo pip install pytz
sudo apt-get install git
git clone https://github.com/adafruit/Adafruit_Python_DHT.git
cd Adafruit_Python_DHT
sudo python setup.py install
cd ..
git clone https://github.com/aws/aws-iot-device-sdk-python.git
cd aws-iot-device-sdk-python
sudo python setup.py install
echo 'network={' >> myfile.txt
echo '    ssid=' + ssid >> file.txt
echo '    psk=' >> file.txt
echo '}'