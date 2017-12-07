#!/bin/bash
# type in ./install.sh
set -e

# Update apt
sudo apt-get update
sudo apt-get -y upgrade

# Install dependencies
sudo apt-get install -y python-pip
sudo pip install paho-mqtt
sudo pip install pytz
sudo apt-get install -y git
git clone https://github.com/adafruit/Adafruit_Python_DHT.git
cd Adafruit_Python_DHT
sudo python setup.py install
cd ..
git clone https://github.com/aws/aws-iot-device-sdk-python.git
cd aws-iot-device-sdk-python
sudo python setup.py install
cd /home/pi

# Add network settings
sudo bash -c 'cat default_networks.txt >> /etc/wpa_supplicant/wpa_supplicant.conf'

# Set program to launch on startup
sed 's/exit 0/python /home/pi/iko$1/automatino.py &\nexit 0' /etc/rc.local

sudo reboot