#!/bin/bash
# This script rotates access keys for users created with the IAC AWS IAM module.
# Keys are rotated in place.  They are marked as "tainted" in Terraform state, 
# which causes Terraform to rebuild them in place the next time that the module
# is applied.  
#
# After execution you simply need to distribute the new access keys # to your 
# users.  You could do this via copy / past into an e-mail or write a more 
# sophisticated script that does all of that automatically as well.
# 
# This script allows you to pass the --env option to specify the environment you
# would like to address.  It will automatically set the workspace for you.

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
	while getopts "c:a:b:e:m:" opt; do
		case $opt in
			e) env=$OPTARG ;;
			\?)
				echo "Invalid option: -$OPTARG" >&2
				;;
		esac
	done
}

function main {
    cd $IAC_HOME/aws/iam 

    # Set the environment
    terraform workspace select $env

    # Iterate through the created access keys
    for access_key in $(terraform state list | grep access_key)
    do
        # Taint the state of each record to force Terraform
        # to recreate the resource
        terraform taint $access_key
    done

    # Run the plan for IAM to recreate access keys
    buildctl.sh --provider aws --module iam \
                --action apply \
                --terraform \
                --auto-approve
}

parse_cli $@
main