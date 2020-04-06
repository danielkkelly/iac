#!/bin/bash

terraform $1 --var-file=../aws.tfvars \
             --var-file=../env-dev.tfvars
