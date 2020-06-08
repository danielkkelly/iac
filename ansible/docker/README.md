# Overview

This module sets up a docker server.  This server is configured for log rotation.  We 
use the syslog driver for docker to log through rsyslogd and then configure syslog to 
allow developers in the docker group to view the logs under /var/log/docker.

Logs are configured to rotate and also to optionally forward to a central syslog server
for security and convenience.

# Centralized Logging

The following scripts will implement centralized logging.  The first playbook is generic syslog
remote logging.  The second configures docker to use syslog.

* playbook-syslog.yaml
* playbook-syslog-docker.yaml (in both docker and syslog)

## References 

https://medium.com/better-programming/docker-centralized-logging-with-syslog-97b9c147bd30

# Running a test container

To test try running:

```
docker run --name mynginx1 -p 8080:80 -d nginx
```

You need to be in the docker group to execute the command above.  

After the container is running try a request.  Run it from the bastion server or the 
ALB public endpoint.


```
[ec2-user@ip-10-0-1-10 ~]$ curl docker.dev.internal:8080
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```