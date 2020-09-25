#!/usr/local/bin/bash
# Script that performs terraform operations across an entire provider
# TODO: add a task for upgrading terraform modules?

declare provider
declare module
declare env="dev"
declare action

declare -a targets=()

function parse_cli {
	for arg in "$@"; do # transform long options to short ones 
		shift
		case "$arg" in
			"--provider")     set -- "$@" "-c" ;;
			"--module")       set -- "$@" "-m" ;;
			"--action")       set -- "$@" "-a" ;;
			"--env")          set -- "$@" "-e" ;;
			*)                set -- "$@" "$arg"
		esac
	done

	# Parse command line options safely using getops
	while getopts "c:a:e:m:" opt; do
		case $opt in
			c) provider=$OPTARG ;;
			m) module=$OPTARG ;;
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
	declare -a valid_actions=("migrate-default-workspace" "output")

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

	if [[ ! " ${valid_actions[@]} " =~ " ${action} " ]];
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

# Specialty method, used if you are going from the default terraform state file to 
# workspaces.  This will convert your default state to a workspace specified by 
# the env command line argument.
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

function tf_print_output {
	local state_file="$IAC_HOME/$provider/$module/terraform.tfstate.d/$env/terraform.tfstate"
	if [[ -f $state_file ]]
	then
		terraform output -state=$state_file 2>/dev/null
		if [[ $? != 0 ]]; then
			exit 1
		fi
	fi
}

# After command line arguments are parsed, this is the mail driver for this 
# script
function main {
	if [[ $action == "migrate-default-workspace" ]] 
	then
		tf_migrate_default_workspace
	elif [[ $action == "output" ]]
	then
		tf_print_output
	fi
}

parse_cli $@
check_cli
main