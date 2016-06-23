#!/usr/bin/env bash

# Add current hostname to hosts
echo __fixed_ip__ `uname -n` >> /etc/hosts

## Temporary bypass script, by exiting.
wc_notify --data-binary '{"status": "SUCCESS"}'
exit $?

# Add Docker to repo
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo deb https://apt.dockerproject.org/repo ubuntu-wily main >> /etc/apt/sources.list

# Install required packages
apt-get update
apt-get install -y docker-engine linux-image-extra-$(uname -r) python-dev git gcc libffi-dev libssl-dev
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
systemctl restart docker

# Download Kolla repo
cd /root
git clone https://github.com/openstack/kolla.git
cd kolla/

# Install Kolla requirements
pip install -r requirements.txt
#pip install ansible==1.9.4

python setup.py install

# Generate build configuration
pip install tox
tox -e genconfig

# Copy default configuration of Kolla
cp -r etc/kolla /etc/

# Replace default globals.yml configuration
cd /etc/kolla/
sed -i.bak 's/#kolla_base_distro: "centos"/kolla_base_distro: "ubuntu"/; s/#kolla_install_type: "binary"/kolla_install_type: "source"/; s/#enable_central_logging: "no"/enable_central_logging: "yes"/' globals.yml

# Build docker images
kolla-build --base ubuntu --type source

# Generate passwords
kolla-genpwd

# Check if everything is OK
kolla-ansible prechecks

# Deploy stack
kolla-ansible deploy

# Post-deploy configuration
kolla-ansible post-deploy

# Install required CLIs
pip install python-openstackclient python-neutronclient

# Initialize environment (just once)
source /etc/kolla/admin-openrc.sh
cd /root/kolla
tools/init-runonce

# Notify Heat about finishing script run.
wc_notify --data-binary '{"status": "SUCCESS"}'
