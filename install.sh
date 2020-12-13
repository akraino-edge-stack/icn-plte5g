#!/bin/sh
#set -x
# Author : Isaac
# Copyright (c) 
# <description>
#
# Usage:
#  $sudo  ./install <ip>
#  ip: IP address of the host machine where the installation to be performed.
# 
# Script follows here:

valid_ip()
{
	ip=$1
	stat=1
	if expr "$ip" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; then
  		for i in 1 2 3 4; do
    			if [ $(echo "$ip" | cut -d. -f$i) -gt 255 ]; then
      				echo "Error: IP Address must contain numbers ranging 0-255 ($ip)"
      				return 1
    			fi
  		done
		return 0
	else
  		echo "Error: IP Address must contain only number ranging 0-255. ($ip)"
		return 1
	fi	
}

install_ansible()
{
	echo "IP address recieved from main script in install ansible ($1)"
	ssh-copy-id $1
        yum install git
	#following can be used to install pip on system, if not installed already
	curl https://bootstrap.pypa.io/2.7/get-pip.py -o get-pip.py
	chmod +x ./get-pip.py
	./get-pip.py
	pip install ansible==2.7.18
	pip install requests
	#For Contrail R5.0 use
	#git clone -b R5.0 http://github.com/tungstenfabric/tf-ansible-deployer
	#For master branch use
	git clone http://github.com/tungstenfabric/tf-ansible-deployer
	cd tf-ansible-deployer
        sed -i -e "s/192.168.1.100/$1/g" ./config/instances.yaml
        ansible-playbook -e orchestrator=kubernetes -i inventory/ playbooks/configure_instances.yml
	ansible-playbook -e orchestrator=kubernetes -i inventory/ playbooks/install_contrail.yml
	ansible-playbook -i inventory/ -e orchestrator=kubernetes playbooks/install_k8s.yml
        yum install openssl -y
	curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
}

echo "---- Installation of Tungsten Fabric begins in local instance----"
valid_ip $1
ret="$?"
if [ $ret -eq 0 ]; then
	echo "Host Machine IP received is: " $1
else
	echo "Please enter valid host IP."
	exit 2;
fi

install_ansible $1

echo "---- Installation of Tungsten Fabric Ends ----"



