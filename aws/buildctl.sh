#!/usr/local/bin/bash
# Script to create infrastructure based on defined modules and thier associated
# targets Run terraform or ansible for each target based on the configuration in 
# JSON model below.

declare module
declare action
declare terraform=false
declare ansible=false
declare playbook="playbook.yaml"

declare -a targets=()

function parse_cli {
	for arg in "$@"; do # transform long options to short ones 
		shift
		case "$arg" in
			"--module")       set -- "$@" "-m" ;;
			"--action")       set -- "$@" "-a" ;;
			"--terraform")    set -- "$@" "-t" ;;
			"--ansible")      set -- "$@" "-n" ;;
			"--playbook")     set -- "$@" "-p" ;;
			*)                set -- "$@" "$arg"
		esac
	done

	# Parse command line options safely using getops
	while getopts "m:a:tnp:" opt; do
		case $opt in
			m) module=$OPTARG ;;
			a) action=$OPTARG ;;
			t) terraform=true ;;
			n) ansible=true ;;
			p) playbook=$OPTARG ;;
			\?)
				echo "Invalid option: -$OPTARG" >&2
				;;
		esac
	done
}

function check_cli { # by making sure that the requied options are supplied, etc.
	declare -a required_opts=("module" "action")

	for opt in ${required_opts[@]};
	do
		if [[ "x${!opt}" == "x" ]]
		then
			echo "$opt is required"
			exit 1;
		fi
	done;
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

# Determines if an EC2 instance of the type hostType is running.  This works for
# now given that we have one of each type.
function is_instance_available {
		local instanceId=`print-ec2.sh --hostType $1`

		if [[ "x$instanceId" == "x" ]]
		then
			return 1 # false
	    else
			return 0 # true
		fi
}

# This method wil check if there's an EC2 instance for the given target.  Not all
# targets are EC2 instances.  This will make a CLI call for each regardless but 
# better than managing meta data on targets, at least for now.
function wait_for_instance {
	local target=$1
	local instance_id=`print-ec2.sh --hostType $target`

	if [[ "x$instance_id" != "x" ]] # we have an EC2 instance
	then
		echo "$target is an EC2 instance, waiting..."
		aws ec2 wait instance-status-ok --instance $instance_id
	else 
		echo "$target isn't available"
		return 1
	fi
}

# Execute terraform for the module specified.  Provide the action as an argument.
function exec_terraform {
	local target=$1
	local action=$2
	local target_dir="$IAC_HOME/aws/$1"

	if [[ -f "$target_dir/tf.sh" ]]
	then
		cd $target_dir  # module
		./tf.sh $action # action
	fi
}

# Execute ansible for the given module and use the playbook specified.
function exec_ansible {
	local target=$1
	local playbook=$2
	local playbook_file="$IAC_HOME/aws/$target/$playbook"

	if [[ $action == "destroy" ]] # no need to run scripts
	then 
		return
	fi

	if wait_for_instance $target; 
	then
		if [[ -f $playbook_file ]] # run the playbook
		then
			ansible-playbook $playbook_file
		fi
	fi
}

# Searches our JSON model array to pull the correct object and then the requested
# property.  The object represents the module or directory where we have our
# configuration for terraform, ansible, or both.
function get_model_value {
	local module=$1
	local action=$2
	local property=$3

	local value=`cat $IAC_HOME/aws/buildctl.json | 
		jq -r -c ".modules[] | select(.module==\"${module}\" 
				                  and .action==\"${action}\").$property"`

	if [[ "x${value}" == "x" ]] # grab the default value 
	then
		value="${!property}"
	fi
	echo $value
}

# Prepares the list of targets for processing.  This is done as a separate loop 
# because the "while read" causes issues if we process targets in the same loop
# where underlying commands wait for input.  Additionally, this is cleaner even 
# at the expense of another loop.
function configure_targets {
	local target=$(get_model_value $module $action "target")

	if [[ "x${target}" == "x" ]] # add the module as the target
	then
		targets+=($module)
	else 
		targets=($(echo $target | jq -c -r '.[]'))
	fi
}

# Reads configuration from the model and sets the appropriate global variables.
function configure_globals {
	terraform=$(get_model_value $module $action "terraform")
	ansible=$(get_model_value $module $action "ansible")
	playbook=$(get_model_value $module $action "playbook")
}

# After command line arguments are parsed, this is the mail driver for this 
# script
function main {
	# Basic configuration work before processing
	configure_globals
	configure_targets

	for target in ${targets[@]}; # execute scripts
	do
		if [[ $terraform == true ]]
		then
			exec_terraform $target $action
		fi
		
		if [[ $ansible == true ]]
		then
			exec_ansible $target $playbook
		fi
	done
}

parse_cli $@
check_cli
check_env
main