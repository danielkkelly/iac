#!/usr/local/bin/bash

ssh -L 13306:`print-rds-endpoint.sh`:3306 \
 dev-bastion
