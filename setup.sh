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
        sudo chown $USER:$USER /etc/systemd/system/byob-server.service
        sudo chown $USER:$USER /usr/bin/byob
        sleep .2
        echo "MAKE SURE YOUR SYSTEM IS UPDATED"
        cd
        echo "Current Directory:"
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
            clear
            echo "  __  __       _                              ";
            echo " |  \/  |     | |                             ";
            echo " | \  / | __ _| | _____   _   _ ___  ___ _ __ ";
            echo " | |\/| |/ _\` | |/ / _ \ | | | / __|/ _ \ '__|";
            echo " | |  | | (_| |   <  __/ | |_| \__ \  __/ |   ";
            echo " |_|  |_|\__,_|_|\_\___|  \__,_|___/\___|_|   ";
            echo "                                              ";
            echo "                                              ";
            echo "Setting up $USER to with your Linux tenant..."
            sudo usermod -aG sudo $USER
            sudo usermod -aG docker $USER
            echo "Finished... $USER is linked now..."
            sleep 1
            echo " "
            echo " "
            echo " "
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
                sleep .2
                read -p "Your system must now reboot (Press [enter])"
                sudo reboot now
                ;;
            esac
            clear
            echo "  _    _           _       _   _                   ";
            echo " | |  | |         | |     | | (_)                  ";
            echo " | |  | |_ __   __| | __ _| |_ _ _ __   __ _       ";
            echo " | |  | | '_ \ / _\` |/ _\` | __| | '_ \ / _\` |      ";
            echo " | |__| | |_) | (_| | (_| | |_| | | | | (_| |_ _ _ ";
            echo "  \____/| .__/ \__,_|\__,_|\__|_|_| |_|\__, (_|_|_)";
            echo "        | |                             __/ |      ";
            echo "        |_|                            |___/       ";
            echo "Installing dependencies..."
            sleep .3
            touch ~/bootspool.log
            sudo apt install docker gcc cmake make upx-ucl build-essential zlib1g-dev neofetch htop avahi-daemon -y
            sudo apt install python3 python3-pip python3-opencv python3-wheel python3-setuptools python3-dev python3-distutils python3-venv -y
            sudo systemctl start avahi-daemon
            sudo systemctl enable avahi-daemon
            sudo usermod -aG docker $USER
            git -C ~/ clone https://github.com/vrlnx/byob.git
            cd ~/byob/byob
            python3 setup.py
            pip3 install requirements.txt
            pip3 install colorama
            pip3 pyinstaller==3.6
            pip3 install flask
            pip3 install flask-bcrypt
            pip3 install flask-login
            pip3 install flask-sqlalchemy
            sleep .3
            chmod +x ~/byob/web-gui/startup.sh
            sleep .2
            cd ~/vrl-package
            clear
            chmod +x uninstaller.sh
            chmod +x start-byob.sh
            cd
            echo "  ______     ______  ____    _____           _        _ _          _ ";
            echo " |  _ \ \   / / __ \|  _ \  |_   _|         | |      | | |        | |";
            echo " | |_) \ \_/ / |  | | |_) |   | |  _ __  ___| |_ __ _| | | ___  __| |";
            echo " |  _ < \   /| |  | |  _ <    | | | '_ \/ __| __/ _\` | | |/ _ \/ _\` |";
            echo " | |_) | | | | |__| | |_) |  _| |_| | | \__ \ || (_| | | |  __/ (_| |";
            echo " |____/  |_|  \____/|____/  |_____|_| |_|___/\__\__,_|_|_|\___|\__,_|";
            echo "                                                                     ";
            echo "                                                                     ";
            echo ""
            sleep .2
            echo "Run the command"
            echo "#1 'sudo su byob'"
            echo "#2 'cd'"
            echo "#3 'cd byob/web-gui'"
            echo "#4 './startup.sh'"
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