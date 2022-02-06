# AWS config
[profile ha-monitor]
region            = us-east-2
credential_source = Ec2InstanceMetadata
role_arn          = arn:aws:iam::464267695814:role/platform-test-ha-monitor-role

# Install keepalived
sudo yum install keepalived

# Instance data v2 calls - can use to get the IPv4 address of the current host
TOKEN=`curl -X PUT "http://instance-data/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://instance-data/latest/meta-data/local-hostname
curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://instance-data/latest/meta-data/instance-id
curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://instance-data/latest/meta-data/local-ipv4

# After reassigning the VIP need to call "sudo systemctl restart network" on the host receiving the VIP
sudo systemctl restart network

# Script to move a VIP (secondary IP) to the primary host IP passed on the command line
#!/bin/bash

declare VIP="10.2.2.21"

function get_eni {
        local primary_ip_address=$1

        echo $(aws ec2 describe-instances --profile ha-monitor \
            | jq -r ".Reservations[] 
                     | .Instances[] 
                     | .NetworkInterfaces[] 
                     | select(.PrivateIpAddresses[].Primary==true and 
                              .PrivateIpAddresses[].PrivateIpAddress==\"$primary_ip_address\") 
                     | .NetworkInterfaceId")
}

function main {
        local vip_host_ip=$1

        aws ec2 assign-private-ip-addresses --profile ha-monitor \
                --allow-reassignment \
                --network-interface-id $(get_eni $vip_host_ip) \
                --private-ip-addresses $VIP
}

main $1


#!/bin/bash

#############--USER DEFINED VARIABLES SET HERE--##############
#Set the AWS credentials here if you didn't create an IAM instance profile
#export AWS_ACCESS_KEY_ID=
#export AWS_SECRET_ACCESS_KEY=

#Set the AWS default region
export AWS_DEFAULT_REGION=

#Set the internal or private DNS names of the HA nodes here
HA_NODE_1=
HA_NODE_2=

#Set the ElasticIP ID Value here
ALLOCATION_ID=
###############################################################

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin

#Values passed in from keepalived
TYPE=$1
NAME=$2
STATE=$3

#Determine the internal or private dns name of the instance
LOCAL_INTERNAL_DNS_NAME=`wget -q -O - http://instance-data/latest/meta-data/local-hostname`
LOCAL_INTERNAL_DNS_NAME=`echo $LOCAL_INTERNAL_DNS_NAME | sed -e 's/% //g'`

#OTHER_INSTANCE_DNS_NAME is the other node than this one, default assignment is HA_NODE_1
OTHER_INSTANCE_DNS_NAME=$HA_NODE_1

#Use LOCAL_INTERNAL_DNS_NAME to determine which node this is and to set the Other Node name
if [ "$HA_NODE_1" = "$LOCAL_INTERNAL_DNS_NAME" ]
then
    OTHER_INSTANCE_DNS_NAME=$HA_NODE_2
fi

#Get the local instance ID
INSTANCE_ID=`wget -q -O - http://instance-data/latest/meta-data/instance-id`
INSTANCE_ID=`echo $INSTANCE_ID | sed -e 's/% //g'`

#Get the instance ID of the other node
OTHER_INSTANCE_ID=`aws ec2 describe-instances --filter "Name=private-dns-name,Values=$OTHER_INSTANCE_DNS_NAME" | /usr/bin/python -c 'import json,sys;obj=json.load(sys.stdin); print obj["Reservations"][0]["Instances"][0]["InstanceId"]'`

#Get the ASSOCIATION_ID of the ElasticIP to the Instance
ASSOCIATION_ID=`aws ec2 describe-addresses --allocation-id $ALLOCATION_ID | /usr/bin/python -c 'import json,sys;obj=json.load(sys.stdin); print obj["Addresses"][0]["AssociationId"]'`

#Get the INSTANCE_ID of the system the ElasticIP is associated with
EIP_INSTANCE=`aws ec2 describe-addresses --allocation-id $ALLOCATION_ID | /usr/bin/python -c 'import json,sys;obj=json.load(sys.stdin); print obj["Addresses"][0]["InstanceId"]'`

STATEFILE=/var/run/nginx-ha-keepalived.state

logger -t nginx-ha-keepalived "Params and Values: TYPE=$TYPE -- NAME=$NAME -- STATE=$STATE -- ALLOCATION_ID=$ALLOCATION_ID -- INSTANCE_ID=$INSTANCE_ID -- OTHER_INSTANCE_ID=$OTHER_INSTANCE_ID -- EIP_INSTANCE=$EIP_INSTANCE -- ASSOCIATION_ID=$ASSOCIATION_ID -- STATEFILE=$STATEFILE"

logger -t nginx-ha-keepalived "Transition to state '$STATE' on VRRP instance '$NAME'."

case $STATE in
        "MASTER")
                  aws ec2 disassociate-address --association-id $ASSOCIATION_ID
                  aws ec2 associate-address --allocation-id $ALLOCATION_ID --instance-id $INSTANCE_ID
                  service nginx start ||:
                  echo "STATE=$STATE" > $STATEFILE
                  exit 0
                  ;;
        "BACKUP"|"FAULT")
                  if [ "$INSTANCE_ID" = "$EIP_INSTANCE" ]
                  then
                    aws ec2 disassociate-address --association-id $ASSOCIATION_ID
                    aws ec2 associate-address --allocation-id $ALLOCATION_ID --instance-id $OTHER_INSTANCE_ID
                    logger -t nginx-ha-keepalived "BACKUP Path Transfer from $INSTANCE_ID to $OTHER_INSTANCE_ID"
                  fi
                  echo "STATE=$STATE" > $STATEFILE
                  exit 0
                  ;;
        *)        logger -t nginx-ha-keepalived "Unknown state: '$STATE'"
                  exit 1
                  ;;
esac