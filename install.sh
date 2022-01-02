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
echo -e "\033[1;31mVERSION: 2022-01-02\033[0m"
echo -e "\033[1;31mShinobi installer aka NVR-Pi\033[0m"
sleep 3

# Make sure script is run as root.
echo ''
echo 'Checking root status ...'
echo ''
if [ "$(id -u)" != "0" ]; then
    echo -e "\033[1;31mDas Script muss als root ausgeführt werden, sudo./install.sh\033[0m"
    echo -e '\033[36mMust be run as root with sudo! Try: sudo ./install.sh\033[0m'
  exit 1
fi

#Checking Memory Requirements
echo ''
echo "Checking minimum system memory requirements ..."
echo ''
memtotal=$(cat /proc/meminfo | grep MemTotal | grep -o '[0-9]*')
swaptotal=$(cat /proc/meminfo | grep SwapTotal | grep -o '[0-9]*')
echo "Your total system memory is $memtotal"
echo "Your total system swap is $swaptotal"
totalmem=$(($memtotal + $swaptotal))
echo "Your effective total system memory is $totalmem"

if [[ $totalmem -lt 900000 ]]
  then
    echo 'You have low memory'
  else
    echo 'You have enough memory to meet the requirements! :-)'
fi
    echo ''
    echo -n 'Do you want to create a 1 G swap file? [Y/n] '
    echo ''
    read swapfiledecision
      if [[ $swapfiledecision =~ (Y|y) ]]
        then
          echo 'Creating 1 G swap file...'
            sudo fallocate -l 1G /swapfile
            sudo chmod 600 /swapfile
            sudo mkswap /swapfile
            sudo swapon /swapfile
            sudo cp /etc/fstab /etc/fstab.bak
            echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab > /dev/null
          echo '1 G swap file successfully created!'
      elif [[ $swapfiledecision =~ (n) ]]
        then
          echo 'No swap file was created!'
      else
        echo Input error!
        echo No swap file was created!
        echo Please start again
      fi


echo 'Step 1:' 
echo "Installing dependencies..."
echo "=========================="
echo ''
apt update
apt -y full-upgrade
apt -y install ntfs-3g hdparm hfsutils hfsprogs exfat-fuse git ntpdate proftpd samba wget build-essential
echo "updating date and time"
sudo ntpdate -u de.pool.ntp.org 

# Einstellen der Zeitzone und Zeitsynchronisierung per Internet: Berlin
sudo timedatectl set-timezone Europe/Berlin
sudo timedatectl set-ntp true

# Konfigurieren der lokale Sprache: deutsch 
sudo sed -i -e 's/# de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen 
sudo locale-gen 
sudo localectl set-locale LANG=de_DE.UTF-8 LANGUAGE=de_DE

# SSH dauerhaft aktivieren für Fernzugriff
sudo systemctl enable ssh.service
sudo systemctl start ssh.service

echo ''
echo ''
echo ''
echo ''
echo ''
echo 'Step 2:' 
echo -e '\033[5mShinobi installieren\033[0m'
echo "=========================="
echo ''
echo 'Empfohlene Auswahl:'
echo ''
echo 'if asked, choose:'
echo 'Dashboard V3 [1]'
echo ''
echo '1. Ubuntu - Fast and Touchless [1]'
echo ''
echo 'disable ipv6: No [n]'
echo ''
echo ''
echo ''
echo ''
echo ''
sleep 3

#cd /tmp
#bash <(curl -s https://gitlab.com/Shinobi-Systems/Shinobi-Installer/raw/master/shinobi-install.sh)

#Node.ja V17.x
sudo curl -fsSL https://deb.nodesource.com/setup_17.x | bash -
sudo apt update
sudo apt install -y nodejs
sudo npm install npm@latest

cd /home
if [ ! -d "Shinobi" ]; then
    theRepo=''
    productName="Shinobi"
    echo "Which branch do you want to install?"
    echo "(1) New (V3 - needed for MQTT)"
    echo "(2) Standard (V2)"
    echo "(3) Beta"
    read theBranchChoice
    if [ "$theBranchChoice" = "3" ]; then
        echo "Getting the Development Branch"
        theBranch='dev'
    elif [ "$theBranchChoice" = "2" ]; then
        echo "Getting the Master Branch"
        theBranch='master'
    elif [ "$theBranchChoice" = "1" ]; then
        echo "Getting the V3 Branch"
        theBranch='dashboard-v3'
    else
    echo "Invalid input!"
    fi
        
    # Download from Git repository
    gitURL="https://gitlab.com/Shinobi-Systems/Shinobi$theRepo"
    sudo git clone $gitURL.git -b $theBranch Shinobi
    # Enter Shinobi folder "/home/Shinobi"
    cd Shinobi
    gitVersionNumber=$(git rev-parse HEAD)
    theDateRightNow=$(date)
    # write the version.json file for the main app to use
    sudo touch version.json
    sudo chmod 777 version.json
    sudo echo '{"Product" : "'"$productName"'" , "Branch" : "'"$theBranch"'" , "Version" : "'"$gitVersionNumber"'" , "Date" : "'"$theDateRightNow"'" , "Repository" : "'"$gitURL"'"}' > version.json
    echo "-------------------------------------"
    echo "---------- Shinobi Systems ----------"
    echo "Repository : $gitURL"
    echo "Product : $productName"
    echo "Branch : $theBranch"
    echo "Version : $gitVersionNumber"
    echo "Date : $theDateRightNow"
    echo "-------------------------------------"
    echo "-------------------------------------"  
else
    echo "!-----------------------------------!"
    echo "Shinobi already downloaded. Please restart from scratch. Shinobi is restarting now ..."
fi
# start the installer in the main app (or start shinobi if already installed)
echo "*-----------------------------------*"
sudo chmod +x INSTALL/start.sh
sudo INSTALL/start.sh

echo 'MQTT for Shinobi'
echo ''
echo 'Installation of optional MQTT (recommend)'
echo ''
echo -n -e '\033[7mMöchten Sie MQTT aktivieren? [J/n]\033[0m'
echo ''
echo -n -e '\033[36mDo you want to activate MQTT? [Y/n]\033[0m'
echo ''
echo ''
echo ''
echo ''
echo ''
read mqttdecision

if [[ $mqttdecision =~ (J|j|Y|y) ]]
  then
# mqtt
sudo curl -o ./libs/customAutoLoad/mqtt.js https://gitlab.com/geerd/shinobi-mqtt/raw/master/mqtt.js
npm install mqtt
node tools/modifyConfiguration.js addToConfig='{"mqttClient":true}'
pm2 restart camera.js
elif [[ $mqttdecision =~ (n) ]]
  then
    echo 'Es wurde nichts verändert'
    echo -e '\033[36mNo modifications was made\033[0m'
else
    echo 'Invalid input!'
fi

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

echo "Disable search for SD after USB boot"
echo "========================"
echo "" >> /boot/config.txt
echo "# stopp searching for SD-Card after boot" >> /boot/config.txt
echo "dtoverlay=sdtweak,poll_once" >> /boot/config.txt

# enable additional admin programs
echo 'Step 4: Optionales Admin Programm'
echo 'Installation of optional Raspberry-Config UI: Webmin (recommend)'
echo ''
echo -n -e '\033[7mMöchten Sie Webmin installieren (empfohlen) [J/n]\033[0m'
echo ''
echo -n -e '\033[36mDo you want to install Webmin [Y/n]\033[0m'
echo ''
echo ''
echo ''
echo ''
echo ''
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

echo 'Step 5: Optionaler Dateiexplorer'
echo ''
echo 'Installation of optional Raspberry-Filemanager: Midnight Commander (recommend)'
echo 'https://www.linode.com/docs/guides/how-to-install-midnight-commander/'
echo ''
echo -n -e '\033[7mMöchten Sie Midnight Commander installieren (empfohlen) [J/n]\033[0m'
echo ''
echo -n -e '\033[36mDo you want to install Midnight Commander [Y/n]\033[0m'
echo ''
echo ''
echo ''
echo ''
echo ''
read mcdecision

if [[ $mcdecision =~ (J|j|Y|y) ]]
  then
sudo apt install mc -y
elif [[ $mcdecision =~ (n) ]]
  then
    echo 'Es wurde nichts verändert'
    echo -e '\033[36mNo modifications was made\033[0m'
else
    echo 'Invalid input!'
fi

# enable USB-Drive autostart
echo 'Step 6:'
echo 'USB-Festplatte automatisch nutzen. Bitte vorher die USB-Festplatte in exFAT formatieren, mit Label "NVR" versehen und vor der Installation anschließen'
echo 'Enable automatic use of an exFAT formated and with NVR labled USB-HDD as storage(recommend)'
echo ''
echo -n -e '\033[7mMöchten Sie; dass eine per USB angeschlossene "NVR" Festplatte automatisch benutzt wird? (empfohlen) [J/n]\033[0m'
echo ''
echo -n -e '\033[36mDo you want to use "NVR" USB-Disk as storage? [Y/n]\033[0m'
echo ''
echo ''
echo ''
echo ''
echo ''
read usbdiskdecision

if [[ $usbdiskdecision =~ (J|j|Y|y) ]]
  then
sudo echo "LABEL=NVR    /media/nvr   exfat    uid=pi,gid=pi,auto,noatime,sync,users,rw,dev,exec,suid,nofail  0       1" >> /etc/fstab
sudo sed -i 's/second/USB-HDD/' /home/Shinobi/conf.json
sudo sed -i 's!__DIR__/videos2!/media/nvr!' /home/Shinobi/conf.json
elif [[ $usbdiskdecision =~ (n) ]]
  then
    echo 'Es wurde nichts verändert'
    echo -e '\033[36mNo modifications was made\033[0m'
else
    echo 'Invalid input!'
fi

# enable weekly reboot
echo 'Step 7:'
echo 'RaspberryPi jeden Sonntag um 03:15 Uhr neustarten (nicht wirklich notwendig)'
echo 'Enable automatic reboot every sunday at 3:15 am (n)'
echo ''
echo -n -e '\033[7mSoll der RaspberryPi jeden Sonntag um 03:15 Uhr automatisch neu starten? [J/n]\033[0m'
echo ''
echo -n -e '\033[36mDo you want to set automatic restart every sunday at 03:15 am every day? [Y/n]\033[0m'
echo ''
echo ''
echo ''
echo ''
echo ''
read cronbootdecision

if [[ $cronbootdecision =~ (J|j|Y|y) ]]
  then
sudo echo "*/15 3 * * 0   root     shutdown -r now" >> /etc/crontab
elif [[ $cronbootdecision =~ (N|n) ]]
  then
    echo 'Es wurde nichts verändert'
    echo -e '\033[36mNo modifications was made\033[0m'
else
    echo 'Invalid input!'
fi

# Hostname setzen
sudo hostnamectl set-hostname nvrpi

echo ''
echo ''
echo ''
echo '########################################################'
echo '########################################################'
echo ''
echo ''
echo 'Auf Ihrem Raspberry wurde Shinobi installiert'
echo 'https://raw.githubusercontent.com/steigerbalett/NVR-Pi-install/master/rpi-install.sh'
echo ''
echo ''
echo -e "\033[36mAccess Shinobi: http://`hostname -I`:8080\033[0m"
echo ''
echo -e "\033[36mAccess the Raspi-Config-UI Webmin at: http\033[42ms\033[0m\033[1;31m://`hostname -I`:10000\033[0m"
echo ''
echo -e "\033[36mwith user: pi and your password (raspberry)\033[0m"
echo ''
echo -e "\033[1;31mYou could start Midnight Commander by typing: mc\033[0m"
echo ''
echo ''
echo ''
echo ''
echo ''
echo ''
echo -e "\033[1;31mLegen Sie einen neuen Benutzer an unter: http://`hostname -I`:8080/super User: admin@shinobi.video Passwort: admin\033[0m"
echo ''
echo -e "\033[1;31mLoggen Sie sich dann bei Shinobi ein unter: http://`hostname -I`:8080\033[0m"
echo ''
echo -e "\033[1;31mLoggen Sie sich in die Raspi-Config-UI Webmin ein: http\033[42ms\033[0m\033[1;31m://`hostname -I`:10000\033[0m"
echo ''
echo -e "\033[1;31mMit Ihrem Benutzer: pi  und Passwort: (raspberry)\033[0m"
echo ''
echo -e "\033[1;31mMidnight Commander kann einfach gestartet werden mit: mc\033[0m"
echo ''
echo ''
echo ''
echo ''
echo ''
echo '########################################################'
echo '########################################################'
echo ''
# reboot the raspi
echo -e '\033[7mSoll der RaspberryPi jetzt automatisch neu starten?\033[0m'
echo -e '\033[36mShould the the RaspberryPi now reboot directly or do you do this manually later?\033[0m'
echo -n -e '\033[36mDo you want to reboot now [Y/n]\033[0m'
echo ''
echo ''
echo ''
echo ''
echo ''
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
echo ''
echo ''
echo ''
echo ''
echo ''
echo 'Reboot the RaspberryPi now with: sudo reboot now'
echo ''
echo ''
echo ''
echo ''
echo ''
echo ''
exit
