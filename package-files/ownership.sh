echo "Adding ""$USER"" to docker"
sudo usermod -aG docker $USER
newgrp docker
echo "Owning BYOB now..."
sudo chown -R $USER:$USER $HOME/byob
