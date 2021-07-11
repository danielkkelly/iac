# TLS

AWS has limits on how many certificates you can deploy in a given year.  You could 
run this each time you build your environment but would eventually hit your quota 
and uploading the generated cert would fail.  One option is to work with AWS to increase 
your quota and add alb-tls to buildctl.json so it runs with each apply / destroy of your 
environment.  The other option is to run alb-tls yearly.  By default we use the later 
in our default configuration.

If you set up the ALB then you will need to run alb-tls first, like below.  

```
buildctl.sh --provider aws --module alb-tls --action apply --terraform --ansible --auto-approve --env dev
```

If you have your quota increased you could also add alb-tls to buildctl.json to run it all 
the time.


# WAF

We add a web application firewall that inspects traffic to and from our load balancer
and applies actions based on the reulsts of inspection.  Our goal is to protect against
common attacks on web-based applications, inclusive of the OWASP top ten vulnerabilities.

We utilized managed rule groups to accomplish this tasks.  These are rule groups that
are maintained by experts and updated with the latest rules independent of our specific 
implementation.  See var.managed_rules[] for details.

https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-list.html