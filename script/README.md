# Project Organization

The project is organized into providers, modules, keys, and scripts.  Configuration scripts 
run in parallel to modules but are stored in the "ansible" top level directory.

```
.
├── ansible
│   ├── module1
│   └── module2
├── aws
│   ├── module1
│   └── module2
├── gcp
│   ├── module1
│   └── module2
├── keys
└── script
```

## Ansible

All ansible artifacts are stored under the "ansible" top level directory.  These configuration
files are independent of the cloud platform used to create the underlying infrastructure, 
assuming you keep the same OS for your VMs, etc.

## Providers

AWS and GCP are considered providers and these contain terraform modules.  If a provider's 
module is configured with Ansible then the "ansible" directory must contain a module of the
same name.  Each provider module as a "tf.sh" script that executes terraform with the correct
parameters.  These scripts will get passed the appropriate environment if you use 
buildctl.sh.

## Keys

This includes public keys for the individuals you will set up to access your VMs.

## Script

Contains scripts that support work across various providers and modules.  The most important
script being buildctl.sh, which controls all fo the execution as you build a single module or
defined groups of modules.

# Running Terraform and Ansible

You need to run things in the correct order when you build with terraform and configure
with ansible.  You could do this manually or let buildctrl.sh do it for you.  Here's 
an example of infrastructure and the order of creation / configuration:

1. localhost 
2. iam
3. network
4. ssm
5. bastion

## Manual execution

For each of the modules above you would do the following:

* Initialize terraform if the module has terraform configuration
* Initialize terraform's workspace for the correct environment (e.g. dev, test, prod)
* Execute terraform
* Wait for the infrastructure to become avalable before configuring it
* Run the appropriate ansible playbook(s)

## Using buildctrl.sh

You could also use buildctl.sh to run terraform modules and ansible playbooks in the 
correct order and in tandem.  If you decide to use it then set IAC_HOME to wherever 
you put the top level directory of this project.  Then execute the command:

### Configuration

In our example above we have five modules to execute.  buildctl.sh simplifies the entire
process by allowing you to specify your configuration in JSON.  For example:

```
{
    "modules": [
        {
            "module": "base",
            "action": "apply",
            "target": ["localhost", "network", "iam", "ssm", "bastion"],
            "terraform": true,
            "ansible": true,
            "playbook": "playbook.yaml"
        },
        {
            "module": "base",
            "action": "destroy",
            "target": ["bastion", "ssm", "iam", "network"],
            "terraform": true,
            "ansible": false
        }
    ],
    "resources" : [
        {
            "target": "bastion",
            "type": "vm"   
        }
    ]
}
```

Now, instead of executing each module independently, you can execute them as a group.  For 
each group we define the module name.  In the example above we call it "base".  Thi is a 
derived module.  buildctl.sh will allow you to use these derived modules or to execute any
individual module directly (e.g. base, bastion, ssm, iam, network all work as modules).

We also define an action.  We have two actions, "apply" and "destroy".  We follow the terraform
pattern here.  Apply will create or update infrastructure and destory will remove it.

Lastly, we define what is exectuted on apply and destroy.  These properties are "terraform" 
and "ansible".  Ansible is never necessary on destroy.  Either terraform or ansible or both
could be used on apply to support various scenarios.

### Execution

```
./buildctl.sh --provider aws --module base --terraform --ansible --action apply    # build
./buildctl.sh --provider aws --module base --terraform --action destroy  # tear down
```

This executes the terraform and ansible modules above in the proper order.  You 
could also use the command below to execute a single module, in this case the 
bastion server.

```
./buildctl.sh --provider aws --module bastion --action apply --terraform --ansible
```

Use the --terraform and --ansible options to toggle those on (or omit for off).


## Environments

Use the --env option to execute across multiple environments.  For example:

```
./buildctl.sh --provider aws --module base --terraform --ansible --action apply --env dev
```

This will pass "dev" to ansible scripts to get the correct hosts as well as to 
terraform to get the correct configuration.

## Benefits

The builctl.sh script uses metadata to define execution.  This is a buildctl.json 
file that defines an array of JSON objects, describing how the module and its targets
are created.  This is a signifcant time saver.

buildctl.sh will also handle simple aspects of execution.  For example:

* Automate manual effort (multiple module execution, terraform imitilization, etc)
* Supports a very modular environment by handling dependencies at a high level
* Manage terraform workspaces automatically
* Wait for VMs to become available prior to executing Ansible

## Possible Issues

Because each module requires its own terraform initialization, all of the terraform 
configuration isn't in one place.  More time and production use across multiple
environments will hammer out the ideal use and correct functionality.  That said,
the modular structure allows you to delegate what you want to buildctl.sh.  This 
could be one module or ten.

# tfctl.sh

This script supports actions that allow you to manage terraform.  For example, 
migrating from the default workspace to another workspace. 