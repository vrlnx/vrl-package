#!/bin/bash
cd /opt/byob/byob/web-gui
echo "When it's running it's available in browser"
echo "Type this in your Chrome or Firefox: ""$HOSTNAME"".local:5000"
sudo sh /opt/byob/byob/web-gui/startup.sh > ~/bootspool.log