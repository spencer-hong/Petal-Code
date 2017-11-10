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