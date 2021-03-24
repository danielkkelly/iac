[General Setup](../README.md)

# Overview

This module manages global settings for the account / region, etc.  The settings we
use as default are per the AWS best practices for security.

# EBS Volumes

By default we'll enable EBS volume encryption.  For a small penalty in latency our 
data is encrypted at rest and, as a result, more secure.  This covers EC2.7 from 
the AWS Foundational Security Best Practices.

# IAM

Sets IAM acount level settings per recommendations from IAM.7 from the AWS 
Foundational Security Best Practices.

# S3

Sets S3 acount level settings per recommendations from S3.1 from the AWS 
Foundational Security Best Practices.  This blocks public access to S3 buckets.

