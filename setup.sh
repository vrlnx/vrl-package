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
        chmod +x uninstaller.sh
        chmod +x start-byob.sh
        sudo chown root:root byob-server.service
        sudo chown root:root byob
        sudo cp byob-server.service /etc/systemd/system/
        sudo cp byob /usr/bin/
        sleep .2
        echo "MAKE SURE YOUR SYSTEM IS UPDATED"
        echo "Not sure? Run ./setup.sh updateMe"
        echo " "
        cd
        echo "Current Directory:"
        pwd
        sleep .5
        read -p "You are about to install BYOB [Yes/No*]: " agreeTo
        case $agreeTo in
            yes|Yes|YES)
            clear
            echo "  __  __       _                              ";
            echo " |  \/  |     | |                             ";
            echo " | \  / | __ _| | _____   _   _ ___  ___ _ __ ";
            echo " | |\/| |/ _\` | |/ / _ \ | | | / __|/ _ \ '__|";
            echo " | |  | | (_| |   <  __/ | |_| \__ \  __/ |   ";
            echo " |_|  |_|\__,_|_|\_\___|  \__,_|___/\___|_|   ";
            echo "                                              ";
            echo "                                              ";
            echo "Adding byob user to your Linux tenant..."
            sudo useradd -r -m -U -d /opt/byob -s /bin/bash byob # Adds the user here
            echo "Finished... Added byob..."
            sleep 3
            clear
            echo "   _____      _                                               _ ";
            echo "  / ____|    | |                                             | |";
            echo " | (___   ___| |_   _ __   __ _ ___ _____      _____  _ __ __| |";
            echo "  \___ \ / _ \ __| | '_ \ / _\` / __/ __\ \ /\ / / _ \| '__/ _\` |";
            echo "  ____) |  __/ |_  | |_) | (_| \__ \__ \\ V  V / (_) | | | (_| |";
            echo " |_____/ \___|\__| | .__/ \__,_|___/___/ \_/\_/ \___/|_|  \__,_|";
            echo "                   | |                                          ";
            echo "                   |_|                                          ";
            echo " "
            echo "It's needed that you set a password..."
            sudo passwd byob
            echo " "
            echo "User created, Password set..."
            sleep .5
            read -p "Have you updated your system? [y/N]" updated
            case $updated in
                y|Y)
                continue
                ;;
                *)
                sudo apt update && sudo apt upgrade -y
                clear
                echo "  _____      _                 _   ";
                echo " |  __ \    | |               | |  ";
                echo " | |__) |___| |__   ___   ___ | |_ ";
                echo " |  _  // _ \ '_ \ / _ \ / _ \| __|";
                echo " | | \ \  __/ |_) | (_) | (_) | |_ ";
                echo " |_|  \_\___|_.__/ \___/ \___/ \__|";
                echo "                                   ";
                echo "                                   ";
                sleep .4
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
            sudo apt install docker -y
            sudo apt install python3 python3-pip python3-opencv -y
            sudo pip3 install flask
            sudo pip3 install flask-bcrypt
            sudo apt install neofetch htop avahi-daemon -y
            sudo systemctl start avahi-daemon
            sudo systemctl enable avahi-daemon
            sudo usermod -aG sudo byob
            cd /opt/byob
            sudo git clone https://github.com/malwaredllc/byob.git
            cd /opt/byob/byob
            python3 setup.py
            pip3 install requirements.txt
            pip3 install colorama
            sleep .3
            clear
            cd
            echo "  _                        _                     ";
            echo " | |                      (_)                    ";
            echo " | |        ___     __ _   _   _ __              ";
            echo " | |       / _ \   / _\` | | | | '_ \             ";
            echo " | |____  | (_) | | (_| | | | | | | |  _   _   _ ";
            echo " |______|  \___/   \__, | |_| |_| |_| (_) (_) (_)";
            echo "                    __/ |                        ";
            echo "                   |___/                         ";
            echo ""
            echo "Run the command"
            echo "#1 './byob/web-gui/startup.sh'"
            sudo chown byob:byob -R /opt/byob
            cd /opt/byob
            sleep .2
            cd
            read -p "Do you want to start web-gui?[y/N]" webGUI
            case $webGUI in
                y)
                clear
                echo "   _____   _                    _     _                             ";
                echo "  / ____| | |                  | |   (_)                            ";
                echo " | (___   | |_    __ _   _ __  | |_   _   _ __     __ _             ";
                echo "  \___ \  | __|  / _\` | | '__| | __| | | | '_ \   / _\` |            ";
                echo "  ____) | | |_  | (_| | | |    | |_  | | | | | | | (_| |  _   _   _ ";
                echo " |_____/   \__|  \__,_| |_|     \__| |_| |_| |_|  \__, | (_) (_) (_)";
                echo "                                                   __/ |            ";
                echo "                                                  |___/             ";
                sleep 1
                cd /opt/byob/web-gui
                echo "Running BYOB - Open Source"
                echo "Hidden mode enabled"
                echo "logfile /opt/byob/bootspool.log"
                ./startup.sh > /opt/byob/bootspool.log
                ;;
                *)
                clear
                echo "  ______     ______  ____    _____           _        _ _          _ ";
                echo " |  _ \ \   / / __ \|  _ \  |_   _|         | |      | | |        | |";
                echo " | |_) \ \_/ / |  | | |_) |   | |  _ __  ___| |_ __ _| | | ___  __| |";
                echo " |  _ < \   /| |  | |  _ <    | | | '_ \/ __| __/ _\` | | |/ _ \/ _\` |";
                echo " | |_) | | | | |__| | |_) |  _| |_| | | \__ \ || (_| | | |  __/ (_| |";
                echo " |____/  |_|  \____/|____/  |_____|_| |_|___/\__\__,_|_|_|\___|\__,_|";
                echo "                                                                     ";
                echo "                                                                     ";
                ;;
            esac
            ;;
            *)
            echo "  _____           _        _ _       _   _                         _                _           _    ";
            echo " |_   _|         | |      | | |     | | (_)                       | |              | |         | |   ";
            echo "   | |  _ __  ___| |_ __ _| | | __ _| |_ _  ___  _ __         __ _| |__   ___  _ __| |_ ___  __| |   ";
            echo "   | | | '_ \/ __| __/ _\` | | |/ _\` | __| |/ _ \| '_ \       / _\` | '_ \ / _ \| '__| __/ _ \/ _\` |   ";
            echo "  _| |_| | | \__ \ || (_| | | | (_| | |_| | (_) | | | |     | (_| | |_) | (_) | |  | ||  __/ (_| |   ";
            echo " |_____|_| |_|___/\__\__,_|_|_|\__,_|\__|_|\___/|_| |_|      \__,_|_.__/ \___/|_|   \__\___|\__,_|   ";
            echo "                                                                                                     ";
            echo "                                                                                                     ";
            ;;
        esac
        ;;
    help)
        echo "DO NOT USE ROOT USER!"
        echo "Commands around this setup:"
        echo "./setup.sh help"
        echo "./setup.sh updateMe - Ready your system before install"
        echo "./setup.sh install - Start installing"
        ;;
    updateme|updateMe|UpdateMe|Updateme)
        sudo apt update && sudo apt upgrade -y
        sudo apt update && sudo apt upgrade -full-upgrade -y
        sudo apt autoremove -y
        clear
        echo "Your system is now ready for install"
        read -p "Do you want to reboot now? [Yes/No*]: " installerNow
        case $installerNow in
            Yes|YES|yes)
            sudo reboot now
            ;;
            *)
            echo "Still HIGHLY recommended to restart the pc."
            echo "To start installing './setup.sh install'"
            ;;
        esac
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
        echo "> use './setup.sh help' to get help"
        ;; 
    *)
    echo "DO NOT USE ROOT USER!"
    echo "> Use './setup.sh rules' to read EULA"
    ;;
esac