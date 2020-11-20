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

######## VARIABLES #########
vrlGitUrl="https://github.com/vrlnx/vrl-package.git"
c2GitUrl="https://github.com/vrlnx/byob.git"
#vrlGitLoc="/home/pi/vrl-package"
setupVarsFile="setupVars.conf"
setupConfigDir="/etc/vrl"
tempsetupVarsFile="/tmp/setupVars.conf"
vrlFilesDir="~/.vrl/vrl-package" # "~/.vrl/vrl-package/"
c2FilesDir="~/.vrl/byob"

vrlScriptDir="~/vrlScripts"

######## PKG Vars ########
PKG_MANAGER="apt-get"
PKG_CACHE="/var/lib/apt/lists/"
### FIXME: quoting UPDATE_PKG_CACHE and PKG_INSTALL hangs the script, shellcheck SC2086
UPDATE_PKG_CACHE="${PKG_MANAGER} update"
PKG_INSTALL="${PKG_MANAGER} --yes --no-install-recommends install"
PKG_COUNT="${PKG_MANAGER} -s -o Debug::NoLocking=true upgrade | grep -c ^Inst || true"

# Dependencies that are required by the script
BASE_DEPS=(curl git avahi-daemon tar wget grep whiptail build-essential gcc cmake neofetch htop upx-ucl zlib1g-dev python3 python3-pip python3-opencv python3-wheel python3-setuptools python3-dev python3-distutils python3-venv docker.io)

# Dependencies that where actually installed by the script. For example if the script requires
# grep and dnsutils but dnsutils is already installed, we save grep here. This way when uninstalling
# vrl-package we won't prompt to remove packages that may have been installed by the user for other reasons
INSTALLED_PACKAGES=()


######## Undocumented Flags. Shhh ########
runUnattended=false
skipSpaceCheck=false
reconfigure=false
showUnsupportedNICs=false

######## SCRIPT ########

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

# Override localization settings so the output is in English language.
export LC_ALL=C
main(){
    ######## FIRST CHECK ########
	# Must NOT be root to install
    echo ":::"
    if [[ $EUID -eq 0 ]];then
		echo "::: You are root. Please do not use root"
        exit 1
	else
		echo "::: Approved!"
		if [[ $(dpkg-query -s sudo) ]]; then
			export SUDO="sudo"
			export SUDOE="sudo -E"
		else
			echo "::: Please install sudo."
			exit 1
		fi
	fi
    # Check for supported distribution
	distroCheck

	# Checks for hostname Length
	checkHostname
	
	# Start the installer
	# Verify there is enough disk space for the install
	if [[ "${skipSpaceCheck}" == true ]]; then
		echo "::: --skip-space-check passed to script, skipping free disk space verification!"
	else
		verifyFreeDiskSpace
	fi

	if cd && [ -d "$(pwd)/.vrl" ];
	then
		echo "::: VRL-Package location already exists, skipping..."
	else
		echo "::: Creating VRL-Package location..."
		cd ~
		mkdir "$(pwd)/.vrl"
	fi
	updatePackageCache
	
	# Notify user of package availability
	notifyPackageUpdatesAvailable

	# Install packages used by this installation script
	preconfigurePackages
	installDependentPackages BASE_DEPS[@]

	# Display welcome dialogs
	welcomeDialogs

	# Find interfaces and let the user choose one
	chooseInterface

	if [ "$PLAT" = "Ubuntu" ]; then
		getStaticIPv4Settings
		if [ -z "$dhcpReserv" ] || [ "$dhcpReserv" -ne 1 ]; then
			setStaticIPv4
		fi
	fi

	# Choose the user for the ovpns
	chooseUser

	# Clone and ready git repos
	cloneOrUpdateRepos
	
	# Install features
	installUs

    # Ingress vector for service
	setupService
	
	# Start services
	restartServices

	# Finish it off
    displayFinalMessage
}
####### FUNCTIONS ##########

preconfigurePackages(){
	# If apt is older than 1.5 we need to install an additional package to add
	# support for https repositories that will be used later on
	if [[ -f /etc/apt/sources.list ]]; then
		INSTALLED_APT="$(apt-cache policy apt | grep -m1 'Installed: ' | grep -v '(none)' | awk '{print $2}')"
		if dpkg --compare-versions "$INSTALLED_APT" lt 1.5; then
			BASE_DEPS+=("apt-transport-https")
		fi
	fi

	# We set static IP only on Ubuntu
	if [ "$PLAT" = "Ubuntu" ]; then
		BASE_DEPS+=(dhcpcd5)
	fi

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
			echo ":::    Package $i successfully installed!"
			# Add this package to the total list of packages that were actually installed by the script
			INSTALLED_PACKAGES+=("${i}")
		else
			echo ":::    Failed to install $i!"
			((FAILED++))
		fi
	done

	if [ "$FAILED" -gt 0 ]; then
		cat "${APTLOGFILE}"
		exit 1
	fi
}

notifyPackageUpdatesAvailable(){
	# Let user know if they have outdated packages on their system and
	# advise them to run a package update at soonest possible.
	echo ":::"
	echo -n "::: Checking ${PKG_MANAGER} for upgraded packages...."
	updatesToInstall=$(eval "${PKG_COUNT}")
	echo " done!"
	echo ":::"
	if [[ ${updatesToInstall} -eq "0" ]]; then
		echo "::: Your system is up to date! Continuing with VRL-Package installation..."
	else
		echo "::: There are ${updatesToInstall} updates available for your system!"
		echo "::: We recommend you update your OS after installing VRL-Package! "
		echo ":::"
	fi
}

distroCheck(){
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
		Ubuntu)
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
	if [ "${runUnattended}" = 'true' ]; then
		echo "::: Invalid OS detected"
		echo "::: We have not been able to detect a supported OS."
		echo "::: Currently this installer supports Ubuntu."
		exit 1
	fi

	whiptail --msgbox --backtitle "INVALID OS DETECTED" --title "Invalid OS" "We have not been able to detect a supported OS.
Currently this installer supports Ubuntu.
For more details, check our documentation at https://github.com/vrlnx/vrl-package/wiki " ${r} ${c}
	exit 1
}

maybeOSSupport(){
	if [ "${runUnattended}" = 'true' ]; then
		echo "::: OS Not Supported"
		echo "::: You are on an OS that we have not tested but MAY work, continuing anyway..."
		return
	fi

	if (whiptail --backtitle "Untested OS" --title "Untested OS" --yesno "You are on an OS that we have not tested but MAY work.
Currently this installer supports Ubuntu.
For more details about supported OS please check our documentation at https://github.com/vrlnx/vrl-package/wiki
Would you like to continue anyway?" ${r} ${c}) then
		echo "::: Did not detect perfectly supported OS but,"
		echo "::: Continuing installation at user's own risk..."
	else
		echo "::: Exiting due to untested OS"
		exit 1
	fi
}

checkHostname(){
	###Checks for hostname size
	host_name=$(hostname -s)
	if [[ ! ${#host_name} -le 28 ]]; then
		if [ "${runUnattended}" = 'true' ]; then
			echo "::: Your hostname is too long."
			echo "::: Use 'hostnamectl set-hostname YOURHOSTNAME' to set a new hostname"
			echo "::: It must be less then 28 characters long and it must not use special characters"
			exit 1
		fi
		until [[ ${#host_name} -le 28 && $host_name  =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,28}$ ]]; do
			host_name=$(whiptail --inputbox "Your hostname is too long.\\nEnter new hostname with less then 28 characters\\nNo special characters allowed." \
		   --title "Hostname too long" ${r} ${c} 3>&1 1>&2 2>&3)
			$SUDO hostnamectl set-hostname "${host_name}"
			if [[ ${#host_name} -le 28 && $host_name  =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,28}$  ]]; then
				echo "::: Hostname valid and length OK, proceeding..."
			fi
		done
	else
		echo "::: Hostname length OK"
	fi
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
		# Show every network interface, could be useful for those who install VRL-Package inside virtual machines.
		availableInterfaces=$(ip -o link | awk '{print $2}' | cut -d':' -f1 | cut -d'@' -f1 | grep -v -w 'lo')
	else
		# Find network interfaces whose state is UP, so as to skip virtual interfaces and the loopback interface.
		availableInterfaces=$(ip -o link | awk '/state UP/ {print $2}' | cut -d':' -f1 | cut -d'@' -f1)
	fi

	if [ -z "$availableInterfaces" ]; then
		echo "::: Could not find any active network interface, exiting"
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
				echo "::: No interface specified, but only ${IPv4dev} is available, using it"
			else
				echo "::: No interface specified and failed to determine one"
				exit 1
			fi
		else
			if ip -o link | grep -qw "${IPv4dev}"; then
				echo "::: Using interface: ${IPv4dev}"
			else
				echo "::: Interface ${IPv4dev} does not exist"
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
			echo "::: Using interface: $IPv4dev"
			echo "IPv4dev=${IPv4dev}" >> ${tempsetupVarsFile}
		done
	else
		echo "::: Cancel selected, exiting...."
		exit 1
	fi
}

verifyFreeDiskSpace(){
	# If user installs unattended-upgrades we'd need about 60MB so will check for 128MB free
	echo "::: Verifying free disk space..."
	local required_free_kilobytes=131072
	local existing_free_kilobytes
	existing_free_kilobytes=$(df -Pk | grep -m1 '\/$' | awk '{print $4}')

	# - Unknown free disk space , not a integer
	if ! [[ "${existing_free_kilobytes}" =~ ^([0-9])+$ ]]; then
		echo "::: Unknown free disk space!"
		echo "::: We were unable to determine available free disk space on this system."
		if [ "${runUnattended}" = 'true' ]; then
			exit 1
		fi
		echo "::: You may continue with the installation, however, it is not recommended."
		read -r -p "::: If you are sure you want to continue, type YES and press enter :: " response
		case $response in
			[Y][E][S])
				;;
			*)
				echo "::: Confirmation not received, exiting..."
				exit 1
				;;
		esac
	# - Insufficient free disk space
	elif [[ ${existing_free_kilobytes} -lt ${required_free_kilobytes} ]]; then
		echo "::: Insufficient Disk Space!"
		echo "::: Your system appears to be low on disk space. VRL-Package recommends a minimum of $required_free_kilobytes KiloBytes."
		echo "::: You only have ${existing_free_kilobytes} KiloBytes free."
		echo "::: If this is a new install on Ubuntu you may need to expand your disk."
		echo "::: After rebooting, run this installation again. (curl -L https://shorturl.at/aqFK1 | bash)"

		echo "Insufficient free space, exiting..."
		exit 1
	fi
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

welcomeDialogs(){
	if [ "${runUnattended}" = 'true' ]; then
		echo "::: VRL-Package Automated Installer"
		echo "::: This installer will transform your ${PLAT} host into an C2 server!"
		echo "::: Initiating network interface"
		return
	fi

	# Display the welcome dialog
	whiptail --msgbox --backtitle "Welcome" --title "VRL-Package Automated Installer" "This installer will transform your Ubuntu into an C2 server!" ${r} ${c}

	# Explain the need for a static address
	whiptail --msgbox --backtitle "Initiating network interface" --title "Static IP Needed" "The VRL-Package is a SERVER so it needs a STATIC IP ADDRESS to function properly.

In the next section, you can choose to use your current network settings (DHCP) or to manually edit them." ${r} ${c}
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
		echo ":::"
		echo -ne "::: ${PKG_MANAGER} update has not been run today. Running now...\\n"
        # shellcheck disable=SC2086
		$SUDO ${UPDATE_PKG_CACHE} &> /dev/null & spinner $!
		echo " done!"
	fi
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

	if [ "${runUnattended}" = 'true' ]; then

		if [ -z "$dhcpReserv" ] || [ "$dhcpReserv" -ne 1 ]; then
			local MISSING_STATIC_IPV4_SETTINGS=0

			if [ -z "$IPv4addr" ]; then
				echo "::: Missing static IP address"
				((MISSING_STATIC_IPV4_SETTINGS++))
			fi

			if [ -z "$IPv4gw" ]; then
				echo "::: Missing static IP gateway"
				((MISSING_STATIC_IPV4_SETTINGS++))
			fi

			if [ "$MISSING_STATIC_IPV4_SETTINGS" -eq 0 ]; then

				# If both settings are not empty, check if they are valid and proceed
				if validIPAndNetmask "${IPv4addr}"; then
					echo "::: Your static IPv4 address:    ${IPv4addr}"
				else
					echo "::: ${IPv4addr} is not a valid IP address"
					exit 1
				fi

				if validIP "${IPv4gw}"; then
					echo "::: Your static IPv4 gateway:    ${IPv4gw}"
				else
					echo "::: ${IPv4gw} is not a valid IP address"
					exit 1
				fi

			elif [ "$MISSING_STATIC_IPV4_SETTINGS" -eq 1 ]; then

				# If either of the settings is missing, consider the input inconsistent
				echo "::: Incomplete static IP settings"
				exit 1

			elif [ "$MISSING_STATIC_IPV4_SETTINGS" -eq 2 ]; then

				# If both of the settings are missing, assume the user wants to use current settings
				IPv4addr="${CurrentIPv4addr}"
				IPv4gw="${CurrentIPv4gw}"
				echo "::: No static IP settings, using current settings"
				echo "::: Your static IPv4 address:    ${IPv4addr}"
				echo "::: Your static IPv4 gateway:    ${IPv4gw}"

			fi
		else
			echo "::: Skipping setting static IP address"
		fi

		echo "dhcpReserv=${dhcpReserv}" >> ${tempsetupVarsFile}
		echo "IPv4addr=${IPv4addr}" >> ${tempsetupVarsFile}
		echo "IPv4gw=${IPv4gw}" >> ${tempsetupVarsFile}
		return
	fi

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
							echo "::: Your static IPv4 address:    ${IPv4addr}"
							IPv4AddrValid=True
						else
							whiptail --msgbox --backtitle "Calibrating network interface" --title "IPv4 address" "You've entered an invalid IP address: ${IPv4addr}\\n\\nPlease enter an IP address in the CIDR notation, example: 192.168.23.211/24\\n\\nIf you are not sure, please just keep the default." ${r} ${c}
							echo "::: Invalid IPv4 address:    ${IPv4addr}"
							IPv4AddrValid=False
						fi
					else
						# Cancelling IPv4 settings window
						echo "::: Cancel selected. Exiting..."
						exit 1
					fi
				done

				until [[ ${IPv4gwValid} = True ]]; do
					# Ask for the gateway
					if IPv4gw=$(whiptail --backtitle "Calibrating network interface" --title "IPv4 gateway (router)" --inputbox "Enter your desired IPv4 default gateway" ${r} ${c} "${CurrentIPv4gw}" 3>&1 1>&2 2>&3) ; then
						if validIP "${IPv4gw}"; then
							echo "::: Your static IPv4 gateway:    ${IPv4gw}"
							IPv4gwValid=True
						else
							whiptail --msgbox --backtitle "Calibrating network interface" --title "IPv4 gateway (router)" "You've entered an invalid gateway IP: ${IPv4gw}\\n\\nPlease enter the IP address of your gateway (router), example: 192.168.23.1\\n\\nIf you are not sure, please just keep the default." ${r} ${c}
							echo "::: Invalid IPv4 gateway:    ${IPv4gw}"
							IPv4gwValid=False
						fi
					else
						# Cancelling gateway settings window
						echo "::: Cancel selected. Exiting..."
						exit 1
					fi
				done

				# Give the user a chance to review their settings before moving on
				if (whiptail --backtitle "Calibrating network interface" --title "Static IP Address" --yesno "Are these settings correct?

						IP address:    ${IPv4addr}
						Gateway:       ${IPv4gw}" ${r} ${c}); then
					# If the settings are correct, then we need to set the vrlIP
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
			echo "::: Static IP already configured."
		else
			setDHCPCD
			$SUDO ip addr replace dev "${IPv4dev}" "${IPv4addr}"
			echo ":::"
			echo "::: Setting IP to ${IPv4addr}.  You may need to restart after the install is complete."
			echo ":::"
		fi
	else
		echo "::: Critical: Unable to locate configuration file to set static IPv4 address!"
		exit 1
	fi
}

chooseUser(){
	if [ "${runUnattended}" = 'true' ]; then
		if [ -z "$install_user" ]; then
			if [ "$(awk -F':' 'BEGIN {count=0} $3>=1000 && $3<=60000 { count++ } END{ print count }' /etc/passwd)" -eq 1 ]; then
				install_user="$(awk -F':' '$3>=1000 && $3<=60000 {print $1}' /etc/passwd)"
				echo "::: No user specified, but only ${install_user} is available, using it"
			else
				echo "::: No user specified"
				exit 1
			fi
		else
			if awk -F':' '$3>=1000 && $3<=60000 {print $1}' /etc/passwd | grep -qw "${install_user}"; then
				echo "::: ${install_user} will hold your ovpn configurations."
			else
				echo "::: User ${install_user} does not exist, creating..."
				$SUDO useradd -m -s /bin/bash "${install_user}"
				echo "::: User created without a password, please do sudo passwd $install_user to create one"
			fi
		fi
		install_home=$(grep -m1 "^${install_user}:" /etc/passwd | cut -d: -f6)
		install_home=${install_home%/}
		echo "install_user=${install_user}" >> ${tempsetupVarsFile}
		echo "install_home=${install_home}" >> ${tempsetupVarsFile}
		return
	fi

	# Explain the local user
	whiptail --msgbox --backtitle "Parsing User List" --title "Local Users" "Choose a local user that will hold your ovpn configurations." ${r} ${c}
	# First, let's check if there is a user available.
	numUsers=$(awk -F':' 'BEGIN {count=0} $3>=1000 && $3<=60000 { count++ } END{ print count }' /etc/passwd)
	if [ "$numUsers" -eq 0 ]
	then
		# We don't have a user, let's ask to add one.
		if userToAdd=$(whiptail --title "Choose A User" --inputbox "No non-root user account was found. Please type a new username." ${r} ${c} 3>&1 1>&2 2>&3)
		then
			# See https://askubuntu.com/a/667842/459815
			PASSWORD=$(whiptail  --title "password dialog" --passwordbox "Please enter the new user password" ${r} ${c} 3>&1 1>&2 2>&3)
			CRYPT=$(perl -e 'printf("%s\n", crypt($ARGV[0], "password"))' "${PASSWORD}")
			if $SUDO useradd -m -p "${CRYPT}" -s /bin/bash "${userToAdd}" ; then
				echo "Succeeded"
				((numUsers+=1))
			else
				exit 1
			fi
		else
			exit 1
		fi
	fi
	availableUsers=$(awk -F':' '$3>=1000 && $3<=60000 {print $1}' /etc/passwd)
	local userArray=()
	local firstloop=1

	while read -r line
	do
		mode="OFF"
		if [[ $firstloop -eq 1 ]]; then
			firstloop=0
			mode="ON"
		fi
		userArray+=("${line}" "" "${mode}")
	done <<< "${availableUsers}"
	chooseUserCmd=(whiptail --title "Choose A User" --separate-output --radiolist
  "Choose (press space to select):" "${r}" "${c}" "${numUsers}")
	if chooseUserOptions=$("${chooseUserCmd[@]}" "${userArray[@]}" 2>&1 >/dev/tty) ; then
		for desiredUser in ${chooseUserOptions}; do
			install_user=${desiredUser}
			echo "::: Using User: $install_user"
			install_home=$(grep -m1 "^${install_user}:" /etc/passwd | cut -d: -f6)
			install_home=${install_home%/} # remove possible trailing slash
			echo "install_user=${install_user}" >> ${tempsetupVarsFile}
			echo "install_home=${install_home}" >> ${tempsetupVarsFile}
		done
	else
		echo "::: Cancel selected, exiting...."
		exit 1
	fi
}

restartServices(){
	echo "::: Restarting services..."
	case ${PLAT} in
		Ubuntu)
			$SUDO systemctl enable vrl.service &> /dev/null
			$SUDO systemctl restart vrl.service
		;;
	esac
}

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
			$SUDO rm -rf "$(dirname "$1")/vrl"
		fi
		# Go back to /usr/local/src otherwise git will complain when the current working
		# directory has just been deleted (/usr/local/src/vrl).
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
		$SUDO rm -rf "$(dirname "$1")/vrl"
	fi
	# Go back to /usr/local/src otherwhise git will complain when the current working
	# directory has just been deleted (/usr/local/src/vrl).
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
	getGitFiles ${c2FilesDir} ${c2GitUrl} || \
	{ echo "!!! Unable to clone ${c2GitUrl} into ${c2FilesDir}, unable to continue."; \
	exit 1; \
	# Get Git files
	getGitFiles ${vrlFilesDir} ${vrlGitUrl} || \
	{ echo "!!! Unable to clone ${vrlGitUrl} into ${vrlFilesDir}, unable to continue."; \
	exit 1; \
}

setupService() {
    echo "::: Applying pre-perms to service files"
    sed "s/SHELL_DIR/$(which sh)/g" ~/vrl/vrl.service
    sed "s/REPLACE_THIS_USERNAME/$(whoami)/g" ~/vrl/vrl.service
    sleep .05
    sudo mv ~/vrl-package/automatic/vrl.service /etc/systemd/system/
    sudo mv ~/vrl-package/automatic/vrl /usr/bin/
    sudo chown root:root /usr/bin/vrl \
    ; sudo chmod 755 /usr/bin/vrl \
    ; sudo chown root:root /etc/systemd/system/vrl.service \
    ; sudo chmod 755 /etc/systemd/system/vrl.service \
	; sudo systemctl daemon-reload
	mkdir ${vrlScriptDir}
}

installUs(){
    sudo xargs apt install -y < reqs.txt &> /dev/null \
	; echo "::: Setting system services..." \
    ; sudo systemctl start avahi-daemon &> /dev/null \
    ; sudo systemctl enable avahi-daemon &> /dev/null \
    ; sudo systemctl start docker &> /dev/null \
    ; sudo systemctl enable docker &> /dev/null \
	; git -C ~/ clone ${vrlGitUrl} &> /dev/null \
	; echo "::: Installing BYOB - VRL Edition..." \
    ; git -C ~/ clone ${GitUrlC2} &> /dev/null \
    ; cd ~/byob/byob \
	; echo "::: Installing requirements..." \
    ; python3 ~/byob/byob/setup.py &> /dev/null \
    ; python3 -m pip install -r requirements.txt &> /dev/null \
    ; cd ~/byob/web-gui/ \
	; echo "::: Installing web-gui..." \
    ; python3 -m pip install -r requirements.txt &> /dev/null \
    ; cd ~/vrl-package \
	; echo "::: Installing vrl-package features..." \
    ; python3 -m pip install -r reqs-pip.txt &> /dev/null \
    ; cd \
	; echo "::: Cleaning up..." \
	; mv ~/vrl-package/automatic/uninstaller.sh ~/vrl-package/uninstaller.sh \
    ; chmod +x ~/vrl-package/uninstaller.sh \
    ; sudo usermod -aG docker $USER  &> /dev/null
    ; PATH=$PATH:~/.local/bin &> /dev/null \
    ; sudo chown $USER:$USER -R ~/byob &> /dev/null
}

displayFinalMessage(){
	if [ "${runUnattended}" = 'true' ]; then
		echo "::: Installation Complete!"
		echo "::: Now run 'vrl add' to create the client profiles."
		echo "::: Run 'vrl help' to see what else you can do!"
		echo
		echo "::: If you run into any issue, please read all our documentation carefully."
		echo "::: All incomplete posts or bug reports will be ignored or deleted."
		echo
		echo "::: Thank you for using VRL-Package."
		echo "::: It is strongly recommended you reboot after installation."
		return
	fi

	# Final completion message to user
	whiptail --msgbox --backtitle "Make it so." --title "Installation Complete!" "Now run 'vrl start' to start the server.
Run 'vrl help' to see what else you can do!\\n\\nIf you run into any issue, please read all our documentation carefully.
All incomplete posts or bug reports will be ignored or deleted.\\n\\nThank you for using VRL-Package." ${r} ${c}
	if (whiptail --title "Reboot" --yesno --defaultno "It is strongly recommended you reboot after installation.  Would you like to reboot now?" ${r} ${c}); then
		whiptail --title "Rebooting" --msgbox "The system will now reboot." ${r} ${c}
		printf "\\nRebooting system...\\n"
		$SUDO sleep 3
		$SUDO shutdown -r now
	fi
}

main "$@"