# Overview 

![Alt text](img/proxied-ssh.png?raw=true "Proxied SSH")

You should use the system manager approach for AWS.  If you decide you want to use a pulbic 
bastion host then you'll need to modify the HCL for the AWS bastion host by uncommenting the 
lines that create the public EIP and modify the network to put the bastion host on a public 
subnet instead of a private subnet. 

See http://sawers.com/blog/aws-session-manager-a-better-way-to-ssh/ for more details.

The above change should be all that is required.  Because we use the bastion host as 
our jump host in either scenario, the rest of the SSH Config specified in [General Setup](../README.md)
remains accurate.  However, you could use session manager to go directly to those hosts
if you like as well.