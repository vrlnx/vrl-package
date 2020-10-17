#!/bin/bash
cd /opt/byob/byob/web-gui
echo "When it's running it's available in browser"
echo "$HOSTNAME"".local:5000"
sudo sh /opt/byob/byob/web-gui/startup.sh > ~/bootspool.log