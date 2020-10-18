#!/bin/bash
cd /opt/byob/byob/web-gui
echo "Open Chrome or Firefox: ""$HOSTNAME"".local:5000"
sudo sh /opt/byob/byob/web-gui/startup.sh > ~/bootspool.log