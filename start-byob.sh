#!/bin/bash
PATH=$PATH:~/.local/bin
cd ~/byob/web-gui
echo "Open Chrome or Firefox: ""$HOSTNAME"".local:5000"
echo "Please wait about 3-5 min before the server is started up..."
./startup.sh > ~/bootspool.log