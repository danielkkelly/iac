function get_terraform_output_value {
    local provider=$1
	local module=$2
	local output_name=$3
	local output_name_value=$(tfctl.sh --provider $provider --module $module --env $env --action output)
	local output_value=$(echo "$output_name_value" | sed -n "s/^$output_name = //p" | sed 's/"//g')
	echo $output_value
}