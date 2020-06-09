# Overview

The goal of this project, outside of my own source control management related to my own learning,
is to provide some useful examples for others who are coming up the learning curve on infrastructure
as code using AWS and GCP.  

This project provides a framework and tools for managing production infrastructure.  It offers a 
cloud independent framework for creating infrastructure and configuring it, as as code.

For more information, review the [project overview and tools](script/README.md)

# Prerequisites

* terriform (download from https://www.terraform.io/downloads.html and unzip in your path)
* ansible 
* paramiko
* passlib (allows creating password hashes for users, not strictly required)

Terraform is a single binary - put that somewhere like ~/bin or /usr/local/bin.  Ansible and paramiko 
instructions can be found in the installation guide:

 (https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html).

I use MacOS so it's:

* pip install --user ansible
* pip install --user paramiko
* pip install --user passlib
* pip install --user pymysql

Other packages that are required for scripts include

* bash 4+
* jq

# Environment Configuration

* Add IAC_HOME and point it to where you cloned this repo
* Add $IAC_HOME/[script & aws/script && gcp script]  to your path
* Make IAC_HOME available to Terraform

## Example
```
export IAC_HOME=~/iac
export PATH=$PATH:$IAC_HOME/script:$IAC_HOME/aws/script:$IAC_HOME/gcp/script
export TF_VAR_iac_home=$IAC_HOME
```

# Ansible

## Ansible hosts 

Located at /etc/ansible/hosts.  The stanzas below specify the same infrastructure across 
multiple environments.

```
---
dev_all:
  hosts:
    dev-bastion:
    dev-syslog:
    dev-docker:
  vars:
    ansible_user: ec2-user
    ansible_ssh_private_key_file: ~/.ssh/aws-ec2-user-use1.pem
test_all:
  hosts:
    test-bastion:
    test-syslog:
    test-docker:
  vars:
    ansible_user: ec2-user
    ansible_ssh_private_key_file: ~/.ssh/aws-ec2-user-use2.pem
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
   HostName syslog.dev.internal
   ProxyCommand ssh -W %h:%p dev-bastion

Host dev-docker
   HostName docker.dev.internal
   ProxyCommand ssh -W %h:%p dev-bastion

Host test-bastion
   ProxyCommand nc `print-ip.sh --env test` %p

Host test-syslog
   HostName syslog.test.internal
   ProxyCommand ssh -W %h:%p test-bastion

Host test-docker
   HostName docker.test.internal
   ProxyCommand ssh -W %h:%p test-bastion

Host *
   User ec2-user
   ForwardAgent yes
```
# Project Framework and Tools

[Project Framework and Tools](script/README.md) 

# Provider Specific Documentation

* [AWS](aws/README.md)
* [GCP](gcp/README.md)