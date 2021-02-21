# NVR-Pi-installer
Installscript for [Shinobi](https://shinobi.video/)

NVR-Pi-install script

Installscript for Shinobi NVR on RaspberryPi ([with Raspberry Pi OS 10 Lite](https://www.raspberrypi.org/software/operating-systems/))

###############

cd /tmp

wget https://raw.githubusercontent.com/steigerbalett/NVR-Pi-installer/master/install.sh

sudo bash install.sh

###############

Use (1) Ubuntu touchless install if asked.


If you want to add a USB-HDD, please format it as exFat, lable it NVR and attache it to the raspberry befor installation.



After installation & reboot you can access Shinobi at your RaspberryPi IP http://nvrpi:8080

Add an new User to Shinobi:

http://nvrpi:8080/super

Username : admin@shinobi.video

Password : admin
