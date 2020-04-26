#!/bin/bash

terraform $1 --var-file=../gcp.tfvars \
             --var-file=../dev-env.tfvars
