#!/usr/bin/env bash
# 
#
# curl -L https://raw.githubusercontent.com/vrlnx/vrl-package/beta/auto_install/installer.sh | bash
# curl -L http://alturl.com/dxz27 | bash
# Make sure you have `curl` installed

######## VARIABLES
myPublicIp=$(dig +short myip.opendns.com @resolver1.opendns.com)
gitBranch="beta"
vrlFilesDir="/usr/local/src/vrl-package"
vrlServiceFile="/etc/systemd/system/vrl.service"
vrlCommandFile="/usr/local/bin/vrl"
byobGitUrl="https://github.com/vrlnx/byob.git"
byobFileDir="${vrlFilesDir}/byob"
tempsetupVarsFile="/tmp/setupVars.conf"

PY_VER="python3"
PIP_INSTALL="${PY_VER} -m pip --no-warn-script-location install"

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
        say "Verify your user."
        # Check if it is actually installed
        # If it isn't, exit because the install cannot complete
        if [[ $(dpkg-query -s sudo) ]];then
            export SUDO="sudo"
            export SUDOE="sudo -E"
            $SUDO echo "::: Verification Complete"
        else
            say "Please install sudo."
            exit 1
        fi
    fi
}
osCheck() {
    SUPPORTED_OS=(Ubuntu Pop Raspbian Kali)
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
    
    compactSupport(){
        for i in ${SUPPORTED_OS[@]}; do
            SUPPORTED_OS_PACK+="$i|"
        done
        echo $SUPPORTED_OS_PACK | sed "s/|$//"
        return
    }
    case ${PLAT} in
        $(compactSupport))
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
    say "Currently this installer supports ${SUPPORTED_OS[@]}."
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

    # Issue 0015 - bash: line 152: syntax error near unexpected token 'else' - FIXED
    for i in ${REQU_DEPS[@]}; do
        which $i > /dev/null
        status=$?
        if [ ${status} -ne 0 ]; then
            say "Installing $i"
            $SUDO ${PKG_INSTALL} $i > /dev/null & spinner $!
        else
            say "$i is installed already."
        fi
    done
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
    say
    say "You have 10 sec to abort install if you do not agree [CTRL+C]"
    numsz=(10 9 8 7 6 5 4 3 2 1)
    for i in ${numsz[@]}; do
        sleep 1s
        say "Launch in $i..."
    done
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
    # Issue 0021 - bash: line 152: syntax error near unexpected token 'else'
    for i in ${REQU_PIP[@]}; do
        say "Installing $i..."
        ${PIP_INSTALL} $i --no-warn-script-location
    done

    # ${PIP_INSTALL} pyinstaller==3.6 > /dev/null & spinner $!
    # ${PIP_INSTALL} mss==3.3.0 > /dev/null & spinner $!
    # ${PIP_INSTALL} WMI==1.4.9 > /dev/null & spinner $!
    # ${PIP_INSTALL} numpy==1.19.4 > /dev/null & spinner $!
    # ${PIP_INSTALL} pyxhook==1.0.0 > /dev/null & spinner $!
    # ${PIP_INSTALL} twilio==6.14.0 > /dev/null & spinner $!
    # ${PIP_INSTALL} colorama==0.3.9 > /dev/null & spinner $!
    # ${PIP_INSTALL} requests==2.20.0 > /dev/null & spinner $!
    # ${PIP_INSTALL} pycryptodomex==3.8.1 > /dev/null & spinner $!
    # ${PIP_INSTALL} py-cryptonight\>=0.2.4 > /dev/null & spinner $!
    # ${PIP_INSTALL} git+https://github.com/jtgrassie/pyrx.git#egg=pyrx > /dev/null & spinner $!
    # ${PIP_INSTALL} opencv-python\;python_version\>'3' > /dev/null & spinner $!
    # ${PIP_INSTALL} pypiwin32==223\;sys.platform=='win32'
    # ${PIP_INSTALL} pyHook==1.5.1\;sys.platform=='win32'
}
byobSetup(){

    # ::: Issue 0023 - Make sure that vrl folder exsists
    $SUDO mkdir ${vrlFilesDir}
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
    # ::: Issue 0022 - No such file or directory - FIXED
    $SUDO mv ~/byob ${vrlFilesDir}/
    
    # ::: Issue 0012 - No such file or directory
    say "Downloading Byob Python3 CLI requirements"
    cd ${byobFileDir}
    python3 ${byobFileDir}/byob/setup.py > /dev/null & spinner $!
    say "Applying Python3 CLI requirements"
    ${PIP_INSTALL} -r requirements.txt > /dev/null & spinner $!

    # ::: Issue 0013 - No such file or directory
    say "Downloading Byob Python3 GUI requirements"
    cd ${byobFileDir}/web-gui/
    ${PIP_INSTALL} -r requirements.txt > /dev/null & spinner $!
    
    # ::: Issue 0017 - 
    say "Installing general lacking requirements"
    cd ${vrlFilesDir}
    pipConfig > /dev/null & spinner $!
    
    # ::: Issue 0019 - making sure it can run in the 
    say "Configure Docker Container permissions"
    local USER_ME=$(whoami)
    sudo usermod -aG docker $USER_ME  &> /dev/null
    PATH=$PATH:$HOME/.local/bin &> /dev/null
    sudo chown root:root -R ${byobFileDir} &> /dev/null
    
    # ::: Issue 0020 - Forgot to apply read and execute permissions
    say "Configuring services"
    
    $SUDO wget -O ${vrlCommandFile} ${commandfileUrl} > /dev/null & spinner $!
    $SUDO chmod 755 ${vrlServiceFile}
    $SUDO chmod 755 ${vrlCommandFile}
    # ::: Issue 0024 - Making sure that service files 
    wget -O ~/vrl.service ${serviceUrl} > /dev/null & spinner $!
    cat ~/vrl.service | sed "s/$shell/$(which sh)/g" | sed "s/$usrname/${USER_ME}/g" | sed "s/$vrlFilesDir/${vrlFilesDir}/g" | sed -e "s/$byobFileDir/${byobFileDir}/g" > ${vrlServiceFile}
    $SUDO mv ~/vrl.service ${vrlServiceFile}
    say "done."
    sleep 5
    clear

    # ::: Issue 0025 - Make sure to build Docker containers
    # Build Docker images
    local checkDocker=$(groups | grep -w "docker")
    if [ "${checkDocker}" = "docker" ]; then
        say "Building Docker images - this will take a while, please be patient..."
        say
        cd ${byobFileDir}/web-gui/docker-pyinstaller1
        say "Building amd64 for Mac and Linux enviorment"
        docker build -f Dockerfile-py3-amd64 -t nix-amd64 . > /dev/null & spinner $!
        say "Building i386 for Mac and Linux enviorment"
        docker build -f Dockerfile-py3-i386 -t nix-i386 . > /dev/null & spinner $!
        say "Building x32 for Windows enviorment"
        docker build -f Dockerfile-py3-win32 -t win-x32 . > /dev/null & spinner $!
    else
        say "You don't have permissions to build with Docker"
        say "Reboot! Run 'curl -L http://alturl.com/dxz27 | bash' again"
        exit 1
    fi
}
installDependentPackages(){
	declare -a TO_INSTALL=()

	# Install packages passed in via argument array
	# No spinner - conflicts with set -e
	declare -a argArray1=("${!1}")

	for i in "${argArray1[@]}"; do
		echo -n ":::    Checking for $i..."
		if $SUDO dpkg-query -W -f='${Status}' "${i}" 2>/dev/null | grep -q "ok installed"; then
			echo " already installed!"
		else
			echo " not installed!"
			# Add this package to the list of packages in the argument array that need to be installed
			TO_INSTALL+=("${i}")
		fi
	done

    # shellcheck disable=SC2086
    $SUDO ${PKG_INSTALL} "${TO_INSTALL[@]}"

	local FAILED=0

	for i in "${TO_INSTALL[@]}"; do
		if $SUDO dpkg-query -W -f='${Status}' "${i}" 2>/dev/null | grep -q "ok installed"; then
			say "   Package $i successfully installed!"
			# Add this package to the total list of packages that were actually installed by the script
			INSTALLED_PACKAGES+=("${i}")
		else
			say "   Failed to install $i!"
			((FAILED++))
		fi
	done

	if [ "$FAILED" -gt 0 ]; then
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
    say "  is needed...                :::"
    say "                              :::"
    say "                              :::"
    say "      Access denied!          :::"
    say "::::::::::::::::::::::::::::: :::"
    exit 1
}
say() {
    echo "::: $@"
}
main "$@"