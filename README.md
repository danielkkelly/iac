# General Requirements

* terriform (download from https://www.terraform.io/downloads.html and unzip in your path)
* ansible 
* paramiko
* passlib (allows creating password hashes for users)

Terraform is a single binary - put that somewhere like ~/bin or /usr/local/bin.  Ansible and paramiko instructions
can be found in the installation guide (https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html).
I used MacOS so it's:

* pip install -user ansible
* pip install -user paramiko
* pip install --user passlib

# Path configuration

* Add /iac/aws/scripts to your path

# AWS Requirements

* Install aws cli (v2)
* Configure aws (~/.aws/credentials and config)

aws/scripts requires

* bash 5
* jq

# Ansible

## Ansible hosts 

Located at /etc/ansible/hosts

```
---
all:
  hosts:
    dev-bastion:
    dev-syslog:
    dev-docker:
  vars:
    ansible_user: ec2-user
    ansible_ssh_private_key_file: ~/.ssh/aws-ec2-user.pem
```

## ansible.cfg

Located at /etc/ansible/ansible.cfg

```
[defaults]
interpreter_python 	= auto_silent
host_key_checking 	= False
```

# SSH Config

```
Host dev-bastion
   ProxyCommand nc `print-ip.sh` %p

Host dev-syslog
   HostName 10.0.2.20
   ProxyCommand ssh -W %h:%p dev-bastion

Host dev-docker
   HostName 10.0.4.40
   ProxyCommand ssh -W %h:%p dev-bastion

Host *
   ForwardAgent yes
```
