# pasos para usarlo en Termux
pkg update -y && pkg upgrade -y
pkg install python git -y
git clone https://github.com/mr3rf1/SecPhoto.git
cd SecPhoto
pip install -r requirements.txt
# editar el script para poner tus credenciales:
# editar SecPhoto.py: api_id, api_hash