echo "Python installer"
cd $HOME/byob/byob/
python3 setup.py > /dev/null 2>&1 &
# Installing pip3 python add-ons
pip3 install requirements.txt > /dev/null 2>&1 &
pip3 install colorama > /dev/null 2>&1 &
pip3 pyinstaller==3.6 > /dev/null 2>&1 &
pip3 install flask > /dev/null 2>&1 &
pip3 install flask-bcrypt > /dev/null 2>&1 &
pip3 install flask-login > /dev/null 2>&1 &
pip3 install flask-sqlalchemy > /dev/null 2>&1 &