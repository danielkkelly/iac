#!/usr/local/bin/bash
# Script to create infrastructure based on defined modules and thier associated
# targets Run terraform or ansible for each target based on the configuration in 
# JSON model below.

declare provider
declare module
declare action
declare terraform=false
declare ansible=false
declare playbook="playbook.yaml"
declare env="dev"
declare auto_approve
declare verbose=false

declare -a instructions_json=()

function parse_cli {
	for arg in "$@"; do # transform long options to short ones 
		shift
		case "$arg" in
			"--provider")     set -- "$@" "-c" ;;
			"--module")       set -- "$@" "-m" ;;
			"--action")       set -- "$@" "-a" ;;
			"--terraform")    set -- "$@" "-t" ;;
			"--ansible")      set -- "$@" "-n" ;;
			"--playbook")     set -- "$@" "-p" ;;
			"--env")          set -- "$@" "-e" ;;
			"--auto-approve") set -- "$@" "-b" ;;
			"--verbose") 	  set -- "$@" "-v" ;;
			*)                set -- "$@" "$arg"
		esac
	done

	# Parse command line options safely using getops
	while getopts "c:m:a:tnp:e:bv" opt; do
		case $opt in
			c) provider=$OPTARG ;;
			m) module=$OPTARG ;;
			a) action=$OPTARG ;;
			t) terraform=true ;;
			n) ansible=true ;;
			v) verbose=true ;;
			p) playbook=$OPTARG ;;
			e) env=$OPTARG ;;
			b) auto_approve="--auto-approve" ;;
			\?)
				echo "Invalid option: -$OPTARG" >&2
				;;
		esac
	done
}

function check_cli { # by making sure that the requied options are supplied, etc.
	declare -a required_opts=("provider" "module" "action")

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

# Determines whether or not the target is a virtual machine instance.  This allows us 
# to check whether or not we need to wait for it to spin up, etc.
function is_vm {
	local value=`cat $IAC_HOME/$provider/buildctl.json | 
		jq -r -c ".resources[] | select(.target==\"${target}\").type"` 

	if [[ "x$value" == "x" ]]
	then
		return 1
	else
		return 0
	fi
}

# This method wil check if there's an VM instance for the given target.  Not all
# targets are VM instances.  This will make a CLI call for each regardless but 
# better than managing meta data on targets, at least for now.
function wait_for_instance {
	local target=$1
	local instance_id=`print-ec2.sh --hostType $target --env $env`

	if ! is_vm $target 
	then
		return 0
	fi

	if [[ "x$instance_id" != "x" ]] # we have an EC2 instance
	then
		echo "$target is a VM instance, waiting..."
		aws ec2 wait instance-status-ok --instance $instance_id --profile $env
	else 
		echo "$target isn't available"
		return 1
	fi
}

# Execute terraform for the module specified.  Provide the action as an argument.
function exec_terraform {
	local target=$1
	local action=$2
	local target_dir="$IAC_HOME/$provider/$1"
	local tf_state_dir="$target_dir/terraform.tfstate.d"

	if [[ -f "$target_dir/tf.sh" ]]
	then
		cd $target_dir  # module

		if [[ ! -d $target_dir/.terraform ]] # initialize terraform
		then
			terraform init
		fi	

		if [[ ! -d $tf_state_dir || ! -d $tf_state_dir/$env ]] # initialize workspace
		then
			terraform workspace new $env
		fi

		# switch to workspace
		terraform workspace select $env

		# execute action
		./tf.sh $action $env $auto_approve
	fi
}

# Execute ansible for the given module and use the playbook specified.
function exec_ansible {
	local target=$1
	local playbook=$2
	local playbook_file="$IAC_HOME/ansible/$target/$playbook"

	if [[ $action == "destroy" ]] # no need to run scripts
	then 
		return
	fi

	if [[ -f $playbook_file ]] # continue
	then
		if wait_for_instance $target; 
		then
			ansible-playbook $playbook_file \
				--extra-vars "@$IAC_HOME/ansible/env-$env.json"
		fi
	fi
}

# Searches our JSON model array to pull the correct object and then the requested
# property.  
function get_model_value {
	local module=$1
	local action=$2
	local property=$3

	local value=`cat $IAC_HOME/$provider/buildctl.json | 
		jq -r -c ".modules[] | select(.module==\"${module}\" 
				                  and .action==\"${action}\").$property"`
	echo $value
}

# Convert a bash array to a JSON array string. This uses "compact" format, which
# removes whites space. 
function array_to_json {
	local array=($@)	
	echo $(printf '%s\n' "${array[@]}" | jq -R '.' | jq -c -s)
}

# Convert a JSON array to a bash array.
function json_to_array {
	echo $(echo $1 | jq -c -r '.[]')
}

# Prepares the list of targets for processing.  This method will also expand the
# list of targets based on dependencies.
function configure_targets {
	local module=$1
	local instruction=("$@") # will get the module as well, i.e. four elements
	local targets=$(get_model_value $module $action "target")

	if [[ "x$targets" != "x" ]]; then # this is an instruction
		local instruction=($(get_model_value $module $action "terraform")
					       $(get_model_value $module $action "ansible")
					       $(get_model_value $module $action "playbook"))
	else # leaf
		instructions_json+=($(array_to_json ${instruction[@]}))
	fi
	
	for target in $(json_to_array $targets)
	do
		configure_targets $target "${instruction[@]}"
	done;	
}

# Prints the instructions for the module requested as well as dependancies.
function print_instructions {
	for instruction_json in ${instructions_json[@]};
	do
		echo $instruction_json
	done
}

# After command line arguments are parsed, this is the mail driver for this 
# script
function main {
	# Basic configuration work before processing
	configure_targets $module $terraform $ansible $playbook
	
	if [[ $verbose == true ]]
	then
		print_instructions
	fi

	for instruction_json in ${instructions_json[@]};
	do
		instruction=($(json_to_array $instruction_json))
		local target=${instruction[0]}
		local target_terraform=${instruction[1]}
		local target_ansible=${instruction[2]}
		local target_playbook=${instruction[3]}

		if [[ $terraform == true && $target_terraform == true ]]
		then
			exec_terraform $target $action
		fi
		
		if [[ $ansible == true && $target_ansible == true ]]
		then
			exec_ansible $target $target_playbook
		fi
	done
}

parse_cli $@
check_env
check_cli
main