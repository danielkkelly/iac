# Overview

This module moves database schemas and a setup script from $SCHEMA_HOME to the bastion 
host.  It installs the mysql client and configures it for your database server using 
the default user name and password (see aws/rds-mysql, gcp/cloud-sql).  It processes
your db-setup.sql script, then imports your schemas (in no particular order).

# Assumptions

* You have a db-setup.sql script that executes before your schemas are imported
* Scripts to create schemas are compressed with gzip and are normal MySQL exports

# Database Exports

It's likely that you'll need to use --set-gtid-purged=OFF when you export your database,
otherwise you get an error regarding SUPER privileges.  

## Example Export Script

```
#!/bin/sh

DIR="/home/me/backup"
TODAY=`date +"%Y-%m-%d"`
USER=manager
PASSWD=top-s3cr3t!
TARGET=$DIR/app-$TODAY.sql

mysqldump --databases appdb --single-transaction --set-gtid-purged=OFF \
          --user=$USER --password=$PASSWD --host=db-reader.dev.internal > $TARGET
/bin/gzip -9 $TARGET

/usr/bin/find $DIR -name "*.gz" -mtime +10 -exec rm {} \;
```