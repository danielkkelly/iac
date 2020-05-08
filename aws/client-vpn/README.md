# Overview

A client VPN could be useful for a number of use cases.  If you don't want to jump through
a bastion server and use SSH port forwarding for various services this is a good solution.
Also, if you have services that make port forwarding difficult, this also helps.  

Kafka is a good use case.  Because you connect to one broker in a cluster, and that broker
tells the client which broker (perhaps not itself) is handling a topic, your Kafka client 
coudl need to hit another broker after the initial connection is made.  

* Connect to broker.dev.internal, request topic xyz
* Discover that topic xyz is on broker2.dev.internal
* Port forwarding issues ensue

You could get around that using port forwarding by setting up broker to resolve to 127.0.0.1
and broker 2 to resolve to 127.0.0.2.  Then when Kafka gives you broker2.dev.internal you
just need to make sure it's forwarded appropriately.  But this isn't recommended by AWS.  It's
not nearly as simple as the client VPN.

# Imports to the AWS Certificate Manager

This is all you need, contrary to the AWS documentation.

```
aws acm import-certificate --certificate fileb://server.crt \
                           --private-key fileb://server.key \
                           --certificate-chain fileb://ca.crt
```

# Revoking a client certificate

```
./easyrsa revoke client1.dev.internal
./easyrsa gen-crl

aws ec2 import-client-vpn-client-certificate-revocation-list \
  --certificate-revocation-list fileb://easy-rsa/easyrsa3/pki/crl.pem \
  --client-vpn-endpoint-id cvpn-endpoint-whatever.prod.clientvpn.us-east-2.amazonaws.com \
  --region us-west-2
```