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
sed "s/deb/deb-src/" /etc/apt/sources.list | sudo tee -a /etc/apt/sources.list
sudo apt update
sudo apt -y upgrade
sudo apt install -y python-is-python3 build-essential python3-dev libxml2-dev libxslt-dev python3-venv

### install jupyter lab in a Python virtual environment
cd ~
python -m venv .venv/jupyter
.venv/jupyter/bin/pip install jupyterlab
.venv/jupyter/bin/jupyter lab --generate-config
sed -i "s/# c.ServerApp.ip = 'localhost'/c.ServerApp.ip = '*'/" .jupyter/jupyter_lab_config.py
