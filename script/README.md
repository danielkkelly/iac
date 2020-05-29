# Running Terraform and Ansible

You need to run things in the correct order when you build with terraform and configure
with ansible.  You could do this manually or let buildctrl.sh do it for you.  Here's 
an example of infrastructure and the order of creation / configuration:

1. localhost 
2. iam
3. network
4. ssm
5. bastion
6. docker
7. syslog
8. rds-mysql
9. configure syslog clients

After creating these you could run the other scripts in whatever order you like.

# Using terraform modules

The order of execution is maintained by terraform if you define that.  A good example
is our list of GCP modules.  These use one terraform driver to run the GCP modules in
the correct order.  This is traditional for terraform and a good way to do it. 

# Using buildctrl.sh

You could also use buildctl.sh to run terraform modules and ansible playbooks in the 
correct order and in tandem.  If you decide to use it then set IAC_HOME to wherever 
you put the top level directory of this project.  Then execute the command:

```
./buildctl.sh --provider aws --module base --terraform --ansible --action apply    # build
./buildctl.sh --provider aws --module base --terraform --action destroy  # tear down
```

This executes the terraform and ansible modules above in the proper order.  You 
could also use the command below to execute a single module, in this case the 
bastion server.

```
./buildctl.sh --module bastion --action apply --terraform --ansible
```

Use the --terraform and --ansible options to toggle those on (or omit for off).

Use the --env option to execute across multiple environments.

## Benefits

The builctl.sh script uses metadata to define execution.  This is a buildctl.json 
file that defines an array of JSON objects, describing how the module and its targets
are created.  Review that for all of the available modules and their configurations.  
It currently includes several modules for AWS builds that allow you to build the 
infrastructure modularly and incrementally.

## Issues

Because each module requires its own terraform initialization, all of the terraform 
configuration isn't in one place.  It's not 100% clear to me without more experience
whether or not this is the best approach.  I've used it for AWS but not GCP to gain
experience using two different patterns and hope to decide on the best approach or 
the factors that would drive using one or the other.