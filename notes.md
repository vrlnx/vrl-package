#!/bin/bash
# Quickfix
sudo apt update && sudo apt upgrade -y
sudo systemctl start docker
sudo systemctl enable docker
sudo apt install pyinstaller -y
sudo apt install python3 -y
sudo apt install python3-pip -y

### Though prossess
> start here
> update and upgrade
> install avahi-daemon
> start avahi-daemon and enable
> install git
> install docker
> start and enable docker
> get python3, pip3 and pyinstaller
> get pip3 requierments.txt
> get pip3 colorama
> make byob user
> cd to byob folder
> sudo git clone byob
> chown byob -R /opt/byob
> 



    # 
    # Make a system service
    # Allows for quick access to BYOB
    # To get access to this feature, uncomment the area below
    #
    # cp ~/vrl-package/byob-server.service /etc/systemd/system/
    # sudo chown root:root /etc/systemd/system/byob-server.service
    # sudo systemctl daemon-reload
    # sudo cp ~/vrl-package/byob.sh /usr/bin/byob
    # sudo chmod +x /usr/bin/byob
    # sudo chown root:root /usr/bin/byob
    #