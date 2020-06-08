[General Setup](../README.md)

# AWS Requirements

* Install aws cli (v2)
* Configure aws (~/.aws/credentials and config)

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

# Patch Management 

We create the appropriate IAM object to allow our ins$ances to be managed by System Manager.  To verify,
after creating instances associated with IAM profile::

```
aws ssm describe-instance-information
```

Checking maintenance window details:

```
aws ssm describe-maintenance-window-executions --window-id `print-mw-id.sh`
aws ssm describe-maintenance-window-targets    --window-id `print-mw-id.sh`
```

Viewing Compliance:

```
aws ssm list-compliance-summaries
```

# Modules

* [IAM](iam/README.md)
* [VPN](client-vpn/README.md)
* [Docker](docker/README.md)
* [MSK](msk/README.md)

# References 

https://aws.amazon.com/blogs/security/how-to-patch-linux-workloads-on-aws/
