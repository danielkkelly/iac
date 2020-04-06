#!/usr/local/bin/bash

#
# Script to create basic infrastructure.  Run terraform init in each module first
#

# Terraform modules
export modules=("network" "iam" "ssm" "bastion")

# Ansible playbooks
export playbooks=("localhost/playbook.yaml" "bastion/playbook.yaml")

if [[ "$1" == "create" ]] 
then
	for i in ${modules[@]};
	do 
		cd $i
		./tf.sh apply
		cd -
	done
elif [[ "$1" == "destroy" ]]
then
	for (( i = ${#modules[@]} - 1; i >= 0; i-- )); 
	do
		cd ${modules[i]}
		./tf.sh destroy
		cd -
	done;
elif [[ "$1" == "configure" ]]
then
	for i in ${playbooks[@]};
	do 
		ansible-playbook $i 
	done
else 
	echo "invalid argument $1"
fi
