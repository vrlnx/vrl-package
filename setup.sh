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
var_user=$(whoami)
if [ $(whoami) == "root" ]; then
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
export LC_ALL=C
case $1 in
    install)
        clear
        # Does not work atm [ ! -d "$HOME/byob" ] || echo "You have already installed a version of byob." ; exit
        # Does not work atm [ $OSTYPE == "linux-gnu" ] && echo "" || echo "You are trying to run this in a unsupported OS" ; exit
        # if [ -d "~/byob"]; then

        # fi
        clear
        echo " __      _______  _        _____           _        _ _            ";
        echo " \ \    / /  __ \| |      |_   _|         | |      | | |           ";
        echo "  \ \  / /| |__) | |        | |  _ __  ___| |_ __ _| | | ___ _ __  ";
        echo "   \ \/ / |  _  /| |        | | | '_ \/ __| __/ _\` | | |/ _ \ '__| ";
        echo "    \  /  | | \ \| |____   _| |_| | | \__ \ || (_| | | |  __/ |    ";
        echo "     \/   |_|  \_\______| |_____|_| |_|___/\__\__,_|_|_|\___|_|    ";
        echo "                                                                   ";
        echo "                                                                   ";
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
            if ! sudo apt update | grep "All packages are up to date"; then
                sudo apt update -qq \
                && sudo apt upgrade -y \
                && sudo apt autoremove -y
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
            spin()
            {
            spinner="/|\\-/|\\-"
            while :
            do
                for i in `seq 0 7`
                do
                echo -n "${spinner:$i:1}"
                echo -en "\010"
                sleep .15
                done
            done
            }
            spin & SPIN_PID=$!
            echo "Applying pre-perms to service files"
            sudo cp ~/vrl-package/byob.service /etc/systemd/system/ \
            ; sudo cp ~/vrl-package/byob /usr/bin/ \
            ; sudo chown root:root /usr/bin/byob \
            ; sudo chmod 755 /usr/bin/byob \
            ; sudo chown root:root /etc/systemd/system/byob.service > /dev/null
            kill -9 $SPIN_PID >& /dev/null
            sleep .05
            clear
            # fortheimpatient() {
            #     pid=$1
            #     status="   ... ${@:2}"
            #     echo -ne "  |$status\r"
            #     echo -n "| "
            #     inset=1
            #     spinner=(
            #         '⠋'
            #         '⠙'
            #         '⠹'
            #         '⠸'
            #         '⠼'
            #         '⠴'
            #         '⠦'
            #         '⠧'
            #         '⠇'
            #         '⠏'
            #     )
            #     while kill -0 $pid 2> /dev/null; do
            #         for state in ${spinner[@]}; do
            #             echo -ne "\b$state"
            #             sleep 0.05
            #         done
            #     done
            #     wait $pid
            #     retc=$?
            #     bkset=0
            #     bkspc=""
            #     while [ $bkset -le $inset ]; do
            #         bkspc="$bkspc\b"
            #         bkset=$((bkset + 1))
            #     done
            #     echo -ne "$bkspc"
            #     if [ $retc -ne 0 ]; then feedback 2 "$2 failed with errorcode: $retc -/- Check log.build_environment for details."; fi
            # }
            # fortheimpatient $! "Setting up system"
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
            echo ""
            echo "Sit back and enjoy a drink, this may take a while..."
            echo ""
            echo "Do not cancel..."
            spin & SPIN_PID=$!
            sudo xargs apt install -y < reqs.txt >& /dev/null \
            ; sudo systemctl start avahi-daemon >& /dev/null \
            ; sudo systemctl enable avahi-daemon >& /dev/null \
            ; sudo systemctl start docker >& /dev/null \
            ; sudo systemctl enable docker >& /dev/null \
            ; git -C ~/ clone https://github.com/vrlnx/byob.git >& /dev/null \
            ; cd ~/byob/byob \
            ; python3 ~/byob/byob/setup.py >& /dev/null \
            ; python3 -m pip install -r requirements.txt >& /dev/null \
            ; cd ~/byob/web-gui/ \
            ; python3 -m pip install -r requirements.txt >& /dev/null \
            ; cd ~/vrl-package \
            ; python3 -m pip install -r reqs-pip.txt >& /dev/null \
            ; cd \
            ; chmod +x ~/vrl-package/uninstaller.sh \
            ; chmod +x ~/vrl-package/start-byob.sh \
            ; sudo usermod -aG docker $var_user  >& /dev/null
            chmod -x ~/vrl-package/setup.sh \
            ; PATH=$PATH:$HOME/.local/bin >& /dev/null \
            ; sudo chown $var_user:$var_user -R $HOME/byob >& /dev/null \
            ; touch $HOME/bootspool.log >& /dev/null \
            ; sudo chown $var_user:$var_user $HOME/bootspool.log >& /dev/null \
            ; kill -9 $SPIN_PID > /dev/null
            sleep .05
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
            read -p "::: System will now reboot (Press Enter when ready)"
            sudo reboot now
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
