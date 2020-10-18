sleep .5
echo "Adding permissions"
cd $HOME
# Making linux files executable
chmod +x $HOME/byob/web-gui/startup.sh
chmod +x $HOME/vrl-package/uninstaller.sh
chmod +x $HOME/vrl-package/start-byob.sh
sleep .5
echo "Enabled uninstaller and start-byob files"