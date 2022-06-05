[General Setup](../README.md)

# Overview

This module sets up system manager.  It updates the identify and access management 
configuration to set up roles and policies to support System Manager related operations, 
such as automatic patching, as well as configures maintenace windows, patching, etc.

Systems Manager allows fleet management.  Use it to:

* View details about your fleet of EC2 instances (Fleet Manager)
* Patch your EC2 instances (Patch Manager)
* View compliance 

# Implementation

This codebase enables automatic patching.  We set up a patch baseline, a maint-
enanace window, and approval rules for patching.

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

# References 

https://aws.amazon.com/blogs/security/how-to-patch-linux-workloads-on-aws/