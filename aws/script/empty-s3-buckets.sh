#!/bin/bash

# Default to the default environment
declare env=dev

function parse_cli {
	for arg in "$@"; do # transform long options to short ones 
		shift
		case "$arg" in
			"--env")          set -- "$@" "-e" ;;
			*)                set -- "$@" "$arg"
		esac
	done

	# Parse command line options safely using getops
	while getopts "e:" opt; do
		case $opt in
			e) env=$OPTARG ;;
			\?)
				echo "Invalid option: -$OPTARG" >&2
				;;
		esac
	done
}

function main {
    local buckets=`aws s3api list-buckets --profile $env | jq -r ".Buckets[] | .Name"`

    for bucket in $buckets 
    do
        echo "emptying $bucket..."
        aws s3 rm s3://$bucket --recursive --only-show-errors --profile $env
    done
}

parse_cli $@
main