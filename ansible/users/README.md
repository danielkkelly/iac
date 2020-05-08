The playbook.yaml in this directory is an example.  Most of the modules have playbooks
import the tasks in this directory and create their own users.  That's because we I 
don't typically create all of the infrastructure in one shot.  

I use parts of it at any given time and then spin it down when done.  So I might create
a docker and MySQL server but not a syslog server. Rather than have a users playbook 
that failes for some servers it's better to create just what I need.  For work, I create
all of the infrastructure and then all of the accounts at once. 