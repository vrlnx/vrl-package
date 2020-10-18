#!/bin/bash
#  ________   _____________   _____                           _             
#  | ___ \ \ / |  _  | ___ \ |  __ \                         | |            
#  | |_/ /\ V /| | | | |_/ / | |  \/ ___ _ __   ___ _ __ __ _| |_ ___  _ __ 
#  | ___ \ \ / | | | | ___ \ | | __ / _ | '_ \ / _ | '__/ _` | __/ _ \| '__|
#  | |_/ / | | \ \_/ | |_/ / | |_\ |  __| | | |  __| | | (_| | || (_) | |   
#  \____/  \_/  \___/\____/   \____/\___|_| |_|\___|_|  \__,_|\__\___/|_|   
#                                                                           
#                                                                           
#   _             _   _______ _     _                  
#  | |           | | | | ___ | |   (_)                 
#  | |__  _   _  | | | | |_/ | |    _ _ __  _   ___  __
#  | '_ \| | | | | | | |    /| |   | | '_ \| | | \ \/ /
#  | |_) | |_| | \ \_/ | |\ \| |___| | | | | |_| |>  < 
#  |_.__/ \__, |  \___/\_| \_\_____|_|_| |_|\__,_/_/\_\
#          __/ |                                       
#         |___/                                        
#
# vrlinux's automatic BYOB setup 
# for Raspi, Ubuntu and any Debian-base using .deb or apt
# 
# VRLinux is not apart of the BYOB and will not identify as a member of staff.
#
# Description
# BYOB can be tricky to install. I've collected community data
# and made this tool to help the community.
#
#
#   _____      _               _ 
#  |  ___|    (_)             | |
#  | |__ _ __  _  ___  _   _  | |
#  |  __| '_ \| |/ _ \| | | | | |
#  | |__| | | | | (_) | |_| | |_|
#  \____|_| |_| |\___/ \__, | (_)
#            _/ |       __/ |    
#           |__/       |___/     


case $1 in
    install)
        clear
        echo "  _____           _        _ _                  ___    ___  ";
        echo " |_   _|         | |      | | |                |__ \  / _ \ ";
        echo "   | |  _ __  ___| |_ __ _| | | ___ _ __  __   __ ) || | | |";
        echo "   | | | '_ \/ __| __/ _\` | | |/ _ \ '__| \ \ / // / | | | |";
        echo "  _| |_| | | \__ \ || (_| | | |  __/ |     \ V // /_ | |_| |";
        echo " |_____|_| |_|___/\__\__,_|_|_|\___|_|      \_/|____(_)___/ ";
        echo "                                                            ";
        echo "                                                            ";
        echo " "
        sudo cp byob-server.service /etc/systemd/system/
        sudo cp byob /usr/bin/
        sudo chown root:root /etc/systemd/system/byob-server.service
        sudo chown root:root /usr/bin/byob
        sleep .2
        echo "MAKE SURE YOUR SYSTEM IS UPDATED"
        echo "Current Directory:"
        cd ~
        pwd
        sleep .5
        read -p "You are about to install BYOB [Y/n]: " agreeTo
        case $agreeTo in
            n|N)
            echo "  _____           _        _ _       _                             _ ";
            echo " |_   _|         | |      | | |     | |                           | |";
            echo "   | |  _ __  ___| |_ __ _| | |  ___| |_ ___  _ __  _ __   ___  __| |";
            echo "   | | | '_ \/ __| __/ _\` | | | / __| __/ _ \| '_ \| '_ \ / _ \/ _\` |";
            echo "  _| |_| | | \__ \ || (_| | | | \__ \ || (_) | |_) | |_) |  __/ (_| |";
            echo " |_____|_| |_|___/\__\__,_|_|_| |___/\__\___/| .__/| .__/ \___|\__,_|";
            echo "                                             | |   | |               ";
            echo "                                             |_|   |_|               ";
            ;;
            *)
            read -p "Have you upgraded or updated your system? [y/N]" updated
            case $updated in
                y|Y)
                continue
                ;;
                *)
                sudo apt update && sudo apt upgrade -y
                sudo apt update && sudo apt upgrade -full-upgrade -y
                sudo apt autoremove -y
                clear
                echo "  _____      _                 _   ";
                echo " |  __ \    | |               | |  ";
                echo " | |__) |___| |__   ___   ___ | |_ ";
                echo " |  _  // _ \ '_ \ / _ \ / _ \| __|";
                echo " | | \ \  __/ |_) | (_) | (_) | |_ ";
                echo " |_|  \_\___|_.__/ \___/ \___/ \__|";
                echo "                                   ";
                echo "                                   ";
                read -p "Your system must now reboot (Press [enter])"
                sudo reboot now
                ;;
            esac
            clear
            echo "  _    _           _       _   _                   ";
            echo " | |  | |         | |     | | (_)                  ";
            echo " | |  | |_ __   __| | __ _| |_ _ _ __   __ _       ";
            echo " | |  | | '_ \ / _\` |/ _\` | __| | '_ \ / _\` |   ";
            echo " | |__| | |_) | (_| | (_| | |_| | | | | (_| |_ _ _ ";
            echo "  \____/| .__/ \__,_|\__,_|\__|_|_| |_|\__, (_|_|_)";
            echo "        | |                             __/ |      ";
            echo "        |_|                            |___/       ";
            echo "Installing dependencies..."
            # Installing dependencies
            sudo apt install docker gcc cmake make upx-ucl build-essential zlib1g-dev neofetch htop avahi-daemon -y
            sudo apt install python3 python3-pip python3-opencv python3-wheel python3-setuptools python3-dev python3-distutils python3-venv -y
            sudo systemctl start avahi-daemon
            sudo systemctl enable avahi-daemon
            sudo systemctl start docker
            sudo systemctl enable docker
            # Adding user to docker group
            sudo usermod -aG docker $USER
            newgrp docker
            # Downloading latest git
            git -C ~/ clone https://github.com/vrlnx/byob.git
            sleep .1
            # Probing python3 dependencies
            cd ~/byob/byob
            python3 setup.py
            # Installing pip3 python add-ons
            pip3 install requirements.txt
            pip3 install colorama
            pip3 pyinstaller==3.6
            pip3 install flask
            pip3 install flask-bcrypt
            pip3 install flask-login
            pip3 install flask-sqlalchemy
            cd ~
            # Making linux files executable
            chmod +x ~/byob/web-gui/startup.sh
            chmod +x ~/vrl-package/uninstaller.sh
            chmod +x ~/vrl-package/start-byob.sh
            # Add ownership to the byob folder
            sudo chown -R $USER:$USER ~/byob
            # Finish the script with fancy message
            echo "Enabled uninstaller and start-byob files"
            clear
            sleep .5
            echo "  ______     ______  ____    _____           _        _ _          _   ";
            echo " |  _ \ \   / / __ \|  _ \  |_   _|         | |      | | |        | |  ";
            echo " | |_) \ \_/ / |  | | |_) |   | |  _ __  ___| |_ __ _| | | ___  __| |  ";
            echo " |  _ < \   /| |  | |  _ <    | | | '_ \/ __| __/ _\` | | |/ _ \/ _\` |";
            echo " | |_) | | | | |__| | |_) |  _| |_| | | \__ \ || (_| | | |  __/ (_| |  ";
            echo " |____/  |_|  \____/|____/  |_____|_| |_|___/\__\__,_|_|_|\___|\__,_|  ";
            echo "                                                                       ";
            echo "                                                                       ";
            echo " "
            cd ~/vrl-package
            echo "Run the following cmd"
            echo "#1 './start-byob.sh'"
            ;;
        esac
        ;;
    help)
        echo "DO NOT USE ROOT USER!"
        echo "Commands around this setup:"
        echo "./setup.sh help"
        echo "./setup.sh install - Start installing"
        ;;
    rules)
        echo "DO NOT USE ROOT USER!"
        echo ""
        echo "VRLinux, the owner, support team,"
        echo "or anyone else is not responsible for your use of this framework."
        echo ""
        echo "Use common sense, if you think it's against the rules, don't do it."
        echo "By reading messages you are agreeing to this."
        echo ""
        echo "> use './setup.sh install' to start installing"
        ;; 
    *)
    echo "DO NOT USE ROOT USER!"
    echo "> Use './setup.sh rules' to read EULA"
    ;;
esac