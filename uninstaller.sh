#!/bin/bash

echo "  _    _           _                 _             _   _               ";
echo " | |  | |         (_)               | |           | | | |              ";
echo " | |  | |  _ __    _   _ __    ___  | |_    __ _  | | | |   ___   _ __ ";
echo " | |  | | | '_ \  | | | '_ \  / __| | __|  / _\` | | | | |  / _ \ | '__|";
echo " | |__| | | | | | | | | | | | \__ \ | |_  | (_| | | | | | |  __/ | |   ";
echo "  \____/  |_| |_| |_| |_| |_| |___/  \__|  \__,_| |_| |_|  \___| |_|   ";
echo "                                                                       ";
echo "                                                                       ";
read -p "You are about uninstall Byob? [y/N*]: " uninstall
case $uninstall in
    yes|Yes|YES|y|Y)
    echo "Deleting byob user and deleting it's host files"
    sudo userdel -rf byob
    sleep .3
    echo "Deleting service files"
    sudo rm -f /usr/bin/byob-server.service
    sleep .2
    echo "Deleting byob command"
    sudo rm -rf /usr/bin/byob
    cd
    rm -rf ~/vrl-package
    ;;
    *)
    echo "Nothing has been done"
    ;;
esac
