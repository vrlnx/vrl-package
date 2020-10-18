#!/bin/bash
PATH=$PATH:~/.local/bin
cd ~/byob/web-gui
echo "When the server is running open Chrome or Firefox: "
echo "URL in browser: ""$HOSTNAME"".local:5000"
echo "Please wait about 3-5 min before the server is started up..."
./startup.sh > ~/bootspool.log