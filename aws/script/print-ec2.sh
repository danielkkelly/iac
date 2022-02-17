#!/usr/local/bin/bash

# Default to the bastion host for a given environment
declare hostType=bastion

# Default to the default environment
declare env=default

declare propertyName=InstanceId

# Transform long options to short ones
#
for arg in "$@"; do
  shift
  case "$arg" in
    "--env")          set -- "$@" "-e" ;;
    "--hostType")     set -- "$@" "-t" ;;
    "--property")     set -- "$@" "-p" ;;
    *)                set -- "$@" "$arg"
  esac
done

# Parse command line options safely using getops
#
while getopts "e:t:p:" opt; do
  case $opt in
    e)
      env=$OPTARG
      ;;
    t)
      hostType=$OPTARG
      ;;
    p)
      propertyName=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done


declare properties=`aws ec2 describe-instances --profile $env \
                                 --filters "Name=tag:HostType,Values=$hostType" \
                                           "Name=instance-state-name,Values=running" \
        | jq -r ".Reservations[] | .Instances[] | .$propertyName"`

if [ "$properties" == "null" ]; then
        echo "$hostType isn't running in $env"
        exit 1;
else 
  for property in $properties
  do
	  echo $property
  done
fi

