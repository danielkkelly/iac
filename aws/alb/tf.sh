#!/bin/bash

terraform $1 --var-file=../$2-env.tfvars \
             --var-file=../$2-net.tfvars
