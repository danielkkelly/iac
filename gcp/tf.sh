#!/bin/bash

terraform $@ --var-file=gcp.tfvars \
             --var-file=dev-env.tfvars \
             --var-file=dev-net.tfvars
