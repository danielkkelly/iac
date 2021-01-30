[General Setup](../README.md)

# Overview

This module enables security features, such as Security Hub and Config.  The goal 
of this module is to provide an example of how to go about gaining conformance to
specific standards.  

# Security Standards

AWS provies subscriptions to security standards.  When these execute they will 
generate a list of findings, insights, and score your overall security.  In 
addition, failed checks will provide links to steps to remmediate.  Conformance
packs are available for security standards that aren't available by default.  
For example, there are CMMC conformance packs.

# Security Hub and Config

Security Hub provides a consolidated view of security in a given region or for
an organization.  This is your "single pane of glass" that scores and lists
findings and insights.  At the heart of these insights and findings are config
rules that execute to test your configuration against required controls.  These
can are provided with the available standards and conformance packs or could be
custom coded.  If integrations are enabled, Security Hub will pull findings and
insights from those.  For example, if you enable GuardDuty, the AWS SIEM, it 
will share data with Security Hub.

# Continuous Monnitoring

Another benefit of enabling this level of security is that it allows for ongoing
monitoring of resources.  It allows us to attach an SNS resource that notifies
a topic of issues found.

# Implementation

I've run Security Hub with the basic subscriptions at this point and have worked
on remedidation of issues as I find them.  If you draw from thos codebase then
you should be ahead in terms of security and compliance vs. starting from scratch
on your own.  I'm working through CMMC compliance at the office, so ingihts from
that process will eventually be reflected here as well.