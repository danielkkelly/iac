#!/usr/local/bin/bash

#
# Script to create all of the network and server resrouces and configure them
#

# terraform init needs to get run for each configuration

#network/tf.sh apply
#bastion/tf.sh apply
#syslog/tf.sh apply

# Base configuration for Bastion host
# ansible-playbook bastion/playbook.yaml

# Base configuration for Syslog host
# ansible-playbook bastion/playbook-server.yaml

# Configure syslog for clients
# ansible-playbook bastion/playbook-client.yaml

