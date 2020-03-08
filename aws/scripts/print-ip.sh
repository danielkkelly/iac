#!/usr/local/bin/bash

# Default to the bastion host for a given environment
hostType=bastion

# Default to the default environment
env=default

# Transform long options to short ones
#
for arg in "$@"; do
  shift
  case "$arg" in
    "--env")          set -- "$@" "-e" ;;
    "--host-type")    set -- "$@" "-t" ;;
    *)                set -- "$@" "$arg"
  esac
done

# Parse command line options safely using getops
#
while getopts "e:t:" opt; do
  case $opt in
    e)
      env=$OPTARG
      ;;
    t)
      hostType=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

if [ "x$env" == "x" ]; then
        echo "Please use --env to specify the desired environment"
        exit 1;
fi

host=`aws ec2 describe-instances --profile $env --filters "Name=tag:HostType,Values=$hostType" "Name=instance-state-name,Values=running" | jq -r ".Reservations[] | .Instances[] | .PublicIpAddress"`

if [ "$host" == "null" ]; then
        echo "$hostType isn't running in $env"
        exit 1;
else 
	echo $host
fi

