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

See the [AWS](aws/README.md) and [GCP](gcp/README.md) documents for provider specific setup.

# Environment Configuration

* Add IAC_HOME and point it to where you cloned this repo
* Add $IAC_HOME/[script & aws/script && gcp script]  to your path
* Make IAC_HOME available to Terraform
* SMS number is for alarms

## Example
```
export IAC_HOME=~/projects/iac
export PATH=$PATH:$IAC_HOME/script:$IAC_HOME/aws/script:$IAC_HOME/gcp/script
export TF_VAR_iac_home=$IAC_HOME

# IAC SMS
export TF_VAR_sms_number="+15555555555"
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

The configuration below shows the configuration needed when using a traditional basion
host, which resides on a public network and has a public IP.  If you use AWS then you
have the option to use Session Manager to access non-public hosts in a variety of ways.  
See [AWS](aws/README.md#ssh-config) for more information.  It's  a one line change and
you can eliminate a public IP and reduce your attack surface.  Our HCL is set up by 
default to support Session Manager for AWS.

```
Host dev-bastion
   ProxyCommand nc `print-ip.sh` %p
   LocalForward 19990 docker.dev.internal:9990
   LocalForward 13306 db-writer.dev.internal:3306

Host dev-syslog
   HostName syslog.dev.internal
   ProxyCommand ssh -W %h:%p dev-bastion

Host dev-docker
   HostName docker.dev.internal
   ProxyCommand ssh -W %h:%p dev-bastion

Host test-bastion
   ProxyCommand nc `print-ip.sh --env test` %p
   LocalForward 29990 docker.dev.internal:9990
   LocalForward 23306 db-writer.dev.internal:3306

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

# CI

It's possilb that you'll want to deploy applications on your infrastructure automatically. 
The sections below cover deployment of database schemas to MySQL as well as hooks for 
deploying applications.

* [Deploying Schemas](ansible/deploy-schemas/README.md)
* [Deploying Apps](ansible/deploy-apps/README.md)
