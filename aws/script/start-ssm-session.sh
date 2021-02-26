#!/usr/local/bin/bash

# Default to the default environment
declare env=dev
declare hostType=bastion
declare port=22

function parse_cli {
	for arg in "$@"; do # transform long options to short ones 
		shift
		case "$arg" in
			"--env")          set -- "$@" "-e" ;;
            "--hostType")     set -- "$@" "-t" ;;
            "--port")         set -- "$@" "-p" ;;
			*)                set -- "$@" "$arg"
		esac
	done

	# Parse command line options safely using getops
	while getopts "e:p:" opt; do
		case $opt in
			e) env=$OPTARG ;;
			t) hostType=$OPTARG ;;
			p) port=$OPTARG ;;
			\?)
				echo "Invalid option: -$OPTARG" >&2
				;;
		esac
	done
}

function main {
	aws ssm start-session --profile $env \
	                      --target `print-ec2.sh --env $env --hostType $hostType` \
						  --document-name AWS-StartSSHSession --parameters "portNumber=$port"
}

parse_cli $@
main