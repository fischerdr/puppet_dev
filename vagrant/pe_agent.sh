#!/bin/bash
#
# Dirty vagrant provisioner for installing a Puppet agent
#
# Assumes EL 6 or 7
#

if [[ $(uname -r) =~ "el7" ]]; then
  PLATFORM="el-7-x86_64"
  FALLBACK_INSTALL="https://s3.amazonaws.com/puppet-agents/2016.1/puppet-agent/1.4.2/repos/el/7/PC1/x86_64/puppet-agent-1.4.2-1.el7.x86_64.rpm"
else
  PLATFORM="el-6-x86_64"
  FALLBACK_INSTALL="https://s3.amazonaws.com/puppet-agents/2016.1/puppet-agent/1.4.2/repos/el/6/PC1/x86_64/puppet-agent-1.4.2-1.el6.x86_64.rpm"
fi

###########################################################
ANSWERS=$1
control_dir=$3
modules_dir=$4
AGENT_FILENAME=${FALLBACK_INSTALL##*/}

## A reasonable PATH
echo "export PATH=$PATH:/usr/local/bin:/opt/puppet/bin:/opt/puppetlabs/bin" >> /etc/bashrc

# turn off iptables
echo "==> Disabling iptables"
(set -x ; /sbin/service iptables stop)

echo "==> Setting SELinux to permissive"
(set -x ; /usr/sbin/setenforce permissive)

# Do we need this?
(set -x ; yum install -y bind-utils)
(set -x ; yum update -y nss-softokn nss ca-certificates)
(set -x ; curl -k https://curl.haxx.se/ca/cacert.pem -o /etc/pki/tls/certs/ca-bundle.crt)

echo "==> Attempting to installing Puppet Enterprise Agent from ${1}..."
(set -x;set -o pipefail;curl -k https://${1}:8140/packages/current/install.bash  | bash)
if [ $? -eq 0 ]; then
  echo "Complete!"
else
  echo "Installing the Puppet Enterprise agent didn't exit cleanly."
  [ ! -d "/vagrant/.tmp" ] && (set -x; mkdir /vagrant/.tmp/)
  (set -x ; cd /vagrant/.tmp)
  if [ ! -f "${AGENT_FILENAME}" ]; then
    echo
    echo "Attempting to download and install from Puppet..."
    echo "Downloading ${FALLBACK_INSTALL}"
    (set -x ; curl -k -O "${FALLBACK_INSTALL}")
  else
    echo
    echo "/vagrant/.tmp/${AGENT_FILENAME} was found, using that.."
  fi
  (set -x ; rpm -ivh "$AGENT_FILENAME")
  (set -x ; yum install -y libxslt dmidecode pciutils)
fi

## The following just bootstraps the agent so that it can be used masterless
echo "Configuring Puppet agent"
(set -x ; mkdir -p /etc/puppetlabs/code/environments)

echo "==> Linking the working directory of /vagrant/control to an environment called 'vagrant'"
echo "==> By default, vagrant hosts will use \"vagrant\" as its default Puppet environment"
(set -x ; ln -s /vagrant/control /etc/puppetlabs/code/environments/vagrant)

(set -x ; /opt/puppetlabs/bin/puppet config set server $1 --section main)
(set -x ; /opt/puppetlabs/bin/puppet config set environment vagrant --section main)
(set -x ; /opt/puppetlabs/bin/puppet config set environmentpath /vagrant/environments:/etc/puppetlabs/code/environments --section main)
(set -x ; /opt/puppetlabs/bin/puppet config set basemodulepath /opt/puppetlabs/puppet/modules --section agent)
(set -x ; /opt/puppetlabs/bin/puppet config set basemodulepath /opt/puppetlabs/puppet/modules --section main)
(set -x ; yum install -y git)

## Move the default 'production' environment out of the way
if [ -d "/etc/puppetlabs/code/environments/production" ]; then
  (set -x ; mv "/etc/puppetlabs/code/environments/production" "/etc/puppetlabs/code/environments/orig_production")
fi

check_envs="staging production"
for branch in $check_envs; do
  if [ ! -d "/vagrant/environments/${branch}" ]; then
    echo "============================[ warning ]============================"
    echo "/vagrant/environments/${branch} does not exist.  Has r10k ran?"
    echo "You should run this outside the vagrant box from the puppet_dev repo"
    echo "  bundle exec r10k deploy environment -pv"
    echo
  fi
done

echo "Configuring Hiera"
(set -x ; rm -f /etc/puppetlabs/code/hiera.yaml)
(set -x ; ln -s /vagrant/${control_dir}/site/profile/files/puppet/hiera.yaml /etc/puppetlabs/code/hiera.yaml)

set -x
/opt/puppetlabs/puppet/bin/gem list hiera-eyaml | grep -q hiera-eyaml
if [ $? -ne 0 ]; then
  /opt/puppetlabs/puppet/bin/gem install hiera-eyaml --no-ri --no-rdoc
fi
set +x

(set -x ; [ ! -d "/etc/puppetlabs/puppet/keys" ] && mkdir -p /etc/puppetlabs/puppet/keys)
(set -x ; [ ! -f "/etc/puppetlabs/puppet/keys/public_key.pkcs7.pem" ] && cp /vagrant/vagrant/eyaml_keys/public_key.pkcs7.pem /etc/puppetlabs/puppet/keys/public_key.pkcs7.pem)
(set -x ; [ ! -f "/etc/puppetlabs/puppet/keys/private_key.pkcs7.pem" ] && cp /vagrant/vagrant/eyaml_keys/private_key.pkcs7.pem /etc/puppetlabs/puppet/keys/private_key.pkcs7.pem)

echo "Simulating Puppet's pluginsync for masterless agent"
(set -x ; /opt/puppetlabs/bin/puppet apply /vagrant/vagrant/plugin_sync.pp)

