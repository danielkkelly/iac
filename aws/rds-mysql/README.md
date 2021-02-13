# Overview

If a database user matches the policy that allows IAM authentication, then authentication
is done with a secure token vs. regular password.  AWS geenrates the token, which is valid
for a short time, and the token is pass on the connect string to the database to authenti-
cate.  This also ensures that the connection uses SSL.

In our setup, we create three generic users that are configured for IAM authentication. 
We create a read only user, one that has DML priviledges, and one that has DDL.  A user
will choose from these three.  Because the user is using IAM, we know exactly who requested
use of the generic ID.

You could get more specific about individual users in the policy but the approach above 
keeps it relatively straight-forward.  My applications use a regular MySQL user name and 
password and IAm authentication for developers.

# IAM Policy and Group Attachment

To use RDS IAM authentication requires a policy for the accounts that will authenticate
using IAM.  We set up the policy and attach it to our dev and dev-admin groups created
in the IAM module.

# Setting up MySQL Users

## setup.sql

In the schemas module, which uses ansible to set up a database server and install snapshots
of existing schemas, you could modify setup.sql to add your users.  This is the approach 
that I've taken.  Your setup would include SQL statements like the ones below.

```
# Generic users for RDS IAM authentication
create user 'dev-ro' identified with AWSAuthenticationPlugin AS 'RDS';
create user 'dev-dml' identified with AWSAuthenticationPlugin AS 'RDS';
create user 'dev-ddl' identified with AWSAuthenticationPlugin AS 'RDS';

grant select on *.* TO 'dev-ro'@'%';
grant delete, insert, select, update, create temporary tables on *.* to 'dev-dml'@'%';
grant all privileges on *.* to 'dev-ddl'@'%';
```

## Terraform

In our case the database server is on private subnets.  Access is required for Terraform
to connect with its MySQL provider.  If you have access to your RDS server you could use
Terraform to create users, as shown below.

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
  privileges = ["ALL"]
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

More on https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/UsingWithRDS.IAMDBAuth.Connecting.AWSCLI.html.

## SSL Certificate for MySQL

You will first need to download the combined (CA and intermediate cert) from AWS.  In short, the command below
will get what you need.

```
wget https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem
```

See https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/UsingWithRDS.SSL.html.

## Generate an authentication token

TODO: does this work with our generic CNAME for the database?  If now, how to automatically get the host name
Is region required or will it default to the specified region in the AWS config?

```
MYSQL_AUTH_TOKEN=`aws rds generate-db-auth-token \
   --hostname rdsmysql.123456789012.us-west-2.rds.amazonaws.com \
   --port 3306 \
   --region us-east-1 \
   --username`
```

## MySQL client connection

TODO: hostname from CNAME possible?
```
mysql --host=hostName --port=3306 \
      --ssl-ca=rds-combined-ca-bundle.pem \
      --enable-cleartext-plugin \
      --user=dev-ro \
      --password=$MYSQL_AUTH_TOKEN
```