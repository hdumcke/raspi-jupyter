# raspi-jupyter

Install script to install jupyter lab on Raspberry Pi with Ubuntu 20.04 server on SD card

## Installation

- flash  Ubuntu server 20.04 64bit to SD card
- boot Raspberry Pi connected to Ethernet
- ssh ubuntu@&lt;raspi ip address&gt;
- change password (default is ubuntu)
- clone this repository with git clone https://github.com/hdumcke/raspi-jupyter.git
- ./raspi-jupyter/install.sh  &lt;my SSID&gt; &lt;my wifi password&gt; &gt; install.log 2&gt;&amp;1  &amp;
