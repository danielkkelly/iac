#!/bin/bash

terraform $1 --var-file=../aws.tfvars \
             --var-file=../dev-env.tfvars
