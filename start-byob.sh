#!/bin/bash
cd ~/byob/web-gui
echo "When the server is running open Chrome or Firefox: "
echo "URL in browser: ""$HOSTNAME"".local:5000"
echo "Please wait about 15-30 min before the server is started up..."
./startup.sh > ~/bootspool.log