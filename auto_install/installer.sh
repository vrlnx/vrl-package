#!/usr/bin/env bash
# 
#
# curl -L https://raw.githubusercontent.com/vrlnx/vrl-package/beta/auto_install/installer.sh | bash
#
# Make sure you have `curl` installed

######## VARIABLES
myPublicIp=$(dig +short myip.opendns.com @resolver1.opendns.com)
gitBranch="beta"
vrlFilesDir="/usr/local/src/vrl"
vrlServiceFile="/etc/systemd/system/vrl.service"
vrlCommandFile="/usr/local/bin/vrl"
byobGitUrl="https://github.com/vrlnx/byob.git"
byobFileDir="${vrlFilesDir}/byob"
tempsetupVarsFile="/tmp/setupVars.conf"

######## PKG Vars ########
PKG_MANAGER="apt"
PKG_CACHE="/var/lib/apt/lists/"
### FIXME: quoting UPDATE_PKG_CACHE and PKG_INSTALL hangs the script, shellcheck SC2086
UPDATE_PKG_CACHE="${PKG_MANAGER} update"
PKG_INSTALL="${PKG_MANAGER} --yes --no-install-recommends install"
PKG_COUNT="${PKG_MANAGER} -s -o Debug::NoLocking=true upgrade | grep -c ^Inst || true"

# Dependencies that are required by the script
BASE_DEPS=(git tar wget curl grep dnsutils net-tools bsdmainutils)

# Dependencies that where actually installed by the script. For example if the script requires
# grep and dnsutils but dnsutils is already installed, we save grep here. This way when uninstalling
# vrl-package we won't prompt to remove packages that may have been installed by the user for other reasons
INSTALLED_PACKAGES=()

######## URLs ########
requiermentsPac=$(curl -L "https://raw.githubusercontent.com/vrlnx/vrl-package/${gitBranch}/archive/auto-list.txt")
requiermentsPip=$(curl -L"https://raw.githubusercontent.com/vrlnx/vrl-package/${gitBranch}/archive/pip-list.txt")
commandfileUrl="https://raw.githubusercontent.com/vrlnx/vrl-package/${gitBranch}/service/vrl"
serviceUrl="https://raw.githubusercontent.com/vrlnx/vrl-package/${gitBranch}/service/vrl.serivce"


######## SCRIPT
# Find the rows and columns. Will default to 80x24 if it can not be detected.
screen_size=$(stty size 2>/dev/null || echo 24 80)
rows=$(echo "$screen_size" | awk '{print $1}')
columns=$(echo "$screen_size" | awk '{print $2}')

# Divide by two so the dialogs take up half of the screen, which looks nice.
r=$(( rows / 2 ))
c=$(( columns / 2 ))
# Unless the screen is tiny
r=$(( r < 20 ? 20 : r ))
c=$(( c < 70 ? 70 : c ))

# Defaults to English(US)
export LC_ALL=C

main() {
    ######## FIRST CHECK ########
	# Can't be root to install
    # init also updates and ready for installation.
    __init__
    
    # Show people welcome
    welcomeDialogs
    
    # Define interface
    chooseInterface

    # Make sure policys is corrected.
    preconfigurePackages

    # Install programms Byob needs
    installDependentPackages ${requiermentsPac}
    
    # Adding vrl as a command
    installScripts
    # This will ensure 
    configureService
    # Freshen up the services and rewrites
    restartServices
    # Ensure that cached writes reach persistent storage
    say "Flushing writes to disk..."
    sync
    say "done."
    displayFinalMessage
    say
}

######## FUNCTIONS
__init__() {
    ###### Setup jumps
    rootCheck # Making sure you are not stupid
    osCheck # Trying to make it work on Kali, Raspberry and Ubuntu
    checkHostname
    updatePackageCache
    notifyPackageUpdatesAvailable
    installDependentPackages BASE_DEPS[@]
    ###### Functions for init
    rootCheck() {
        if [[ $EUID -eq 0 ]];then
            say "You are root!"
            say
            denyAccess
        else
            say "sudo will be used for the install."
            # Check if it is actually installed
            # If it isn't, exit because the install cannot complete
            if [[ $(dpkg-query -s sudo) ]];then
                export SUDO="sudo"
                export SUDOE="sudo -E"
            else
                say "Please install sudo."
                exit 1
            fi
        fi
    }
    
    osCheck() {
        # if lsb_release command is on their system
        if command -v lsb_release > /dev/null; then

            PLAT=$(lsb_release -si)
            OSCN=$(lsb_release -sc)

        else # else get info from os-release

            # shellcheck disable=SC1091
            source /etc/os-release
            PLAT=$(awk '{print $1}' <<< "$NAME")
            VER="$VERSION_ID"
            declare -A VER_MAP=(["18.04"]="bionic" ["20.04"]="focal" ["20.10"]="groovy")
            OSCN=${VER_MAP["${VER}"]}
        fi

        case ${PLAT} in
            Raspbian|Kali|Ubuntu)
                case ${OSCN} in
                    bionic|focal|groovy)
                    :
                    ;;
                    *)
                    maybeOSSupport
                    ;;
                esac
            ;;
            *)
            noOSSupport
            ;;
        esac

        echo "PLAT=${PLAT}" > ${tempsetupVarsFile}
        echo "OSCN=${OSCN}" >> ${tempsetupVarsFile}
    }
    noOSSupport(){
        say "Invalid OS detected"
        say "We have not been able to detect a supported OS."
        say "Currently this installer supports Raspbian and Ubuntu."
        say "For more details, check our documentation at https://github.com/vrlnx/vrl-package/wiki"
        exit 1
    }
    maybeOSSupport(){
        say "OS Not Supported"
        say "You are on an OS that we have not tested but MAY work, continuing anyway..."
    }
    avoidStaticIPv4Ubuntu() {
            say "Since we think you are not using Raspbian, we will not configure a static IP for you."
            return
    }

    validIP(){
        local ip=$1
        local stat=1

        if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            OIFS=$IFS
            IFS='.'
            read -r -a ip <<< "$ip"
            IFS=$OIFS
            [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
            stat=$?
        fi
        return $stat
    }

    validIPAndNetmask(){
        local ip=$1
        local stat=1
        ip="${ip/\//.}"

        if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,2}$ ]]; then
            OIFS=$IFS
            IFS='.'
            read -r -a ip <<< "$ip"
            IFS=$OIFS
            [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 \
            && ${ip[4]} -le 32 ]]
            stat=$?
        fi
        return $stat
    }

    getStaticIPv4Settings() {
        # Find the gateway IP used to route to outside world
        CurrentIPv4gw="$(ip -o route get 192.0.2.1 | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | awk 'NR==2')"

        # Find the IP address (and netmask) of the desidered interface
        CurrentIPv4addr="$(ip -o -f inet address show dev "${IPv4dev}" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/[0-9]{1,2}')"

        # Grab their current DNS servers
        IPv4dns=$(grep -v "^#" /etc/resolv.conf | grep -w nameserver | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | xargs)

        local ipSettingsCorrect
        local IPv4AddrValid
        local IPv4gwValid
        # Some users reserve IP addresses on another DHCP Server or on their routers,
        # Lets ask them if they want to make any changes to their interfaces.

        if (whiptail --backtitle "Calibrating network interface" --title "DHCP Reservation" --yesno --defaultno \
        "Are you Using DHCP Reservation on your Router/DHCP Server?
    These are your current Network Settings:
                IP address:    ${CurrentIPv4addr}
                Gateway:       ${CurrentIPv4gw}
    Yes: Keep using DHCP reservation
    No: Setup static IP address
    Don't know what DHCP Reservation is? Answer No." ${r} ${c}); then
            dhcpReserv=1
            # shellcheck disable=SC2129
            echo "dhcpReserv=${dhcpReserv}" >> ${tempsetupVarsFile}
            # We don't really need to save them as we won't set a static IP but they might be useful for debugging
            echo "IPv4addr=${CurrentIPv4addr}" >> ${tempsetupVarsFile}
            echo "IPv4gw=${CurrentIPv4gw}" >> ${tempsetupVarsFile}
        else
            # Ask if the user wants to use DHCP settings as their static IP
            if (whiptail --backtitle "Calibrating network interface" --title "Static IP Address" --yesno "Do you want to use your current network settings as a static address?
                    IP address:    ${CurrentIPv4addr}
                    Gateway:       ${CurrentIPv4gw}" ${r} ${c}); then
                IPv4addr=${CurrentIPv4addr}
                IPv4gw=${CurrentIPv4gw}
                echo "IPv4addr=${IPv4addr}" >> ${tempsetupVarsFile}
                echo "IPv4gw=${IPv4gw}" >> ${tempsetupVarsFile}

                # If they choose yes, let the user know that the IP address will not be available via DHCP and may cause a conflict.
                whiptail --msgbox --backtitle "IP information" --title "FYI: IP Conflict" "It is possible your router could still try to assign this IP to a device, which would cause a conflict.  But in most cases the router is smart enough to not do that.
    If you are worried, either manually set the address, or modify the DHCP reservation pool so it does not include the IP you want.
    It is also possible to use a DHCP reservation, but if you are going to do that, you might as well set a static address." ${r} ${c}
                # Nothing else to do since the variables are already set above
            else
                # Otherwise, we need to ask the user to input their desired settings.
                # Start by getting the IPv4 address (pre-filling it with info gathered from DHCP)
                # Start a loop to let the user enter their information with the chance to go back and edit it if necessary
                until [[ ${ipSettingsCorrect} = True ]]; do

                    until [[ ${IPv4AddrValid} = True ]]; do
                        # Ask for the IPv4 address
                        if IPv4addr=$(whiptail --backtitle "Calibrating network interface" --title "IPv4 address" --inputbox "Enter your desired IPv4 address" ${r} ${c} "${CurrentIPv4addr}" 3>&1 1>&2 2>&3) ; then
                            if validIPAndNetmask "${IPv4addr}"; then
                                say "Your static IPv4 address:    ${IPv4addr}"
                                IPv4AddrValid=True
                            else
                                whiptail --msgbox --backtitle "Calibrating network interface" --title "IPv4 address" "You've entered an invalid IP address: ${IPv4addr}\\n\\nPlease enter an IP address in the CIDR notation, example: 192.168.23.211/24\\n\\nIf you are not sure, please just keep the default." ${r} ${c}
                                say "Invalid IPv4 address:    ${IPv4addr}"
                                IPv4AddrValid=False
                            fi
                        else
                            # Cancelling IPv4 settings window
                            say "Cancel selected. Exiting..."
                            exit 1
                        fi
                    done

                    until [[ ${IPv4gwValid} = True ]]; do
                        # Ask for the gateway
                        if IPv4gw=$(whiptail --backtitle "Calibrating network interface" --title "IPv4 gateway (router)" --inputbox "Enter your desired IPv4 default gateway" ${r} ${c} "${CurrentIPv4gw}" 3>&1 1>&2 2>&3) ; then
                            if validIP "${IPv4gw}"; then
                                say "Your static IPv4 gateway:    ${IPv4gw}"
                                IPv4gwValid=True
                            else
                                whiptail --msgbox --backtitle "Calibrating network interface" --title "IPv4 gateway (router)" "You've entered an invalid gateway IP: ${IPv4gw}\\n\\nPlease enter the IP address of your gateway (router), example: 192.168.23.1\\n\\nIf you are not sure, please just keep the default." ${r} ${c}
                                say "Invalid IPv4 gateway:    ${IPv4gw}"
                                IPv4gwValid=False
                            fi
                        else
                            # Cancelling gateway settings window
                            say "Cancel selected. Exiting..."
                            exit 1
                        fi
                    done

                    # Give the user a chance to review their settings before moving on
                    if (whiptail --backtitle "Calibrating network interface" --title "Static IP Address" --yesno "Are these settings correct?
                            IP address:    ${IPv4addr}
                            Gateway:       ${IPv4gw}" ${r} ${c}); then
                        # If the settings are correct, then we need to set the vrl-packagesIP
                        echo "IPv4addr=${IPv4addr}" >> ${tempsetupVarsFile}
                        echo "IPv4gw=${IPv4gw}" >> ${tempsetupVarsFile}
                        # After that's done, the loop ends and we move on
                        ipSettingsCorrect=True
                    else
                        # If the settings are wrong, the loop continues
                        ipSettingsCorrect=False
                        IPv4AddrValid=False
                        IPv4gwValid=False
                    fi
                done
                # End the if statement for DHCP vs. static
            fi
            # End of If Statement for DCHCP Reservation
        fi
    }

    setDHCPCD(){
        # Append these lines to dhcpcd.conf to enable a static IP
        echo "interface ${IPv4dev}
        static ip_address=${IPv4addr}
        static routers=${IPv4gw}
        static domain_name_servers=${IPv4dns}" | $SUDO tee -a ${dhcpcdFile} >/dev/null
    }

    setStaticIPv4(){
        # Tries to set the IPv4 address
        if [[ -f /etc/dhcpcd.conf ]]; then
            if grep -q "${IPv4addr}" ${dhcpcdFile}; then
                say "Static IP already configured."
            else
                setDHCPCD
                $SUDO ip addr replace dev "${IPv4dev}" "${IPv4addr}"
                say
                say "Setting IP to ${IPv4addr}.  You may need to restart after the install is complete."
                say
            fi
        else
            say "Critical: Unable to locate configuration file to set static IPv4 address!"
            exit 1
        fi
    }

    checkHostname(){
    ###Checks for hostname size
        host_name=$(hostname -s)
        if [[ ! ${#host_name} -le 28 ]]; then
            until [[ ${#host_name} -le 28 && $host_name  =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,28}$ ]]; do
                host_name=$(whiptail --inputbox "Your hostname is too long.\\nEnter new hostname with less then 28 characters\\nNo special characters allowed." \
            --title "Hostname too long" ${r} ${c} 3>&1 1>&2 2>&3)
                $SUDO hostnamectl set-hostname "${host_name}"
                if [[ ${#host_name} -le 28 && $host_name  =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,28}$  ]]; then
                    say "Hostname valid and length OK, proceeding..."
                fi
            done
        else
            say "Hostname length OK"
        fi
    }

    updatePackageCache(){
        #Running apt-get update/upgrade with minimal output can cause some issues with
        #requiring user input

        #Check to see if apt-get update has already been run today
        #it needs to have been run at least once on new installs!
        timestamp=$(stat -c %Y ${PKG_CACHE})
        timestampAsDate=$(date -d @"${timestamp}" "+%b %e")
        today=$(date "+%b %e")


        if [ ! "${today}" == "${timestampAsDate}" ]; then
            #update package lists
            say 
            echo -ne "::: ${PKG_MANAGER} update has not been run today. Running now...\\n"
            # shellcheck disable=SC2086
            $SUDO ${UPDATE_PKG_CACHE} &> /dev/null & spinner $!
            say " done!"
        fi
    }

    notifyPackageUpdatesAvailable(){
        # Let user know if they have outdated packages on their system and
        # advise them to run a package update at soonest possible.
        say
        echo -n "::: Checking ${PKG_MANAGER} for upgraded packages...."
        updatesToInstall=$(eval "${PKG_COUNT}")
        echo " done!"
        say
        if [[ ${updatesToInstall} -eq "0" ]]; then
            say "Your system is up to date! Continuing with vrl-package installation..."
        else
            say "There are ${updatesToInstall} updates available for your system!"
            say "We recommend you update your OS after installing vrl-package! "
            say
        fi
    }
    
}
installDependentPackages(){
	declare -a TO_INSTALL=()

	# Install packages passed in via argument array
	# No spinner - conflicts with set -e
	declare -a argArray1=("${!1}")

	for i in "${argArray1[@]}"; do
		echo -n ":::    Checking for $i..."
		if dpkg-query -W -f='${Status}' "${i}" 2>/dev/null | grep -q "ok installed"; then
			echo " already installed!"
		else
			echo " not installed!"
			# Add this package to the list of packages in the argument array that need to be installed
			TO_INSTALL+=("${i}")
		fi
	done

	local APTLOGFILE="$(mktemp)"

	if command -v debconf-apt-progress > /dev/null; then
        # shellcheck disable=SC2086
		$SUDO debconf-apt-progress --logfile "${APTLOGFILE}" -- ${PKG_INSTALL} "${TO_INSTALL[@]}"
	else
		# shellcheck disable=SC2086
		$SUDO ${PKG_INSTALL} "${TO_INSTALL[@]}"
	fi

	local FAILED=0

	for i in "${TO_INSTALL[@]}"; do
		if dpkg-query -W -f='${Status}' "${i}" 2>/dev/null | grep -q "ok installed"; then
			say "   Package $i successfully installed!"
			# Add this package to the total list of packages that were actually installed by the script
			INSTALLED_PACKAGES+=("${i}")
		else
			say "   Failed to install $i!"
			((FAILED++))
		fi
	done

	if [ "$FAILED" -gt 0 ]; then
		cat "${APTLOGFILE}"
		exit 1
	fi
}
welcomeDialogs(){
    say "VRL Automated Installer"
    say "This installer will transform your ${PLAT} host into an C2 server!"
    say "Initiating network interface"
}
chooseInterface(){
    # Turn the available interfaces into an array so it can be used with a whiptail dialog
    local interfacesArray=()
    # Number of available interfaces
    local interfaceCount
    # Whiptail variable storage
    local chooseInterfaceCmd
    # Temporary Whiptail options storage
    local chooseInterfaceOptions
    # Loop sentinel variable
    local firstloop=1

    if [[ "${showUnsupportedNICs}" == true ]]; then
        # Show every network interface, could be useful for those who install VRL inside virtual machines
        # or on Raspberry Pis with USB adapters (the loopback interfaces is still skipped)
        availableInterfaces=$(ip -o link | awk '{print $2}' | cut -d':' -f1 | cut -d'@' -f1 | grep -v -w 'lo')
    else
        # Find network interfaces whose state is UP, so as to skip virtual interfaces and the loopback interface
        availableInterfaces=$(ip -o link | awk '/state UP/ {print $2}' | cut -d':' -f1 | cut -d'@' -f1)
    fi

    if [ -z "$availableInterfaces" ]; then
        say "Could not find any active network interface, exiting"
        exit 1
    else
        while read -r line; do
            mode="OFF"
            if [[ ${firstloop} -eq 1 ]]; then
                firstloop=0
                mode="ON"
            fi
            interfacesArray+=("${line}" "available" "${mode}")
            ((interfaceCount++))
        done <<< "${availableInterfaces}"
    fi

    if [ "${runUnattended}" = 'true' ]; then
        if [ -z "$IPv4dev" ]; then
            if [ $interfaceCount -eq 1 ]; then
                IPv4dev="${availableInterfaces}"
                say "No interface specified, but only ${IPv4dev} is available, using it"
            else
                say "No interface specified and failed to determine one"
                exit 1
            fi
        else
            if ip -o link | grep -qw "${IPv4dev}"; then
                say "Using interface: ${IPv4dev}"
            else
                say "Interface ${IPv4dev} does not exist"
                exit 1
            fi
        fi
        echo "IPv4dev=${IPv4dev}" >> ${tempsetupVarsFile}
        return
    else
        if [ "$interfaceCount" -eq 1 ]; then
            IPv4dev="${availableInterfaces}"
            echo "IPv4dev=${IPv4dev}" >> ${tempsetupVarsFile}
            return
        fi
    fi

    chooseInterfaceCmd=(whiptail --separate-output --radiolist "Choose An interface (press space to select):" "${r}" "${c}" "${interfaceCount}")
    if chooseInterfaceOptions=$("${chooseInterfaceCmd[@]}" "${interfacesArray[@]}" 2>&1 >/dev/tty) ; then
        for desiredInterface in ${chooseInterfaceOptions}; do
            IPv4dev=${desiredInterface}
            say "Using interface: $IPv4dev"
            echo "IPv4dev=${IPv4dev}" >> ${tempsetupVarsFile}
        done
    else
        say "Cancel selected, exiting...."
        exit 1
    fi
}
installScripts() {
    $SUDO ${PKG_INSTALL} 
    say "Creating vrl-package folder"
    $SUDO mkdir ${vrlFilesDir}
    say "Populating /usr/local/bin"
    wget "${commandfileUrl}" ${vrlCommandFile} > /dev/null & spinner $!
    wget "${serviceUrl}" ${vrlServiceFile}
    cat ${vrlServiceFile} | sed 's/\$shell/\/usr\/bin\/bash/gm' | sed 's/\$usrname/\$(whoami)/gm' > ${vrlServiceFile} &> /dev/null
    say "Prepairing vrlnx/byob for population"
    cloneGit > /dev/null & spinner $!

}
preconfigurePackages(){
	# If apt is older than 1.5 we need to install an additional package to add
	# support for https repositories that will be used later on
	if [[ -f /etc/apt/sources.list ]]; then
		INSTALLED_APT="$(apt-cache policy apt | grep -m1 'Installed: ' | grep -v '(none)' | awk '{print $2}')"
		if dpkg --compare-versions "$INSTALLED_APT" lt 1.5; then
			BASE_DEPS+=("apt-transport-https")
		fi
	fi

	# We set static IP only on Raspbian
	if [ "$PLAT" = "Raspbian" ]; then
		BASE_DEPS+=(dhcpcd5)
	fi

	AVAILABLE_OPENVPN="$(apt-cache policy openvpn | grep -m1 'Candidate: ' | grep -v '(none)' | awk '{print $2}')"
	DPKG_ARCH="$(dpkg --print-architecture)"

	# if ufw is enabled, configure that.
	# running as root because sometimes the executable is not in the user's $PATH
	if $SUDO bash -c 'command -v ufw' > /dev/null; then
		if $SUDO ufw status | grep -q inactive; then
			USING_UFW=0
		else
			USING_UFW=1
		fi
	else
		USING_UFW=0
	fi

	if [ "$USING_UFW" -eq 0 ]; then
		BASE_DEPS+=(iptables-persistent)
		echo iptables-persistent iptables-persistent/autosave_v4 boolean true | $SUDO debconf-set-selections
		echo iptables-persistent iptables-persistent/autosave_v6 boolean false | $SUDO debconf-set-selections
	fi

	echo "USING_UFW=${USING_UFW}" >> ${tempsetupVarsFile}
}
configureService(){
    sudo xargs apt install -y < reqs.txt > /dev/null & spinner $!
    say "Configuring .local mDNS"
    sudo systemctl start avahi-daemon >& /dev/null \
    ; sudo systemctl enable avahi-daemon >& /dev/null
    say "Configuring Docker Container Service"
    sudo systemctl start docker >& /dev/null \
    ; sudo systemctl enable docker >& /dev/null
    say "Setting up Byob for vrl-package"
    cd ${vrlFilesDir}/byob/byob \
    ; python3 ~/byob/byob/setup.py >& /dev/null
    say "Downloading Python3 CLI requirements"
    python3 -m pip install -r requirements.txt > /dev/null & spinner $1 \
    ; cd ${vrlFilesDir}/byob/web-gui/
    say "Downloading Python3 GUI requirements"
    python3 -m pip install -r requirements.txt > /dev/null & spinner $1 \
    ; cd ${vrlFilesDir}/vrl
    say "Installing general lacking requirements"
    python3 -m pip install -r "${requiermentsPip}" > /dev/null & spinner $1
    say "Configure Docker Container permissions"
    sudo usermod -aG docker $var_user  >& /dev/null \
    ; PATH=$PATH:$HOME/.local/bin >& /dev/null \
    ; sudo chown $var_user:$var_user -R ${vrlFilesDir}/byob >& /dev/null \
    ; touch ${vrlFilesDir}/bootspool.log >& /dev/null \
    ; sudo chown root:root ${vrlFilesDir}/bootspool.log >& /dev/null \
    ; sudo chmod 644 ${vrlFilesDir}/bootspool.log > /dev/null
}
restartServices(){
	say "Restarting services..."
	case ${PLAT} in
		Kali|Raspbian|Ubuntu)
				$SUDO systemctl enable vrl.service &> /dev/null
				$SUDO systemctl restart vrl.service
		;;
	esac
}
cloneGit(){
    isRepo(){
	# If the directory does not have a .git folder it is not a repo
	echo -n ":::    Checking $1 is a repo..."
	cd "${1}" &> /dev/null || return 1
	$SUDO git status &> /dev/null && echo " OK!"; return 0 || echo " not found!"; return 1
    }

    updateRepo(){
        if [ "${UpdateCmd}" = "Repair" ]; then
            echo "::: Repairing an existing installation, not downloading/updating local repos"
        else
            # Pull the latest commits
            echo -n ":::     Updating repo in $1..."
            ### FIXME: Never call rm -rf with a plain variable. Never again as SU!
            #$SUDO rm -rf "${1}"
            if test -n "$1"; then
                $SUDO rm -rf "$(dirname "$1")/byob"
            fi
            # Go back to /usr/local/src otherwise git will complain when the current working
            # directory has just been deleted (/usr/local/src/pivpn).
            cd /usr/local/src && \
            $SUDO git clone -q --depth 1 --no-single-branch "${2}" "${1}" > /dev/null & spinner $!
            cd "${1}" || exit 1
            if [ -z "${TESTING+x}" ]; then
                :
            else
                ${SUDOE} git checkout test
            fi
            echo " done!"
        fi
    }

    makeRepo(){
        # Remove the non-repos interface and clone the interface
        echo -n ":::    Cloning $2 into $1..."
        ### FIXME: Never call rm -rf with a plain variable. Never again as SU!
        #$SUDO rm -rf "${1}"
        if test -n "$1"; then
            $SUDO rm -rf "$(dirname "$1")/byob"
        fi
        # Go back to /usr/local/src otherwhise git will complain when the current working
        # directory has just been deleted (/usr/local/src/pivpn).
        cd /usr/local/src && \
        $SUDO git clone -q --depth 1 --no-single-branch "${2}" "${1}" > /dev/null & spinner $!
        cd "${1}" || exit 1
        if [ -z "${TESTING+x}" ]; then
            :
        else
            ${SUDOE} git checkout test
        fi
        echo " done!"
    }

    getGitFiles(){
        # Setup git repos for base files
        echo ":::"
        echo "::: Checking for existing base files..."
        if isRepo "${1}"; then
            updateRepo "${1}" "${2}"
        else
            makeRepo "${1}" "${2}"
        fi
    }

    cloneOrUpdateRepos(){
        # /usr/local should always exist, not sure about the src subfolder though
        $SUDO mkdir -p /usr/local/src

        # Get Git files
        getGitFiles ${byobFileDir} ${byobGitUrl} || \
        { echo "!!! Unable to clone ${byobGitUrl} into ${byobFileDir}, unable to continue."; \
        exit 1; \
    }
    cloneOrUpdateRepos
}
######## DEFINED MARKS
displayFinalMessage(){
    say "Installation Complete!"
    say "Run 'vrl help' to see what else you can do!"
    say
    say "If you run into any issue, please read all our documentation carefully."
    say "All incomplete posts or bug reports will be ignored or deleted."
    say
    say "Thank you for using VRL-Package."
    say "It is strongly recommended you reboot after installation."
    return
}
spinner(){
	local pid=$1
	local delay=0.50
	local spinstr='/-\|'
	while ps a | awk '{print $1}' | grep -q "$pid"; do
		local temp=${spinstr#?}
		printf " [%c]  " "${spinstr}"
		local spinstr=${temp}${spinstr%"$temp"}
		sleep ${delay}
		printf "\\b\\b\\b\\b\\b\\b"
	done
	printf "    \\b\\b\\b\\b"
}
denyAccess() {
    say "::::::::::::::::::::::::::::: :::"
    say "  Looks like more reading     :::"        
    say "      is needed...            :::"
    say "      Exit completed...       :::"
    say "                              :::"
    say "      Access denied!          :::"
    say "::::::::::::::::::::::::::::: :::"
    exit 1
}
say() {
    echo "::: $@"
}
######## END OF FILE
main