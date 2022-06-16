# Overview

RDS IAM authentication is done with a secure token vs. regular password.  AWS geenrates the 
token, which is valid for a short time, and the token is passed on the connect string to the 
database to authenticate.  This eliminates the need for passwords, passes authentication to 
IAM to enhance loging and centralize managment, and also ensures that the connection uses SSL.

IAM authentication requires a policy that defines the type of access that is allowed.  In our
case, we allow IAM authentication for all users that are created (in the database) with the 
the authentication plugin of "AWSAuthenticationPlugin".  We attach this policy to the dev 
roles that we create earlier in the process so that IAM authentication is available to developers
and developer admins.

From a MySQL perspective, we create three generic users that are configured for IAM authentication. 
We create a read only user, one that has DML priviledges, and one that has DDL.  A user
will choose from these three to obtain the desired privileges, preferably using the user of least
privilege for the given task.  Because the user is using IAM, we know exactly who authenticates
despite use of the generic ID.

You could get more specific about individual users in the policy but the approach above 
keeps it relatively straight-forward.  My applications use a regular MySQL user name and 
password and IAM authentication for developers.  There are some performance related concerns with
using IAM authentication for applications.

# Instance Class

Choose the correct instance class for your use cases.  By default the rds_instance_class in 
variables.tf sets the instance class to something reasonable for personal use of a featurful
web app.  You'll need to select the correct memory, CPU, and network performance.  

Also, make sure you have enough capacity for connections.  For example, t2.medium has a 
max_connections default value of 90.  AWS recommends scaling connections by icreasing the 
size of the instance, as max_connections scales with memory by default.  You could also simply
increase max_connections for any given instance class if the recommendation doesn't fit your
use case.

https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraMySQL.Managing.Performance.html
https://aws.amazon.com/premiumsupport/knowledge-center/rds-mysql-max-connections/


# IAM Policy and Group Attachment

To use RDS IAM authentication requires a policy for the accounts that will authenticate
using IAM.  We set up the policy and attach it to our dev and dev-admin groups created
in the IAM module.

# Non-standard Port

For security purposes we avoid using the standard MySQL port of 3306.  Instead our default is 8809.
Update variables.tf and the mysql_port variable to change the default port.  Make sure any network
ACLs (network/nacl.tf) and security groups are also updated accordingly.  Also update automation - 
i.e. ansible/schemas.

# Setting up MySQL Users

## Using SQL Scripts

In the schemas module, which uses ansible to set up a database server and install snapshots
of existing schemas, you could modify setup.sql to add your users.  This is the approach 
that I've taken.  Your setup would include SQL statements like the ones below.

```
# Generic users for RDS IAM authentication
create user 'dev-ro'@'%' identified with AWSAuthenticationPlugin AS 'RDS';
create user 'dev-dml'@'%' identified with AWSAuthenticationPlugin AS 'RDS';
create user 'dev-ddl'@'%' identified with AWSAuthenticationPlugin AS 'RDS';

grant select on *.* TO 'dev-ro'@'%';
grant delete, insert, select, update, create temporary tables on *.* to 'dev-dml'@'%';
grant delete, insert, select, update, create temporary tables, create view, show view, alter, drop, index, process on *.* to 'dev-ddl'@'%';
```

## Using Terraform

In our case the database server is on private subnets.  Access is required for Terraform
to connect with its MySQL provider.  If you have access to your RDS server you could use
Terraform to create users, as shown below.  NOTE: you will need to update and test the 
work below.  I favor and use the prior approach using a SQL script.  I've included this 
section because I spent time researching it and it could be helpful for those who better
fit this use case.

```
provider "mysql" {
  endpoint = aws_rds_cluster.platform_rds_cluster.endpoint
  username = aws_rds_cluster.platform_rds_cluster.master_username
  password = aws_rds_cluster.platform_rds_cluster.master_password
}

# Read only
resource "mysql_user" "dev_ro_mysql_user" {
  user = "dev-ro"
  host = "%"
  auth_plugin = "AWSAuthenticationPlugin"
}

resource "mysql_grant" "dev_ro_mysql_grant" {
  user       = mysql_user.dev_ro_mysql_user.user
  host       = mysql_user.dev_ro_mysql_user.host
  database   = "*"
  privileges = ["SELECT"]
}

# DML only
resource "mysql_user" "dev_dml_mysql_user" {
  user = "dev-dml"
  host = "%"
  auth_plugin = "AWSAuthenticationPlugin"
}

resource "mysql_grant" "dev_dml_mysql_grant" {
  user       = mysql_user.dev_dml_mysql_user.user
  host       = mysql_user.dev_dml_mysql_user.host
  database   = "*"
  privileges = ["SELECT", "INSERT", "UPDATE", "DELETE", "CREATE TEMPORARY TABLES"]
}

# DDL
resource "mysql_user" "dev_ddl_mysql_user" {
  user = "dev-ddl"
  host = "%"
  auth_plugin = "AWSAuthenticationPlugin"
}

resource "mysql_grant" "dev_ddl_mysql_grant" {
  user       = mysql_user.dev_ddl_mysql_user.user
  host       = mysql_user.dev_ddl_mysql_user.host
  database   = "*"
  privileges = [...]
}
```

It's possible you'll need to open your security group up to your Terraform host.

```
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}
```

And then in your ingress rules.

```   
     // open to any on the private subnets
    cidr_blocks = [var.cidr_block_subnet_pri_1,
      var.cidr_block_subnet_pri_2,
      var.cidr_block_subnet_vpn_1,
      "${chomp(data.http.myip.body)}/32"
    ]
```

# Connecting to the database server

Connecting to the database server using IAM authentication is fairly straight-forward.
The first step is making sure that you have an SSL certificate for your MySQL client.  In
My work I'm assuming you're using the MySQL CLI.  Other solutions, like IntelliJ, VS Code,
SQL Workbench, etc, could be different.  Perhaps as I roll this out to my team I'll gain
some more experience with the above tools and update this section.  For now, assume the 
MySQL CLI.

More on https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/UsingWithRDS.IAMDBAuth.Connecting.AWSCLI.html.

## SSL Certificate for MySQL

You will first need to download the combined (CA and intermediate cert) from AWS.  In short, the command below
will get what you need.

```
wget https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem
```

See https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/UsingWithRDS.SSL.html.

## Generate an authentication token

The command below will generate an RDS authentication token.  Note that you could specify defaults but that 
isn't stricly necessary.  If your region is specified in your AWS config, for example, no need to supply it.

```
MYSQL_AUTH_TOKEN=`aws rds generate-db-auth-token --hostname $(print-rds-endpoint.sh) --port 8809  --username=dev-ro`
```

We capture the token in the MSQL_AUTH_TOKEN environment variable so that it's easy to pass it along to the 
MySQL client and the token won't show in the shell's history.

## MySQL client connection

The two common scenarios used for testing our congigurations are to connect from a VM within our VPC, like
the bastion server, or to connect using SSH forwarding.  The command below will work from the bastion server.

```
mysql --host=db-writer.dev.internal --port=8809 --ssl-ca=rds-combined-ca-bundle.pem  --user=dev-ro --password=$MYSQL_AUTH_TOKEN
```

The more common scenario is to connect via port forwarding through the bastion host from your local machine.
The command below will take care of that for you.  Note that your command could differ slightly if you use 
a different OS, etc.  Mac shown below.

```
mysql --host 127.0.0.1 \
  --port=18809 \
  --ssl-ca=rds-combined-ca-bundle.pem \
  --user=dev-ro \
  --password=$MYSQL_AUTH_TOKEN \
  --enable-cleartext-plugin
```

## MySQL Client Variations

We install the mysql commandline tools on the bastion host (../../ansible/schemas/README.md).  Note that
--enable-cleartext-plugin doesn't seem to be an option for that installation.  However, omitting that
from the command line arguments doesn't have an effect.  That said, on my local machine omitting that 
option is an issue.

# Log Files

Log files are stored on disk vs. table.  This is more performant and allows AWS to automatically rotate
logs on our behalf vs. performing that task manually.  Logs are easily retrieved by doing the following:

```
aws rds describe-db-log-files --db-instance-identifier platform-rds-cluster-0
```

This results in a list of files available.

```
{
    "DescribeDBLogFiles": [
        {
            "LogFileName": "error/mysql-error-running.log",
            "LastWritten": 1615930200000,
            "Size": 38492
        },
...
```

```
aws rds download-db-log-file-portion --db-instance-identifier platform-rds-cluster-0 \
	--log-file-name error/mysql-error-running.log \
	--output text > mysql-error.log
```

Or for the slow query log.

```
aws rds download-db-log-file-portion --db-instance-identifier platform-rds-cluster-0 \
	--log-file-name slowquery/mysql-slowquery.log \
	--output text > mysql-slowquery.log
```
