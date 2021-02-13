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