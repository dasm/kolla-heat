#!/bin/bash

# Add Docker to repo
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo deb https://apt.dockerproject.org/repo ubuntu-wily main >> /etc/apt/sources.list

# Install required packages
apt-get update
apt-get install -y docker-engine linux-image-extra-$(uname -r) python-dev git gcc
curl https://bootstrap.pypa.io/get-pip.py | python  # install pip

# Configure Docker service file
echo "[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network.target docker.socket
Requires=docker.socket

[Service]
Type=notify
ExecStart=/usr/bin/docker daemon -H fd:// --storage-driver=aufs
MountFlags=shared
LimitNOFILE=1048576
LimitNPROC=1048576
LimitCORE=infinity
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target" > /lib/systemd/system/docker.service

# Restart docker to apply Docker file changes
systemctl daemon-reload
service docker restart

# Download Kolla repo
cd /root
git clone https://github.com/openstack/kolla.git
cd kolla/

# Install Kolla requirements
pip install -r requirements.txt
pip install ansible==1.9.4

# Generate build configuration
pip install tox
tox -e genconfig

# Copy default configuration of Kolla
cp -r etc/kolla /etc/

# Disable libvirt. Only one copy may be running at a time.
service libvirt-bin stop
update-rc.d libvirt-bin disable

# If you are seeing the libvirt container fail with the error below
# /usr/sbin/libvirtd: error while loading shared libraries: libvirt-admin.so.0: cannot open shared object file: Permission denied
# disable the libvirt profile.
# apparmor_parser -R /etc/apparmor.d/usr.sbin.libvirtd

# Replace default globals.yml configuration
sed -i.bak 's/#kolla_base_distro: "centos"/kolla_base_distro: "ubuntu"/; s/#kolla_install_type: "binary"/kolla_install_type: "source"/' globals.yml

kolla-build --base ubuntu --type source

# Notify Heat about finishing script run.
wc_notify --data-binary '{"status": "SUCCESS"}'
