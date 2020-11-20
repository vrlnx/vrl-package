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

# Dependencies that are required by the script
BASE_DEPS=(git tar wget curl grep net-tools bsdmainutils)

######## URL #######
commandfileUrl="https://raw.githubusercontent.com/vrlnx/vrl-package/${gitBranch}/service/vrl"
serviceUrl="https://raw.githubusercontent.com/vrlnx/vrl-package/${gitBranch}/service/vrl.serivce"

######## PKG Vars ########
PKG_MANAGER="apt"
PKG_CACHE="/var/lib/apt/lists/"
### FIXME: quoting UPDATE_PKG_CACHE and PKG_INSTALL hangs the script, shellcheck SC2086
UPDATE_PKG_CACHE="${PKG_MANAGER} update"
PKG_INSTALL="${PKG_MANAGER} --yes --no-install-recommends install"
PKG_COUNT="${PKG_MANAGER} -s -o Debug::NoLocking=true upgrade | grep -c ^Inst || true"

# Override localization settings so the output is in English language.
export LC_ALL=C

main(){
    # System Check
    clear
    rootCheck
    osCheck
    # Headpatting system, maybe it tells us something.
    updatePackageCache
    notifyPackageUpdatesAvailable
    # Welcome noobs
    welcomeDialogs
    say "Initiating install..."

    # Installing the absolute needed tools
    # ::: Issue 0009 - Permissions Denied
    installDependentPackages BASE_DEPS[@]

    # Setting up byob with vrl-package
    byobSetup
    # Show them the final message
    displayFinalMessage
}
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
        declare -A VER_MAP=(["19.04"]="dingo" ["19.10"]="eoan" ["20.04"]="focal" ["20.10"]="groovy")
        OSCN=${VER_MAP["${VER}"]}
    fi

    case ${PLAT} in
        Raspbian|Kali|Ubuntu)
            case ${OSCN} in
                dingo|eoan|focal|groovy)
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

    echo "PLAT=${PLAT}"
    echo "OSCN=${OSCN}"
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
updatePackageCache(){
    $SUDO ${UPDATE_PKG_CACHE} > /dev/null & spinner $!

    REQU_DEPS=(
    avahi-daemon
    gcc
    cmake
    neofetch
    htop
    upx-ucl
    build-essential
    zlib1g-dev
    docker.io
    python3
    python3-pip
    python3-opencv
    python3-wheel
    python3-setuptools
    python3-dev
    python3-distutils
    python3-venv
    )
    for i in ${REQU_DEPS}; do
        which $i > /dev/null
        local status=$?
        if test $status -ne 0 then
            say "Installing $i...";
            installDependentPackages $i
        else
            echo "$i is installed already.";
        fi
    done
    PY_VER="python3"
    PY_PIP-Install="${PY_VER} -m pip install"
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
welcomeDialogs(){
    say "VRL Automated Installer"
    say "This installer will transform your ${PLAT} host into an C2 server!"
    say "By using this you agree to vrl-package's TOS and Rules of Conduct"
}
pipConfig(){

    REQU_PIP=(
    flask
    flask_wtf
    flask_mail
    flask-bcrypt
    flask-login
    flask-sqlalchemy
    flask-session
    wtforms
    pyinstaller==3.6
    mss==3.3.0
    WMI==1.4.9
    numpy==1.19.4
    pyxhook==1.0.0
    twilio==6.14.0
    colorama==0.3.9
    requests==2.20.0
    pycryptodomex==3.8.1
    py-cryptonight\>=0.2.4
    git+https://github.com/jtgrassie/pyrx.git#egg=pyrx
    opencv-python\;python_version\>'3'
    pypiwin32==223\;sys.platform=='win32'
    pyHook==1.5.1\;sys.platform=='win32'
    )
    for i in ${REQU_PIP}; do
        which $i > /dev/null
        local status=$?
        if test $status -ne 0 then
            say "Installing $i...";
            ${PY_PIP-Install} $i;
        else
            echo "$i is installed.";
        fi
    done

    # ${PY_PIP-Install} pyinstaller==3.6 > /dev/null & spinner $!
    # ${PY_PIP-Install} mss==3.3.0 > /dev/null & spinner $!
    # ${PY_PIP-Install} WMI==1.4.9 > /dev/null & spinner $!
    # ${PY_PIP-Install} numpy==1.19.4 > /dev/null & spinner $!
    # ${PY_PIP-Install} pyxhook==1.0.0 > /dev/null & spinner $!
    # ${PY_PIP-Install} twilio==6.14.0 > /dev/null & spinner $!
    # ${PY_PIP-Install} colorama==0.3.9 > /dev/null & spinner $!
    # ${PY_PIP-Install} requests==2.20.0 > /dev/null & spinner $!
    # ${PY_PIP-Install} pycryptodomex==3.8.1 > /dev/null & spinner $!
    # ${PY_PIP-Install} py-cryptonight\>=0.2.4 > /dev/null & spinner $!
    # ${PY_PIP-Install} git+https://github.com/jtgrassie/pyrx.git#egg=pyrx > /dev/null & spinner $!
    # ${PY_PIP-Install} opencv-python\;python_version\>'3' > /dev/null & spinner $!
    # ${PY_PIP-Install} pypiwin32==223\;sys.platform=='win32'
    # ${PY_PIP-Install} pyHook==1.5.1\;sys.platform=='win32'
}
byobSetup(){
    # Passed
    say "Configuring .local mDNS"
    $SUDO systemctl start avahi-daemon &> /dev/null \
    ; $SUDO systemctl enable avahi-daemon &> /dev/null
    
    # Passed
    say "Configuring Docker Container Service"
    $SUDO systemctl start docker &> /dev/null \
    ; $SUDO systemctl enable docker &> /dev/null
    
    # Passed
    say "Setting up Byob for vrl-package"
    git -C ~/ clone ${byobGitUrl} &> /dev/null
    $SUDO mv ~/byob ${byobFileDir}
    
    # ::: Issue 0012 - No such file or directory
    say "Downloading Byob Python3 CLI requirements"
    cd ${byobFileDir}
    python3 ${byobFileDir}/byob/setup.py &> /dev/null
    ${PY_PIP-Install} -r requirements.txt > /dev/null & spinner $!

    # ::: Issue 0013 - No such file or directory
    say "Downloading Byob Python3 GUI requirements"
    cd ${byobFileDir}/web-gui/
    ${PY_PIP-Install} -r requirements.txt > /dev/null & spinner $!
    
    say "Installing general lacking requirements"
    cd ${vrlFilesDir}
    pipConfig > /dev/null & spinner $!
    
    say "Configure Docker Container permissions"
    local USER_ME=$(whoami)
    sudo usermod -aG docker $USER_ME  &> /dev/null
    PATH=$PATH:$HOME/.local/bin &> /dev/null
    sudo chown root:root -R ${byobFileDir} &> /dev/null
    
    say "Configuring services"
    $SUDO touch ${vrlCommandFile}
    $SUDO wget -O ${vrlCommandFile} ${commandfileUrl} > /dev/null & spinner $!
    $SUDO touch ${vrlServiceFile}
    $SUDO wget -O ${vrlServiceFile} ${serviceUrl} > /dev/null & spinner $!
    $SUDO cat ${vrlServiceFile} | sed -e "s/$shell/$(which sh)/g" | sed -e "s/$usrname/${USER_ME}/g" | sed -e "s/$vrlFilesDir/${vrlFilesDir}/g" | sed -e "s/$byobFileDir/${byobFileDir}/g" > ${vrlServiceFile}
    say "done."
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
displayFinalMessage(){
    say "Installation Complete!"
    say "Run 'vrl help' to see what else you can do!"
    say
    say "If you run into any issue, please read all our documentation carefully."
    say "All incomplete posts or bug reports will be ignored or deleted."
    say
    say "Thank you for using VRL-Package."
    say "It is strongly recommended you reboot after installation."
    say
    say "Your Public IP: ${myPublicIp}"
    say "Your Local IP(s): $(hostname -I)"
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
main "$@"