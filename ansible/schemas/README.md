# Overview

This module moves database schemas and a setup script from $SCHEMA_HOME to the bastion 
host.  It installs the mysql client and configures it for your database server using 
the default user name and password (see aws/rds-mysql, gcp/cloud-sql).  It processes
your db-setup.sql script, then imports your schemas (in no particular order).

# Assumptions

* You have a db-setup.sql script that executes before your schemas are imported
* Scripts to create schemas are compressed with gzip

# Database Exports

It's likely that you'll need to use --set-gtid-purged=OFF when you export your database,
otherwise you get an error regarding SUPER privileges.  
