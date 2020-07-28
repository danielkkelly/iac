#!/bin/bash

action=$1
env=$2
shift 2

terraform $action --var-file=../$env-env.tfvars $@