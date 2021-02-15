# WAF

We add a web application firewall that inspects traffic to and from our load balancer
and applies actions based on the reulsts of inspection.  Our goal is to protect against
common attacks on web-based applications, inclusive of the OWASP top ten vulnerabilities.

We utilized managed rule groups to accomplish this tasks.  These are rule groups that
are maintained by experts and updated with the latest rules independent of our specific 
implementation.  See var.managed_rules[] for details.

https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-list.html