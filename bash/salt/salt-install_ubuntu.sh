#!/usr/bin/env bash

mirror_salt=mirror-salt.sys.localhost

wget -O - http://$mirror_salt/apt/ubuntu/16.04/amd64/archive/2017.7.5/SALTSTACK-GPG-KEY.pub | sudo apt-key add -
echo "deb http://$mirror_salt/apt/ubuntu/16.04/amd64/archive/2017.7.5 xenial main" | sudo tee /etc/apt/sources.list.d/saltstack.list

apt update
apt install salt-minion -y

cat << 'EOF' > /etc/salt/minion
master:
  - salt-master01.sys.localhost
  - salt-master02.sys.localhost
  - salt-master03.sys.localhost
  - salt-master04.sys.localhost
random_master: True
auth_tries: 3
random_reauth_delay: 60
master_alive_interval: 60
sudo_user: root
hash_type: sha256
state_output: mixed
EOF

systemctl restart salt-minion
