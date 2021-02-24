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
The second is to use System Manager to create sessions to your hosts.  The simplest
configuration to use Session Manager is to update the line below in your SSH config.

```
Host dev-bastion
   ProxyCommand nc `print-ip.sh` %p

```

becomes

```
host dev-bastion
   ProxyCommand sh -c "aws ssm start-session --target `print-ec2.sh --env dev --hostType bastion` --document-name AWS-StartSSHSession --parameters 'portNumber=%p'"
```

Same for test, etc.

You should use the system manager approach for AWS.  If you decide you want to use a pulbic 
bastion host then you'll need to modify the HCL for the AWS bastion host by uncommenting the 
lines that create the public EIP and modify the network to put the bastion host on a public 
subnet instead of a private subnet. 

The above change should be all that is required.  Because we use the bastion host as 
our jump host in either scenario, the rest of the SSH Config specified in [General Setup](../README.md)
remains accurate.  However, you could use session manager to go directly to those hosts
if you like as well.

# Create a KeyPair in whatever region(s) you will use

AWS uses a key pair to default the default SSH keys for a newly created EC2 instance.  You'll need to 
create a key pair and pull it down for logging into the instance and use with Ansible.

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

If you set up the ALB then you will need to run alb-tls first, like below.

```
buildctl.sh --provider aws --module alb-tls --action apply --terraform --ansible --auto-approve --env dev
```

AWS has limits on how many certificates you can deploy in a given year.  You could run this each time you build your environment but would eventually hit your quota and uploading the generated cert would fail.  One option is to work with AWS to increase your quota and add alb-tls to buildctl.json so it runs with each apply / destroy of your environment.  The other option is to run alb-tls yearly.  By default we use the later in our default configuration.

# Modules

* [Settings](settings/README.md)
* [Security](security/README.md)
* [IAM](iam/README.md)
* [VPN](client-vpn/README.md)
* [EKS with Fargate](eks-fargate/README.md)
* [EKS with Managed Node Groups](eks-node-groups/README.md)
* [Docker](../ansible/docker/README.md)
* [Users](../ansible/users/README.md)
* [RDS](rds-mysql/README.md)
* [MSK](msk/README.md)

# Automation

* [Schema Deployment](../ansible/schemas/README.md)