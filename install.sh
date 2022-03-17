#!/bin/bash

set -e

### Get directory where this script is installed
BASEDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <ssid> <wifi password>"
    exit 1
fi

############################################
# wait until unattended-upgrade has finished
############################################
tmp=$(ps aux | grep unattended-upgrade | grep -v unattended-upgrade-shutdown | grep python | wc -l)
[ $tmp == "0" ] || echo "waiting for unattended-upgrade to finish"
while [ $tmp != "0" ];do
sleep 10;
echo -n "."
tmp=$(ps aux | grep unattended-upgrade | grep -v unattended-upgrade-shutdown | grep python | wc -l)
done

### Give a meaningfull hostname
echo "jupyter-lab" | sudo tee /etc/hostname

### Setup wireless networking ( must change SSID and password )

sudo sed -i "/version: 2/d" /etc/netplan/50-cloud-init.yaml
echo "    wifis:" | sudo tee -a /etc/netplan/50-cloud-init.yaml
echo "        wlan0:" | sudo tee -a /etc/netplan/50-cloud-init.yaml
echo "            access-points:" | sudo tee -a /etc/netplan/50-cloud-init.yaml
echo "                $1:" | sudo tee -a /etc/netplan/50-cloud-init.yaml
echo "                    password: \"$2\"" | sudo tee -a /etc/netplan/50-cloud-init.yaml
echo "            dhcp4: true" | sudo tee -a /etc/netplan/50-cloud-init.yaml
echo "            optional: true" | sudo tee -a /etc/netplan/50-cloud-init.yaml
echo "    version: 2" | sudo tee -a /etc/netplan/50-cloud-init.yaml

### upgrade Ubuntu and install required packages

echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections
sudo apt update
sudo apt -y upgrade
sudo apt install -y python-is-python3 build-essential python3-dev libxml2-dev libxslt1-dev python3-venv

### install jupyter lab in a Python virtual environment
cd ~
python -m venv .venv/jupyter
.venv/jupyter/bin/pip install wheel
.venv/jupyter/bin/pip install jupyterlab
.venv/jupyter/bin/jupyter lab --generate-config
sed -i "s/# c.ServerApp.ip = 'localhost'/c.ServerApp.ip = '*'/" .jupyter/jupyter_lab_config.py

### VTK
sudo apt-get install -y libgl1-mesa-dev libxt-dev libosmesa-dev cmake cmake-curses-gui
wget https://www.vtk.org/files/release/9.1/VTK-9.1.0.tar.gz
tar zxf VTK-9.1.0.tar.gz
cd VTK-9.1.0
mkdir build
cd build
git clone https://github.com/Kitware/VTK
mkdir VTK/build
cd VTK/build
cmake -DCMAKE_BUILD_TYPE=Release \
      -DVTK_BUILD_TESTING=OFF \
      -DVTK_BUILD_DOCUMENTATION=OFF \
      -DVTK_BUILD_EXAMPLES=OFF \
      -DVTK_DATA_EXCLUDE_FROM_ALL:BOOL=ON \
      -DVTK_MODULE_ENABLE_VTK_PythonInterpreter:STRING=NO \
      -DVTK_WHEEL_BUILD=ON \
      -DVTK_PYTHON_VERSION=3 \
      -DVTK_WRAP_PYTHON=ON \
      -DVTK_OPENGL_HAS_EGL=False \
      -DPython3_EXECUTABLE=/home/ubuntu/.venv/jupyter/bin/python ../
make -j4
sudo make install
sudo ldconfig

cd ~/VTK/build
rm -rf dist
~/.venv/jupyter/bin/python -m pip install wheel
~/.venv/jupyter/bin/python setup.py bdist_wheel
~/.venv/jupyter/bin/pip install dist/vtk-*.whl

### INstall jupyter-widgets tutorial
mkdir -p ~/workspace
cd ~/workspace
git clone https://github.com/jupyter-widgets/tutorial.git
sed "s/=.*$//" tutorial/requirements.txt > /tmp/requirements.txt
sed -i "/vtk/d" /tmp/requirements.txt
~/.venv/jupyter/bin/pip install -r /tmp/requirements.txt

### Install supervisor and startup scripts
sudo apt install -y supervisor
cd $BASEDIR/Supervisor
./install.sh

