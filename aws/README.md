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
* [MSK](msk/README.md)

# Automation

* [Schema Deployment](../ansible/schemas/README.md)

# References 

https://aws.amazon.com/blogs/security/how-to-patch-linux-workloads-on-aws/
