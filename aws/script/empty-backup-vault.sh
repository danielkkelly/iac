
#!/bin/bash

# TODO: to get region: tfctl.sh --provider aws --module network --action output --env $env

declare VAULT_NAME="platform-backup-vault"

# Default to the default environment
declare env=dev
declare region=us-east-1

function parse_cli {
	for arg in "$@"; do # transform long options to short ones 
		shift
		case "$arg" in
			"--env")          set -- "$@" "-e" ;;
			"--region")       set -- "$@" "-r" ;;
			*)                set -- "$@" "$arg"
		esac
	done

	# Parse command line options safely using getops
	while getopts "e:r:" opt; do
		case $opt in
			e) env=$OPTARG ;;
			r) region=$OPTARG ;;
			\?)
				echo "Invalid option: -$OPTARG" >&2
				;;
		esac
	done
}

function main {
    local recovery_point_arns=`aws backup list-recovery-points-by-backup-vault \
                                --backup-vault-name platform-backup-vault \
                                --region $region \
                                --profile $env \
                                --query 'RecoveryPoints[].RecoveryPointArn' \
                                --output text`

    for arn in $recovery_point_arns
    do
        echo "deleting $arn..."
        aws backup delete-recovery-point --backup-vault-name $VAULT_NAME \
            --recovery-point-arn $arn \
            --region $region \
            --profile $env
    done
}

parse_cli $@
main