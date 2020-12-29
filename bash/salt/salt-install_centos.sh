#!/usr/bin/env bash                                                                                                                            [9/1012]


cat << 'EOF' > /etc/yum.repos.d/saltstack.repo
[saltstack]
name=SaltStack archive/2017.7.5 Release Channel for RHEL/CentOS $releasever
baseurl=http://mirror-salt.sys.localhost/yum/redhat/6/$basearch/archive/2017.7.5/
skip_if_unavailable=True
gpgcheck=1
gpgkey=http://mirror-salt.sys.localhost/yum/redhat/6/$basearch/archive/2017.7.5/SALTSTACK-GPG-KEY.pub
enabled=1
enabled_metadata=1
EOF

yum install salt-minion -y

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

/etc/init.d/salt-minion restart
