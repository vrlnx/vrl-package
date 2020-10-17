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
        echo "                                                                             ";
        echo "                                                                             ";
        echo "BBBBBBBBBBBBBBBBB  YYYYYYY       YYYYYYY    OOOOOOOOO    BBBBBBBBBBBBBBBBB   ";
        echo "B::::::::::::::::B Y:::::Y       Y:::::Y  OO:::::::::OO  B::::::::::::::::B  ";
        echo "B::::::BBBBBB:::::BY:::::Y       Y:::::YOO:::::::::::::OOB::::::BBBBBB:::::B ";
        echo "BB:::::B     B:::::Y::::::Y     Y::::::O:::::::OOO:::::::BB:::::B     B:::::B";
        echo "  B::::B     B:::::YYY:::::Y   Y:::::YYO::::::O   O::::::O B::::B     B:::::B";
        echo "  B::::B     B:::::B  Y:::::Y Y:::::Y  O:::::O     O:::::O B::::B     B:::::B";
        echo "  B::::BBBBBB:::::B    Y:::::Y:::::Y   O:::::O     O:::::O B::::BBBBBB:::::B ";
        echo "  B:::::::::::::BB      Y:::::::::Y    O:::::O     O:::::O B:::::::::::::BB  ";
        echo "  B::::BBBBBB:::::B      Y:::::::Y     O:::::O     O:::::O B::::BBBBBB:::::B ";
        echo "  B::::B     B:::::B      Y:::::Y      O:::::O     O:::::O B::::B     B:::::B";
        echo "  B::::B     B:::::B      Y:::::Y      O:::::O     O:::::O B::::B     B:::::B";
        echo "  B::::B     B:::::B      Y:::::Y      O::::::O   O::::::O B::::B     B:::::B";
        echo "BB:::::BBBBBB::::::B      Y:::::Y      O:::::::OOO:::::::BB:::::BBBBBB::::::B";
        echo "B:::::::::::::::::B    YYYY:::::YYYY    OO:::::::::::::OOB:::::::::::::::::B ";
        echo "B::::::::::::::::B     Y:::::::::::Y      OO:::::::::OO  B::::::::::::::::B  ";
        echo "BBBBBBBBBBBBBBBBB      YYYYYYYYYYYYY        OOOOOOOOO    BBBBBBBBBBBBBBBBB   ";
        echo "                                                                             ";
        echo "                                                                             ";
        echo "                                                                             ";
        echo "  _____                 _             _   _                   ";
        echo " |_   _|               | |           | | | |                  ";
        echo "   | |    _ __    ___  | |_    __ _  | | | |   ___   _ __     ";
        echo "   | |   | '_ \  / __| | __|  / _\` | | | | |  / _ \ | '__|   ";
        echo "  _| |_  | | | | \__ \ | |_  | (_| | | | | | |  __/ | |       ";
        echo " |_____| |_| |_| |___/  \__|  \__,_| |_| |_|  \___| |_|       ";
        echo "                                                              ";
        echo "  for Raspi, Ubuntu, PopOS or Debian-base                     ";
        echo " "
        sleep 1
        echo "MAKE SURE YOUR SYSTEM IS UPDATED"
        echo "Not sure? Run ./setup.sh updateMe"
        echo " "
        cd
        echo "Current Directory:"
        pwd
        sleep 3
        read -p "You are about to install a new BYOB user [Yes/No*]: " agreeTo
        case $agreeTo in
            yes|Yes|YES)
            echo "Adding byob user to your Linux tenant..."
            sudo useradd -r -m -U -d /opt/byob -s /bin/bash byob # Adds the user here
            echo "Finished... Added byob..."
            sudo cp ~/vrl-package/clone-install.sh /opt/byob/installer.sh
            sudo cp ~/vrl-package/packageBoot.sh /opt/byob/run.sh
            sudo chown byob:byob /opt/byob/installer.sh
            echo " "
            echo "It's needed that you set a password"
            sudo passwd byob
            echo " "
            echo "User created, Password set..."
            echo "Initilize install..."
            sudo apt update && sudo apt upgrade -y
            echo ""
            echo "Installing Docker..."
            sudo apt install docker -y
            echo "Installing Python3..."
            sudo apt install python3 python3-pip python3-opencv -y
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
            sleep 2
            echo ""
            echo "Do you want to install extra debug and local discovery tools."
            echo "That will help if you need help"
            echo " "
            read -p "You choose (Highly Recommended)[Yes/No*]: " chooseIt
            case $chooseIt in
                Yes|yes|YES)
                echo "Installing debug tools"
                sudo apt install neofetch htop avahi-daemon -y
                ;;
                *)
                echo " "
                echo "Skipping tools..."
                echo " "
                ;;
            esac
            clear
            echo "  _                        _                     ";
            echo " | |                      (_)                    ";
            echo " | |        ___     __ _   _   _ __              ";
            echo " | |       / _ \   / _\` | | | | '_ \             ";
            echo " | |____  | (_) | | (_| | | | | | | |  _   _   _ ";
            echo " |______|  \___/   \__, | |_| |_| |_| (_) (_) (_)";
            echo "                    __/ |                        ";
            echo "                   |___/                         ";
            echo ""
            echo "Continue by running the next script."
            echo "Run 'cd'"
            echo "After then"
            echo "chmod +x installer.sh"
            echo "After then"
            echo "Run './installer.sh'"
            sleep 5
            sudo su byob
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
        clear
        sudo apt update && sudo apt upgrade -y
        sudo apt autoremove -y
        echo " "
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