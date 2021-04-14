# Overview

Sets up CloudTrail and forwards CloudTrail logs to CloudWatch.  Adds CloudWatch
metrics and alarms requires for CIS AWS Foundations benchmark.  Sets up SNS topic
to receive alarms.  Note: you must have a subscription on the Cloudtrail Breach 
topic before you are compliant with the CIS 3.x log metric requirements.

# E-mail Subscriptions

Terraform can't do e-mail subscriptions because the workflow requires that the 
owner of the address confirms the subscription.  This is a manual step that 
you will need to complete.  Note: old subscriptions could stick around but aren't
associated with the current topic created with Terraform.  So make sure that you
have a new e-mail subscription created for the current topic if you go this route.
You will need to do this each time you build your infrastructure.


# SNS Subscriptions

If you update the sms_enabled variable in the settings module to allow SMS and same 
for this module then it will create an SMS subscription for you.  Note: SMS could 
require some work given carrier requirements. You need an environment variable with 
your number, like below.

```
# IAC SNS
export TF_VAR_sms_number="+19998887777"
```

Email isn't automatic with Terraform.  At the time of this writing the documentation
states partial support for SNS protocol = email but when executed Terraform didn't
accept that value.  This is easy enough to create manually.  Add the subscription
using the console and you're all set.