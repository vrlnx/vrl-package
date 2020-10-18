echo "Fetching dependencies..."
sudo apt install docker \
git gcc cmake make upx-ucl \
build-essential zlib1g-dev \
neofetch htop avahi-daemon -y
echo "Picking python repos..."
sudo apt install python3 python3-pip python3-opencv python3-wheel \
python3-setuptools python3-dev python3-distutils python3-venv -y
echo "Doing magic..."
sudo systemctl start avahi-daemon
sudo systemctl enable avahi-daemon
sudo systemctl start docker
sudo systemctl enable docker