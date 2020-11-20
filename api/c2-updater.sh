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
}