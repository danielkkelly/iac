[General Setup](../README.md)

# AWS Requirements

* Install aws cli (v2)
* Install the aws session manager plugin
* Configure aws (~/.aws/credentials and config)

## Installing

I follow the download and install instructions that AWS provides.  This approach creates
directories under /usr/local and then creates symlinks to the appropriate binaries in 
/usr/local/bin.  It's easy to understand what is going on and how to roll back the install.
The instructions are a bit more generic.  That said you could use package managers to do
the same thing (e.g. brew if using a Mac)

# SSH Config

You have two options for SSH with AWS.  The first is to use a public bastion host.
The second is to use Session Manager to create sessions to your hosts.  The short of 
it is that you should use session manager.  This is our default for AWS and you'll 
modify the configuration in [General Setup](../README.md) as show below:

```
Host dev-bastion
   ProxyCommand nc `print-ip.sh` %p

```

becomes

```
host dev-bastion
   ProxyCommand sh -c "aws ssm start-session --profile dev --target `print-ec2.sh --env dev --hostType bastion` --document-name AWS-StartSSHSession --parameters 'portNumber=%p'"
```

and even more concise, if you use the script I provided, is

```
host dev-bastion
   ProxyCommand sh -c "start-ssm-session.sh --env dev --port %p"
```

Same for test, etc.  

More information in [Bastion](bastion/README.md).

# Create a KeyPair in whatever region(s) you will use

AWS uses a key pair to default the default SSH keys for a newly created EC2 instance.  You'll need to 
create a key pair and pull it down for logging into the instance and use with Ansible.  See EC2 /
Network & Security / Key Pairs.  If you already have a key pair you can import its public key.

# AWS Configuration

AWS allows the definition of different credientials and profiles.  Some of the scripts in this project 
rely on that to determine the target environment.  Example of a ~/.aws/credentials file:

```
[default]
aws_access_key_id=your_key_id
aws_secret_access_key=your_access_key

[dev]
aws_access_key_id=your_key_id
aws_secret_access_key=your_access_key

[test]
aws_access_key_id=your_key_id
aws_secret_access_key=your_access_key
```

And ~/.aws/config:

```
[default]
region=us-east-1

[profile dev]
region=us-east-1

[profile test]
region=us-east-2
```

# Prerequisites

* [TLS for the Load Balancer](alb/README.md#TLS)

# Modules

* [Settings](settings/README.md)
* [Security](security/README.md)
* [IAM](iam/README.md)
* [VPN](client-vpn/README.md)
* [Application Load Balancer](alb/README.md)
* [EKS with Fargate](eks-fargate/README.md)
* [EKS with Managed Node Groups](eks-node-groups/README.md)
* [Docker](../ansible/docker/README.md)
* [Users](../ansible/users/README.md)
* [RDS](rds-mysql/README.md)
* [MSK](msk/README.md)

# Automation

* [Schema Deployment](../ansible/schemas/README.md)