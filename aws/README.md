[General Setup](../README.md)

# AWS Requirements

* Install aws cli (v2)
* Install the aws session manager plugin
* Configure aws (~/.aws/credentials and config)
* Create a user that will run terraform, a group, and role for that user
* Configure SSH and an AWS Key Pair

# Install AWS CLI and Session Manager plugin

I follow the download and install instructions that AWS provides.  This approach creates
directories under /usr/local and then creates symlinks to the appropriate binaries in 
/usr/local/bin.  It's easy to understand what is going on and how to roll back the install.
The instructions are a bit more generic.  That said you could use package managers to do
the same thing (e.g. brew if using a Mac).  More below.

* https://aws.amazon.com/cli/
* https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html

# Create a Terraform User

You can use terraform with straight forward credentials and config, shown in option 1. 
You could also use role-based authentication (RBAC) and MFA, shown in option 2.  You would
use option 2 for a more secure and enterprise ready approach.  Option 2 also lines up with
how users and groups are configured to get set up in [IAM](iam/README.md).

## Option 1 

* Create a terraform user and group
* Attach the AdministratorAccess policy to the group

## Option 2 - RBAC with MFA

* Create a user (e.g. "terraform" or a named user if you prefer)
* Create a group named for that user (e.g. "terraform")
* Add the terraform user to the terraform group
* Create a role (e.g. "terraform-role")
* Create a trust relationship with your account for terraform-role

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::12345678910:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```
* Attach the AdministratorAccess policy to terraform-role
* Create a policy to attach to the group (e.g. terraform-assume-role-policy)

```
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::12345678910:role/terraform-role",
    "Condition": {
      "Bool": {
        "aws:MultiFactorAuthPresent": "true"
      }
    }
  }
}
```

* Attach the above policy to the terraform group
* Add MFA for the user

If you go this route you'll use the advanced setup describe under 
[AWS Configuration](#aws-configuration).

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

## Advanced Setup

It's often a requirement to use MFA and role-based authentication.  This is possible and 
to do so follow the instructions in [IAM](iam/README.md).  We assume that users will be
set up this way by default and create a dev and dev-admin role plus the associated policies
to support it.

# Prerequisites

This is setup that is required prior to running buildctl.sh modules. 

* [TLS for the Load Balancer](alb/README.md#TLS)

# Modules

* [Settings](settings/README.md)
* [Security](security/README.md)
* [IAM](iam/README.md)
* [VPN](client-vpn/README.md)
* [Application Load Balancer](alb/README.md)
* [EKS](eks/README.md)
* [Docker](../ansible/docker/README.md)
* [Users](../ansible/users/README.md)
* [RDS](rds-mysql/README.md)
* [MSK](msk/README.md)

# Automation

* [Schema Deployment](../ansible/schemas/README.md)