#!/bin/bash
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo deb https://apt.dockerproject.org/repo ubuntu-wily main >> /etc/apt/sources.list
apt-get update
apt-get install -y docker-engine linux-image-extra-$(uname -r) git python-dev
curl https://bootstrap.pypa.io/get-pip.py | python  # install pip

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

systemctl daemon-reload
service docker restart

git clone https://github.com/openstack/kolla.git
cd kolla/

pip install -r requirements.txt
pip install ansible==1.9.4

wc_notify --data-binary '{"status": "SUCCESS"}'
