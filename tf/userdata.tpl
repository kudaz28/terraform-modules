 #!/bin/bash

sed -i "s/search.*/search aws.esure.com uk.esure.com eu-west-1.compute.internal/" /etc/resolv.conf

sed -i "s/PEERDNS=.*/PEERDNS=no/" /etc/sysconfig/network-scripts/ifcfg-eth0

yum-config-manager --enable epel

yum clean all

yum -y erase ntp*
yum -y install chrony
chkconfig chronyd
/etc/init.d/chronyd start

rpm -Uvh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-6.noarch.rpm

yum -y install git puppet-agent
cat <<-HIERA >/etc/puppetlabs/puppet/hiera.yaml
---
version: 5
defaults:
  datadir: /etc/puppetlabs/puppet/hieradata/hiera
  data_hash: yaml_data

hierarchy:
  - name: "accounts data"
    path: "accounts.yaml"

  - name: "sshkeys"
    path: "sshkeys.yaml"

HIERA

cat <<-GITHUB >/root/.ssh/config
StrictHostKeyChecking no
Host github.com
IdentityFile /root/.ssh/github
HostName github.com
User git
GITHUB

aws configure set region eu-west-1
aws ssm get-parameters --names "/beanstalk/instance/github" --query 'Parameters[0].[Value]'  --output text > /root/.ssh/github
chmod 600 /root/.ssh/github

mkdir -p /etc/puppetlabs/puppet/hieradata
cd       /etc/puppetlabs/puppet/hieradata
git clone -b hiera git@github.com:esure-dev/puppet-hiera.git hiera

mkdir -p /etc/puppetlabs/code/modules/
cd       /etc/puppetlabs/code/modules/
git clone -b multi-account git@github.com:esure-dev/puppet-accounts.git accounts
git clone -b future_production git@github.com:esure-dev/puppet-common.git common
git clone -b future_production git@github.com:esure-dev/puppet-sudoers.git sudoers
git clone -b master git@github.com:esure-dev/puppet-qualys.git qualys

#__________________________________________________
log 'Run Puppet..'

/opt/puppetlabs/bin/puppet apply --verbose -e "include accounts" || exit 1
/opt/puppetlabs/bin/puppet apply --verbose -e "include sudoers::g2"  || exit 1
/opt/puppetlabs/bin/puppet apply --verbose -e "include qualys"   || exit 1


############################################################## UPSTART #############################################
docker pull jetbrains/upsource:2018.1.584
mkdir -p -m 750 /opt/upsource/{data,conf,logs,backups}
chown -R 13001:13001 /opt/upsource/*
sudo curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

cd /opt/upsource/
cat <<-EOF > /opt/upsource/docker-compose.yml
upstart:
  image: jetbrains/upsource:2018.1.584
  restart: always
  ports:
    - 8080:8080
  expose:
    - 8080
  volumes:
    - /opt/upsource/backup:/opt/upsource/backup
    - /opt/upsource/conf:/opt/upsource/conf
    - /opt/upsource/data:/opt/upsource/data
    - /opt/upsource/logs:/opt/upsource/logs
EOF

/usr/local/bin/docker-compose up -d
