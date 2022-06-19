
# Overview

SES allows you to send email via SMTP.  It works on encrypted ports, 465, or 587.  
The service is useful where you'd like to have an SMTP server to which you can 
route messages from applications.

At a high level you need to set up a domain (set TF_VAR_domain), then take the 
DKIM records that are generated (use the console to copy them) and create DNS 
records by copying and pasting them as needed.  

If you use Route53 for DNS then you could probably automate the entire process.  I 
currently do not so that part is manual.

# Testing

Test is straight-forward.  You need to base64 encode the access key ID and the 
SMTP access key secret.  The SMTP key secret is generated by terraform and you 
can find it in the terraform state.  A better approch would be to encrypt it with
GPG and output it to the console but that is not implemented here (yet).

## Encode the access key and SMTP password

Find the password in the terraform state (i.e. vi aws/ses/terraform.tfstate.d/${env}/terraform.tfstate).

```
echo -n "<access_key>" | openssl enc -base64
echo -n "<ses_smtp_password_v4>" | openssl enc -base64
```

## Use the script below to verify

Create a script called "smtp.txt" for test purposes.  You'll need to replace the 
domain, sender, receiver.

```
EHLO <domain>
AUTH LOGIN
<base64 access key from above>
<base64 ses_smtp_password_v4 from above>
MAIL FROM: sender@domain.com
RCPT TO: receiver@domain.com
DATA
From: Sender Name <sender@domain.com>
To: receiver@domain.com
Subject: Amazon SES SMTP Test

This message was sent using the Amazon SES SMTP interface.
.
QUIT
```

### Run the script as shown below

Run the script as shown below.  Make sure to modify for your AWS region.

```
openssl s_client -crlf -quiet -starttls smtp -connect email-smtp.us-east-2.amazonaws.com:587 < smtp.txt
```

# Resources

https://docs.aws.amazon.com/ses/latest/dg/send-email-smtp-client-command-line.html
https://docs.aws.amazon.com/ses/latest/dg/creating-identities.html#just-verify-domain-proc