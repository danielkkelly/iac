# Overview

Sets up CloudTrail and forwards CloudTrail logs to CloudWatch.  Adds CloudWatch
metrics and alarms requires for CIS AWS Foundations benchmark.  Sets up SNS topic
to receive alarms.

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