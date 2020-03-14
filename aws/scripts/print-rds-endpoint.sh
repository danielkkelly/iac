#!/usr/local/bin/bash

# Default to the default environment
env=default

# Transform long options to short ones
#
for arg in "$@"; do
  shift
  case "$arg" in
    "--env")          set -- "$@" "-e" ;;
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
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

if [ "x$env" == "x" ]; then
        echo "Please use --env to specify the desired environment"
        exit 1;
fi

host=`aws rds describe-db-clusters --profile $env | jq -r '.DBClusters[0].Endpoint'`

if [ "$host" == "null" ]; then
        echo "Issue finding RDS database cluster, perhaps it isn't running in $env"
        exit 1;
else 
	echo $host
fi

