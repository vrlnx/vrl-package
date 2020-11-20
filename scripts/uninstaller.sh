#!/usr/bin/env bash
# VRL-Package: Trivial C2 setup and configuration
# Easiest setup and mangement of BYOB C2 on Ubuntu
# 
# Heavily adapted from the byob.dev project and...
# https://github.com/malwaredllc/byob/
#
# Install with this command:
#
# curl -L https://shorturl.at/aqFK1 | bash
# Make sure you have `curl` installed

# timestamp: 06 Nov. 2020 18:03 CEST


######## SCRIPT ########

# Override localization settings so the output is in English language.
export LC_ALL=C

main(){
	######## FIRST CHECK ########
	# Must NOT be root to install
    echo ":::"
    if [[ $EUID -eq 0 ]];then
		echo "::: You are root. Please do not use root..."
        exit 1
	else
		echo "::: Approved!"
	fi
    echo ":::"
    echo "::: Stopping running services..."
	sudo service stop vrl
	sudo systemctl disable vrl
    echo "::: Removing VRL-Service..."
    sudo rm -f /usr/bin/vrl.service
    sudo rm -rf /usr/bin/vrl
    echo "::: Deleting byob..."
    sudo rm -rf ~/byob
    echo "::: Deleting vrl-package..."
    sudo rm -rf ~/vrl-package
    echo "::: "
}

main "$@"