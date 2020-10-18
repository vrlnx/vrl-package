echo "Python installer"
cd $HOME/byob/byob
python3 setup.py |> /dev/null
# Installing pip3 python add-ons
pip3 install requirements.txt |> /dev/null
pip3 install colorama |> /dev/null
pip3 pyinstaller==3.6 |> /dev/null
pip3 install flask |> /dev/null
pip3 install flask-bcrypt |> /dev/null
pip3 install flask-login |> /dev/null
pip3 install flask-sqlalchemy |> /dev/null