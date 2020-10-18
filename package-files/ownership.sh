sleep .5
echo "Adding ""$USER"" to docker"
sudo usermod -aG docker $USER
newgrp docker
sleep .5
echo "Owning BYOB now..."
sudo chown -R $USER:$USER $HOME/byob
