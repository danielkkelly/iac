terraform output -state=$(dirname 0)/../ssm/terraform.tfstate | awk -F'[=&]' '{print $2}'
