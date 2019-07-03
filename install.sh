#!/bin/sh

# Error out if anything fails.
#set -e

#License
clear
echo 'MIT License'
echo ''
echo 'Copyright (c) 2019 steigerbalett'
echo ''
echo 'Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:'
echo ''
echo 'The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.'
echo ''
echo 'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.'
echo ''
echo 'Installation will continue in 3 seconds...'
echo ''
echo -e "\033[1;31mVERSION: 2019-05-22\033[0m"
echo -e "\033[1;31mShinobi installer aka NVR-Pi\033[0m"
sleep 3

# Make sure script is run as root.
if [ "$(id -u)" != "0" ]; then
    echo -e "\033[1;31mDas Script muss als root ausgeführt werden, sudo./install.sh\033[0m"
    echo -e '\033[36mMust be run as root with sudo! Try: sudo ./install.sh\033[0m'
  exit 1
fi

echo 'Step 1:' 
echo "Installing dependencies..."
echo "=========================="
echo ''
apt update
apt -y full-upgrade
apt -y install ntfs-3g hdparm hfsutils hfsprogs exfat-fuse git ntpdate proftpd samba
echo "updating date and time"
sudo ntpdate -u de.pool.ntp.org 

echo 'Step 2:' 
echo -e '\033[5mShinobi installieren\033[0m'
echo "=========================="
echo ''
cd /tmp
bash <(curl -s https://gitlab.com/Shinobi-Systems/Shinobi-Installer/raw/master/shinobi-install.sh)

echo 'Step 3:'
echo "Tweaks"
echo "========================"
echo ''
if grep gpu_mem /boot/config.txt; then
  echo "Not changing GPU memory since it's already set"
else
  echo "Increasing GPU memory"
  echo "========================"
  echo "" >> /boot/config.txt
  echo "# Increase GPU memory for better performance" >> /boot/config.txt
  echo "gpu_mem=256" >> /boot/config.txt
fi

if grep hdmi_blanking=1 /boot/config.txt; then
  echo "HDMI tweak already set"
else
echo "Turn off HDMI without connected Monitor"
echo "========================"
echo ''
echo "" >> /boot/config.txt
echo "# Turn off HDMI without connected Monitor" >> /boot/config.txt
echo "hdmi_blanking=1" >> /boot/config.txt
echo "" >> /boot/config.txt
echo "# disable HDMI audio" >> /boot/config.txt
echo "hdmi_drive=1" >> /boot/config.txt
fi

echo "" >> /boot/config.txt
echo "# disable the splash screen" >> /boot/config.txt
echo "disable_splash=1" >> /boot/config.txt
echo "" >> /boot/config.txt
echo "# disable overscan" >> /boot/config.txt
echo "disable_overscan=1" >> /boot/config.txt

echo "Enable Hardware watchdog"
echo "========================"
echo ''
echo "" >> /boot/config.txt
echo "# activating the hardware watchdog" >> /boot/config.txt
echo "dtparam=watchdog=on" >> /boot/config.txt

# enable additional admin programs
echo 'Step 4: Optionales Admin Programm'
echo 'Installation of optional Raspberry-Config UI: Webmin (recommend)'
echo ''
echo -n -e '\033[7mMöchten Sie Webmin installieren (empfohlen) [J/n]\033[0m'
echo ''
echo -n -e '\033[36mDo you want to install Webmin [Y/n]\033[0m'
read webmindecision

if [[ $webmindecision =~ (J|j|Y|y) ]]
  then
echo 'deb https://download.webmin.com/download/repository sarge contrib' | sudo tee /etc/apt/sources.list.d/100-webmin.list
#cd ../root
wget http://www.webmin.com/jcameron-key.asc
sudo apt-key add jcameron-key.asc 
sudo apt update
sudo apt install webmin -y
elif [[ $webmindecision =~ (n) ]]
  then
    echo 'Es wurde nichts verändert'
    echo -e '\033[36mNo modifications was made\033[0m'
else
    echo 'Invalid input!'
fi

# enable USB-Drive autostart
echo 'Step 5:'
echo 'USB-Festplatte automatisch mounten'
echo 'Enable automatic mount of an USB-HDD (recommend)'
echo ''
echo -n -e '\033[7mMöchten Sie; dass eine per USB angeschlossene Festplatte automatisch eingebunden wird? (empfohlen) [J/n]\033[0m'
echo ''
echo -n -e '\033[36mDo you want to mount an USB-Disk on boot? [Y/n]\033[0m'
read usbdiskdecision

if [[ $usbdiskdecision =~ (J|j|Y|y) ]]
  then
sudo echo "/dev/sda1    /media/nvr   ntfs    uid=pi,gid=pi,auto,noatime,sync,users,rw,dev,exec,suid,nofail  0       1" >> /etc/fstab
sudo mkdir /media/nvr
sudo mkdir /media/nvr/sample
sudo mount -a
sudo chmod -R 777 /media/nvr
sudo sed -i 's/second/USB-HDD/' /home/Shinobi/conf.json
sudo sed -i 's!__DIR__/videos2!/media/nvr!' /home/Shinobi/conf.json
sudo sed -i 's/change_this_to_something_very_random__just_anything_other_than_this/Change-this-please-to_something_very_random/' /home/Shinobi/conf.json
elif [[ $usbdiskdecision =~ (n) ]]
  then
    echo 'Es wurde nichts verändert'
    echo -e '\033[36mNo modifications was made\033[0m'
else
    echo 'Invalid input!'
fi

# enable weekly reboot
echo 'Step 6:'
echo 'Raspberry jeden Sonntag um 03:15 Uhr neustarten'
echo 'Enable automatic reboot every sunday at 3:15 am'
echo ''
echo -n -e '\033[7mSoll der RaspberryPi jeden Sonntag um 03:15 Uhr automatisch neu starten? [J/n]\033[0m'
echo ''
echo -n -e '\033[36mDo you want to set automatic restart every sunday at 03:15 am every day? [Y/n]\033[0m'
read cronbootdecision

if [[ $cronbootdecision =~ (J|j|Y|y) ]]
  then
sudo echo "*/15 3 * * 0   root     shutdown -r now" >> /etc/crontab
elif [[ $cronbootdecision =~ (n) ]]
  then
    echo 'Es wurde nichts verändert'
    echo -e '\033[36mNo modifications was made\033[0m'
else
    echo 'Invalid input!'
fi

echo 'Auf Ihrem Raspberry wurde Shinobi installiert'
echo 'https://raw.githubusercontent.com/steigerbalett/NVR-Pi-install/master/rpi-install.sh'
echo ''
echo -e "\033[36mAccess Shinobi: http://`hostname -I`:8080\033[0m"
echo -e "\033[36mAccess the Raspi-Config-UI Webmin at: http\033[42ms\033[0m\033[1;31m://`hostname -I`:10000\033[0m"
echo -e "\033[36mwith user: pi and your password (raspberry)\033[0m"
echo ''
echo -e "\033[1;31mLegen Sie einen neuen Benutzer an unter: http://`hostname -I`:8080/super User: admin@shinobi.video Passwort: admin\033[0m"
echo -e "\033[1;31mLoggen Sie sich dann bei Shinobi ein unter: http://`hostname -I`:8080\033[0m"
echo ''
echo -e "\033[1;31mLoggen Sie sich in die Raspi-Config-UI Webmin ein: http\033[42ms\033[0m\033[1;31m://`hostname -I`:10000\033[0m"
echo -e "\033[1;31mMit Ihrem Benutzer: pi  und Passwort: (raspberry)\033[0m"
echo ''
# reboot the raspi
echo -e '\033[7mSoll der RaspberryPi jetzt automatisch neu starten?\033[0m'
echo -e '\033[36mShould the the RaspberryPi now reboot directly or do you do this manually later?\033[0m'
echo -n -e '\033[36mDo you want to reboot now [Y/n]\033[0m'
read rebootdecision

if [[ $rebootdecision =~ (J|j|Y|y) ]]
  then
echo ''
echo 'System will reboot in 3 seconds'
sleep 3
sudo shutdown -r now
elif [[ $rebootdecision =~ (n) ]]
  then
    echo 'Please reboot to activate the changes'
else
    echo 'Invalid input!'
fi
echo 'Reboot the RaspberryPi now with: sudo reboot now'
exit
