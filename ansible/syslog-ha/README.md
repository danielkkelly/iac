# Overview

The goal of this module is to provide an HA solution for what is currently scoped to 
the syslog service.  The service is configured as active / passive using a VIP that
floats from VM to VM based on availability.  Availability is determined via keepalived.

While this solution is specific to syslog currently, it's possible that it could be 
abstracted to support other active / passive scenarios.

# HA Design

Our current design uses keepalived and a secondary IP / VIP on the VM that moves when 
the master service fails for any reason.  But there are multiple ways to handle this 
scenario and this section discusses them and explains the reason for the current 
implementation.  It is possible that this isn't the best implementation for all 
situations.

## Keepalived

Keepalived is a daemon that has a protocol for electing a master VM from among a set
of VMs.  It uses a health-check, which is a custom script that checks for uptime and
a notify script that orchestrates a cutover, in our cast, when a VM is elected the 
master.

The health-check in this case checks the status of the syslog service.  If the service
is down then keepalived will elect a new master.  When a VM is elected master the VM
will execute its notify script, which in turn calls a script for self assigning the VIP
via the AWS command line and then restarts network services so the assignment takes
effect.

This approach is easily configurable and allows monitoring in a granular fashion - i.e.
we detect the service coming down on the master and force an election of a new master.
It also allows us to handle the scenario at the IP address vs. host name.  In some cases
this is preferable (e.g. NAT configured by another group by IP).

The downside is that the VIP exists on a specific subnet.  This means that the servers
are not distributed across zones and do not have the same physical separation as two 
hosts configured on separate subnets in separate zones.

## Route53

Another approach considered was Route53.  This approach uses DNS to detect when a host 
is unavailble.  Not having implemented this approach, it's not clear how this check is 
performed.  Ideally it would detect when the syslog service isn't availble.  If others
rely on IP address then this isn't an effective approach, however.

The appeal of research in this direction is that this approach is supported natively by
AWS and could be easily configured with terraform.  It also allows the active and passive
VMs to occupy different subnets / geographies for additional ressiliency.

It's possible that I'll experiment with this approach in the future.  For now, the 
keepalived approach works well for my particular circumstances.

# HA Playbooks

This section won't rehash what you can read in the playbook itself but instead cover 
concepts.

The playbook makes use of commands executed on localhost.  Specifically, we use tfctl.sh
to obtain information about hosts, region, roles, etc.  This information is then passed
to included playbooks to configure various parts of the solution (aws config, keepalived).

# Syslog Configuration

At the time of this writing this isn't 100% complete.  The design goal is to use playbooks 
under ../syslog and run these for each HA host.  This allows for reuse in a single or HA
VM scenario if desired.

# Future Improvements

In the future we could get more generic about HA vs. tie our HA configuration to redundant
syslog services.  It's straight forward to start to put together playbooks that are more
modular.  That said, given that lack of need for redundant VMs elsewhere it's better to 
keep things simple here and build in additional complexity just in time when it's time.