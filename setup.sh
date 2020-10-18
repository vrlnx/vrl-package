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
        sudo chown -R $USER:$USER *.*
        cd ~/vrl-package/package-files/
        sudo chmod +x *.*
        cd ~/vrl-package
        sudo cp byob-server.service /etc/systemd/system/
        sudo cp byob /usr/bin/
        sudo chown root:root /etc/systemd/system/byob-server.service
        sudo chown root:root /usr/bin/byob
        sleep .2
        echo "MAKE SURE YOUR SYSTEM IS UPDATED"
        echo ""
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
                sudo apt update && sudo apt upgrade -y && sudo apt upgrade -full-upgrade -y
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
            sleep .5
            # Installing dependencies
            cd ~/vrl-package/package-files/
            ./git-byob-clone.sh
            ./python-install.sh
            ./permissions.sh
            ./ownership.sh
            sleep 1
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
            cd $HOME/vrl-package
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