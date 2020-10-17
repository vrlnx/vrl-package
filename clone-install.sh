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

#
# From this install we assume the user in logged in on "byob" user
# And that they are in the home folder of BYOB
# Assumed directory: /opt/byob
git clone https://github.com/malwaredllc/byob.git
echo "Installing python dependencies"
echo ""
cd ~/byob/byob
python3 setup.py
pip3 install requirements.txt
pip3 install colorama
read -p "Do you want to startup the BYOB - GUI? [Yes/No*]: " serverBoot
case $serverBoot in
    yes|Yes|YES)
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
    cd ~/byob/web-gui
    ./startup.sh > ~/bootspool.log
    ;;
esac