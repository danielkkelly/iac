[General Setup](../README.md)

# AWS Requirements

* Install aws cli (v2)
* Configure aws (~/.aws/credentials and config)

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

# Running Terraform and Ansible

You need to run things in the correct order.

1. localhost 
2. iam
3. network
4. ssm
5. bastion
6. docker
7. syslog
8. rds-mysql
9. configure syslog clients

After creating these you could run the other scripts in whatever order you like.

You could also use buildctl.sh for this purpose.  If you decide to use that then
set IAC_HOME to wherever you put the top level directory of this project.  Then
execute the command:

```
./buildctl.sh --module base --action apply    # build
./buildctl.sh --module base --action destroy  # tear down
```

This executes the terraform and ansible modules above in the proper order.  You 
could also use the command below to execute a single module, in this case the 
bastion server.

```
./buildctl.sh --module bastion --action apply --terraform --ansible
```

Use the --terraform and --ansible options to toggle those on (or omit for off).

The builctl.sh script has metadata as an array of JSON objects.  Review that for
all of the available modules and their configurations.  Currently includes "base",
"all", and "syslog-clients".  Single modules (e.g. bastion) don't have entries 
but you could run them as shown above .

# References 

https://aws.amazon.com/blogs/security/how-to-patch-linux-workloads-on-aws/
