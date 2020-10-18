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


echo "  _   _  ____    _____   ____   ____ _______   _    _  _____ ______ _____   ";
echo " | \ | |/ __ \  |  __ \ / __ \ / __ \__   __| | |  | |/ ____|  ____|  __ \  ";
echo " |  \| | |  | | | |__) | |  | | |  | | | |    | |  | | (___ | |__  | |__) | ";
echo " | . \` | |  | | |  _  /| |  | | |  | | | |    | |  | |\___ \|  __| |  _  / ";
echo " | |\  | |__| | | | \ \| |__| | |__| | | |    | |__| |____) | |____| | \ \  ";
echo " |_| \_|\____/  |_|  \_\\____/ \____/  |_|     \____/|_____/|______|_|  \_\ ";
echo "                                                                            ";
echo "                                                                            ";
sleep 10


case $1 in
    install)
        clear
        echo "  _____           _        _ _                  ___    ___   ";
        echo " |_   _|         | |      | | |                |__ \  |__ \  ";
        echo "   | |  _ __  ___| |_ __ _| | | ___ _ __  __   __ ) |    ) | ";
        echo "   | | | '_ \/ __| __/ _\` | | |/ _ \ '__| \ \ / // /    / /  ";
        echo "  _| |_| | | \__ \ || (_| | | |  __/ |     \ V // /_ _ / /_  ";
        echo " |_____|_| |_|___/\__\__,_|_|_|\___|_|      \_/|____(_)____| ";
        echo "                                                             ";
        echo "                                                             ";
        echo " "
        sleep .2
        echo "MAKE SURE YOUR SYSTEM IS UPDATED"
        echo "  _   _  ____    _____   ____   ____ _______   _    _  _____ ______ _____   ";
        echo " | \ | |/ __ \  |  __ \ / __ \ / __ \__   __| | |  | |/ ____|  ____|  __ \  ";
        echo " |  \| | |  | | | |__) | |  | | |  | | | |    | |  | | (___ | |__  | |__) | ";
        echo " | . \` | |  | | |  _  /| |  | | |  | | | |    | |  | |\___ \|  __| |  _  / ";
        echo " | |\  | |__| | | | \ \| |__| | |__| | | |    | |__| |____) | |____| | \ \  ";
        echo " |_| \_|\____/  |_|  \_\\____/ \____/  |_|     \____/|_____/|______|_|  \_\ ";
        echo "                                                                            ";
        echo "                                                                            ";
        sleep .5
        read -p "You are about to install BYOB [Y/n]: " agreeTo
        case $agreeTo in
            n|N|no|No|NO)
            echo "  _____           _        _ _                   _                _           _    ";
            echo " |_   _|         | |      | | |                 | |              | |         | |   ";
            echo "   | |  _ __  ___| |_ __ _| | | ___ _ __    __ _| |__   ___  _ __| |_ ___  __| |   ";
            echo "   | | | '_ \/ __| __/ _\` | | |/ _ \ '__|  / _\` | '_ \ / _ \| '__| __/ _ \/ _\` |";
            echo "  _| |_| | | \__ \ || (_| | | |  __/ |    | (_| | |_) | (_) | |  | ||  __/ (_| |   ";
            echo " |_____|_| |_|___/\__\__,_|_|_|\___|_|     \__,_|_.__/ \___/|_|   \__\___|\__,_|   ";
            echo "                                                                                   ";
            echo "                                                                                   ";
            ;;
            *)
            cd && sudo chown -R $USER:$USER ~/* ; sudo chown -R $USER:$USER ~/.*
            read -p "Do you want to update the system? [Y/n]: " updated
            case $updated in
                n|N|no|No|NO)
                echo "Moving on..."
                PATH=$PATH:~/.local/bin
                ;;
                *)
                # Don't do any actions before user agrees to the terms.
                sudo apt update && sudo apt upgrade -y && sudo apt full-upgrade -y
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
            echo "Applying pre-perms to service files"
                sudo cp ~/vrl-package/byob-server.service /etc/systemd/system/ > /dev/null
                sudo cp ~/vrl-package/byob /usr/bin/ > /dev/null
                sudo chown root:root /etc/systemd/system/byob-server.service > /dev/null
                sudo chown root:root /usr/bin/byob > /dev/null
            sleep .5
            echo "  _    _           _       _   _                   ";
            echo " | |  | |         | |     | | (_)                  ";
            echo " | |  | |_ __   __| | __ _| |_ _ _ __   __ _       ";
            echo " | |  | | '_ \ / _\` |/ _\` | __| | '_ \ / _\` |   ";
            echo " | |__| | |_) | (_| | (_| | |_| | | | | (_| |_ _ _ ";
            echo "  \____/| .__/ \__,_|\__,_|\__|_|_| |_|\__, (_|_|_)";
            echo "        | |                             __/ |      ";
            echo "        |_|                            |___/       ";
            sleep .5
            echo "Installing dependencies..."
                echo "Fetching fresh meat..."
                    sudo apt install docker.io \
                    git gcc cmake make upx-ucl \
                    build-essential zlib1g-dev \
                    neofetch htop avahi-daemon -qy  > /dev/null
                echo "Picking python repos..."
                    sudo apt install python3 python3-pip python3-opencv python3-wheel \
                    python3-setuptools python3-dev python3-distutils python3-venv -qy  > /dev/null
                echo "Doing magic..."
                    sudo systemctl start avahi-daemon  > /dev/null
                    sudo systemctl enable avahi-daemon  > /dev/null
                    sudo systemctl start docker  > /dev/null
                    sudo systemctl enable docker > /dev/null
                echo "Cloning vrlnx/BYOB files..."
                    sleep .4
                    git -C ~/ clone https://github.com/vrlnx/byob.git > /dev/null
                echo "Installing BYOB dependencies..."
                    cd ~/byob/byob
                    sleep .5
                    python3 setup.py  > /dev/null
                    pip3 install requirements.txt  > /dev/null
                    pip3 install colorama  > /dev/null
                    pip3 install pyinstaller==3.6  > /dev/null
                    pip3 install numpy > /dev/null
                    pip3 install requests > /dev/null
                    pip3 install flask > /dev/null
                    pip3 install flask_wtf > /dev/null
                    pip3 install flask_mail > /dev/null
                    pip3 install flask-bcrypt > /dev/null
                    pip3 install flask-login > /dev/null
                    pip3 install flask-sqlalchemy > /dev/null
                    cd
                echo "Set permissions..."
                    sleep 2
                    chmod +x ~/vrl-package/uninstaller.sh
                    chmod +x ~/vrl-package/start-byob.sh
                echo "Transfer Ownership..."
                    echo "Current user: $USER"
                    sudo usermod -aG docker $USER > /dev/null
                    sudo chown -R $USER:$USER ~/byob > /dev/null
                    read -p "Are you ready to use the system? (Enter to continue)"
            clear
            echo "  ______     ______  ____    _____           _        _ _          _   ";
            echo " |  _ \ \   / / __ \|  _ \  |_   _|         | |      | | |        | |  ";
            echo " | |_) \ \_/ / |  | | |_) |   | |  _ __  ___| |_ __ _| | | ___  __| |  ";
            echo " |  _ < \   /| |  | |  _ <    | | | '_ \/ __| __/ _\` | | |/ _ \/ _\` |";
            echo " | |_) | | | | |__| | |_) |  _| |_| | | \__ \ || (_| | | |  __/ (_| |  ";
            echo " |____/  |_|  \____/|____/  |_____|_| |_|___/\__\__,_|_|_|\___|\__,_|  ";
            echo "                                                                       ";
            echo "                                                                       ";
            echo " "
            echo "Enabled start-byob.sh"
            echo "Your website will open on ""$HOSTNAME"".local:5000"" when server is started."
            cd ~/vrl-package
            read -p "Do you want to start BYOB - Open Source web-server? [y/N]" webServer
            case $webServer in
                n|N)
                echo "You start BYOB - Open Source Webserver by running"
                echo "'./start-byob.sh' inside 'vrl-package' folder"
                ;;
                *)
                ./start-byob.sh
                ;;
            esac
            ;;
        esac
        ;;
    help)
        echo "DO NOT USE ROOT USER!"
        echo "Commands around this setup:"
        echo "./setup.sh help"
        echo "./setup.sh install - Start installing"
        echo "./setup.sh rules - Show EULA"
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