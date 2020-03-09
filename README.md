# General Requirements

* terriform 
* ansible 
* paramiko

# AWS Requirements

* Install aws cli (v2)
* Configure aws (~/.aws/credentials and config)

aws/scripts requires

* bash 5
* jq

# Ansible

## Ansible hosts 

Located at /etc/ansible/hosts

`dev-bastion     ansible_user=ec2-user   ansible_ssh_private_key_file=~/.ssh/aws-ec2-user.pem
dev-syslog      ansible_user=ec2-user   ansible_ssh_private_key_file=~/.ssh/aws-ec2-user.pem`

## ansible.cfg

[defaults]
interpreter_python 	= auto_silent
host_key_checking 	= False


# SSH Config

Host dev-bastion
   ProxyCommand nc `print-ip.sh` %p

Host dev-syslog
   HostName 10.0.2.20
   ProxyCommand ssh -W %h:%p dev-bastion

Host *
   ForwardAgent yes
