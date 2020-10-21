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
USERNAME = $USER
if [ $USERNAME == "root" ]; then
    clear
    echo "          DO NOT USE ROOT      DO NOT USE ROOT          DO NOT USE ROOT            ";
    echo "  _____           _        _ _                   _                _           _    ";
    echo " |_   _|         | |      | | |                 | |              | |         | |   ";
    echo "   | |  _ __  ___| |_ __ _| | | ___ _ __    __ _| |__   ___  _ __| |_ ___  __| |   ";
    echo "   | | | '_ \/ __| __/ _\` | | |/ _ \ '__|  / _\` | '_ \ / _ \| '__| __/ _ \/ _\` |";
    echo "  _| |_| | | \__ \ || (_| | | |  __/ |    | (_| | |_) | (_) | |  | ||  __/ (_| |   ";
    echo " |_____|_| |_|___/\__\__,_|_|_|\___|_|     \__,_|_.__/ \___/|_|   \__\___|\__,_|   ";
    echo "                                                                                   ";
    echo "                                                                                   ";
    echo "          DO NOT USE ROOT      DO NOT USE ROOT          DO NOT USE ROOT            ";
    exit
fi
case $1 in
    install)
    clear
        echo " __      _______  _        _____           _        _ _            ";
        echo " \ \    / /  __ \| |      |_   _|         | |      | | |           ";
        echo "  \ \  / /| |__) | |        | |  _ __  ___| |_ __ _| | | ___ _ __  ";
        echo "   \ \/ / |  _  /| |        | | | '_ \/ __| __/ _\` | | |/ _ \ '__| ";
        echo "    \  /  | | \ \| |____   _| |_| | | \__ \ || (_| | | |  __/ |    ";
        echo "     \/   |_|  \_\______| |_____|_| |_|___/\__\__,_|_|_|\___|_|    ";
        echo "                                                                   ";
        echo "                                                                   ";
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
            if ! sudo apt update | grep -woc "All packages are up to date"; then
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
                exit
            fi
            echo "Applying pre-perms to service files"
            sudo cp ~/vrl-package/byob.service /etc/systemd/system/ \
            ; sudo cp ~/vrl-package/byob /usr/bin/ \
            ; sudo chown root:root /usr/bin/byob \
            ; sudo chmod 755 /usr/bin/byob \
            ; sudo chown root:root /etc/systemd/system/byob.service > /dev/null
            clear
            echo "  _    _           _       _   _                   ";
            echo " | |  | |         | |     | | (_)                  ";
            echo " | |  | |_ __   __| | __ _| |_ _ _ __   __ _       ";
            echo " | |  | | '_ \ / _\` |/ _\` | __| | '_ \ / _\` |   ";
            echo " | |__| | |_) | (_| | (_| | |_| | | | | (_| |_ _ _ ";
            echo "  \____/| .__/ \__,_|\__,_|\__|_|_| |_|\__, (_|_|_)";
            echo "        | |                             __/ |      ";
            echo "        |_|                            |___/       ";
            echo "Fetching fresh meat..."
            sleep .5
            echo "Doing magic..."
            echo " "
            echo "Sit back and enjoy a drink, this may take a while..."
            echo "Do not cancel... (If not installed after 1 hour, then there is trouble...)"
            echo "Slow PC even longer..."
            sudo xargs apt install -y < req.txt > /dev/null \
            ; sudo systemctl start avahi-daemon > /dev/null \
            ; sudo systemctl enable avahi-daemon > /dev/null \
            ; sudo systemctl start docker > /dev/null \
            ; sudo systemctl enable docker > /dev/null \
            ; git -C ~/ clone https://github.com/vrlnx/byob.git > /dev/null \
            ; cd ~/byob/byob \
            ; python3 ~/byob/byob/setup.py > /dev/null \
            ; python3 -m pip install -r requirements.txt > /dev/null \
            ; cd ~/vrl-package \
            ; python3 -m pip install -r reqs-pip.txt > /dev/null \
            ; cd \
            ; chmod +x ~/vrl-package/uninstaller.sh \
            ; chmod +x ~/vrl-package/start-byob.sh \
            ; sudo usermod -aG docker $USERNAME  > /dev/null
            chmod -x ~/vrl-package/setup.sh
            PATH=$PATH:/home/$USERNAME/.local/bin
            sudo chown $USER:$USER -R /home/$USER/byob
            sudo chown $USER:$USER /home/$USER/bootspool.log
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
            echo "#1 Type 'newgrp docker', hit enter"
            echo "#2 Type './start-byob.sh', hit enter"
            cd ~/vrl-package
            ;;
        esac
        ;;
    help)
        clear
        echo "Commands around this setup:"
        echo "./setup.sh help"
        echo "./setup.sh install - Start installing"
        echo "./setup.sh rules - Show EULA"
        ;;
    rules)
        clear
        echo "vrl-package TOS (Terms of Service)"
        echo " "
        echo "VRLinux, the owner of byob, support team,"
        echo "or anyone else is not responsible for your use of this framework."
        echo ""
        echo "Use common sense, if you think it's against the rules, don't do it."
        echo "By reading messages you are agreeing to this."
        echo ""
        echo "> use './setup.sh install' to start installing"
        ;; 
    *)
    clear
    echo "> Welcome to VRL Installer"
    echo "> This installer need you to read our rules."
    echo "> Type './setup.sh rules' to read vrl-package TOS"
    ;;
esac