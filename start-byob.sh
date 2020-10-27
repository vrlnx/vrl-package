#!/bin/bash
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
cd ~/byob/web-gui
echo "When the server is running open Chrome or Firefox: "
# sourcing startup.sh in a better fashion
. ~/byob/web-gui/startup.sh > ~/bootspool.log