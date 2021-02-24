# Overview 

The image below shows how authentication works when using IAM + SSH.  IAM will authenticate
a user based on his or her AWS access key and secret.  You'll also need the user's public
key deployed on your VMs.  This gives you two-factor, essentially.

![Alt text](img/proxied-ssh.png?raw=true "Proxied SSH")

# Session Manager vs. Tranditional Bastion

You should use the session manager approach for AWS.  If you decide you want to use a pulbic 
bastion host then you'll need to modify the HCL for the AWS bastion host by uncommenting the 
lines that create the public EIP and modify the network to put the bastion host on a public 
subnet instead of a private subnet. 

See http://sawers.com/blog/aws-session-manager-a-better-way-to-ssh/ for more details.

The above change changes in [AWS](../README.md#ssh-config) are all that are that is required.  
Because we use the bastion host as our jump host in either scenario, the rest of the SSH Config 
specified in [General Setup](../README.md) remains accurate.  However, you could use session 
manager to ssh directly to other hosts if you like as well.  You'll have to modify the IAM 
policy to allow it as we lock it down to VMs with a HostType = bastion.