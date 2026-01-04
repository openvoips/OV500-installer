# OV500-installer
OV500 Billing and Switch Installer script

This installation script support for CentOS-7.

This Installation script is testing with CentOS-7 http://centos.mirror.net.in/centos/7.9.2009/isos/x86_64/CentOS-7-x86_64-Minimal-2009.iso

cd /usr/local/src

git clone https://github.com/openvoips/OV500-installer.git

cd OV500-installer

sh ovinstaller.sh


# OV500 3.0 installer

OV500 Billing and Switch Installer script

This installation script support for Ubuntu-Server-24.04.3 LTS

This Installation script is testing with Ubuntu-Server-24.04.3 LTS https://mirror.server.net/ubuntu-releases/24.04.3/ubuntu-24.04.3-live-server-amd64.iso

cd /usr/local/src

git clone https://github.com/openvoips/OV500-installer.git

cd OV500-installer

chmod 777 * 

./install.sh

After installation setup the cron Job by 

./cron_install.sh