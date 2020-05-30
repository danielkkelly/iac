#!/usr/local/bin/bash
# Script that performs terraform operations across an entire provider
# TODO: add a task for upgrading terraform modules?

declare provider
declare env="dev"
declare action

declare -a targets=()

function parse_cli {
	for arg in "$@"; do # transform long options to short ones 
		shift
		case "$arg" in
			"--provider")     set -- "$@" "-c" ;;
			"--action")       set -- "$@" "-a" ;;
			"--env")          set -- "$@" "-e" ;;
			*)                set -- "$@" "$arg"
		esac
	done

	# Parse command line options safely using getops
	while getopts "c:a:e:" opt; do
		case $opt in
			c) provider=$OPTARG ;;
			a) action=$OPTARG ;;
			e) env=$OPTARG ;;
			\?)
				echo "Invalid option: -$OPTARG" >&2
				;;
		esac
	done
}

function check_cli { # by making sure that the requied options are supplied, etc.
	declare -a required_opts=("provider" "action")

	for opt in ${required_opts[@]};
	do
		if [[ "x${!opt}" == "x" ]]
		then
			echo "$opt is required"
			exit 1;
		fi
	done;

	if [[ ! -d $IAC_HOME/$provider ]]
	then
		echo "provider \"$provider\" doens't exist"
	fi

	if [[ $action != "migrate-default-workspace" ]]
	then
		echo "unknown action: $action"
	fi
}

# Verify that the prerequisite environment variable exists, otherwise things don't 
# work down the line.
function check_env {
	if [[ "x$IAC_HOME" == "x" ]] 
	then
		echo "please set IAC_HOME and try again"
		exit 1
	fi
}

function tf_migrate_default_workspace {
	local tfstate="terraform.tfstate"
	
	cd $IAC_HOME/$provider
	for i in *  # move terraform state files to workspace state based on env
	do
		if [[ -d $i && -f "$i/$tfstate" ]] 
		then
			if [[ ! -d "$i/$tfstate.d" ]]
			then 
				mkdir "$i/$tfstate.d"
			fi
			
			if [[ ! -d "$i/$tfstate.d/$env" ]]
			then
				mkdir "$i/$tfstate.d/$env"
			fi

			echo "moving $i/$tfstate to $i/$tfstate.d/$env"
			mv "$i/$tfstate" "$i/$tfstate.d/$env"

			if [[ -d $i && -f "$i/$tfstate.backup" ]] 
			then
				echo "moving $i/$tfstate.backup to $i/$tfstate.d/$env"
				mv "$i/$tfstate.backup" "$i/$tfstate.d/$env"
			fi
		fi
	done
}

# After command line arguments are parsed, this is the mail driver for this 
# script
function main {

	if [[ $action == "migrate-default-workspace" ]] 
	then
		tf_migrate_default_workspace
	fi
}

parse_cli $@
check_cli
main