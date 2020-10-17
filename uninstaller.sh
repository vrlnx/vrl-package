#!/bin/bash

echo "  _    _           _                 _             _   _               ";
echo " | |  | |         (_)               | |           | | | |              ";
echo " | |  | |  _ __    _   _ __    ___  | |_    __ _  | | | |   ___   _ __ ";
echo " | |  | | | '_ \  | | | '_ \  / __| | __|  / _\` | | | | |  / _ \ | '__|";
echo " | |__| | | | | | | | | | | | \__ \ | |_  | (_| | | | | | |  __/ | |   ";
echo "  \____/  |_| |_| |_| |_| |_| |___/  \__|  \__,_| |_| |_|  \___| |_|   ";
echo "                                                                       ";
echo "                                                                       ";
read -p "Do you want to uninstall? [Yes/No*]: " uninstall
case $uninstall in
    yes|Yes|YES)
    if []
    sleep 3
    echo "Deleting byob user and deleting it's host files"
    sudo userdel -rf byob
    sleep 3
    echo "Deleting service files"
    sudo rm -f /usr/bin/byob-server.service
    sleep 3
    echo "Deleting "
    sudo rm 
    ;;
esac
