# Overview

![Alt text](img/k8-rds.png?raw=true "K8 with RDS")

# Prerequisites

You must have the following installed:

* kubctl
* Helm


# Setup

1. Set the alb_target_port in variables.tf - please ensure it is set to 80 for the example below
2. Build the cluster using terraform
3. Install kubectl (https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html)
4. run "aws eks --region us-east-1 update-kubeconfig --name platform-eks" 
5. Patch Core DNS
6. Install the AWS Load Balancer Controller
7. Install your application to test load balancing 

## OIDC

The OIDC proider is automatically created through terraform.  This allows us to run the 
AWS Load Balancer Controller.

## CoreDNS

KS assumes that the Kubernetes CoreDNS service runs on EC2, which is not the case with a
fargate-only cluster.  Terraform already creates the appropriate selector.  However, you
need to run the command below to patch the CoreDNS deployment.

```
kubectl patch deployment coredns \
    -n kube-system \
    --type json \
    -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]'
```
## Load Balancing

Load balancing configuration will be managed outside of Kubernetes using Terraform.  This 
means that we'll use the AWS Load Balancer Controller to attach a Kubernetes Ingress to 
an existing Target Group on the ALB.

### Install the AWS Load Balancer Controller

See https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html for 
more information.

First time through add the AWS helm repo.

```
helm repo add eks https://aws.github.io/eks-charts

```

Each time do the following.  Note that you will need to update the region and VPC ID below
prior to running the helm upgrade command.

```
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"

helm repo update

helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller \
  --set clusterName=platform-eks \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=`tfctl.sh --provider aws --module network --action output --qualifier region --env test` \
  --set vpcId=`tfctl.sh --provider aws --module network --action output --qualifier vpc_id --env test` \
  -n kube-system
```

### View the logs

```
kubectl logs -n kube-system deployment.apps/aws-load-balancer-controller
```

# Test using nginx

Make sure to set the alb_target_port to 80 in variables.tf.

## Create a service

Run the following commands to create an nginx service and attach the load balancer's
target group to the service.  You must replace the ARN in 02-tgb with the target 
group's ARN.

```
kubectl apply -f test/01-nginx.yaml 
kubectl apply -f test/02-tgb.yaml 
```

## Connect

```
kubectl port-forward service/my-service 80:80  -n default
```

## Remove 

```
kubectl delete namespaces default
```

# Logging

Logging follows https://aws.amazon.com/blogs/containers/fluent-bit-for-amazon-eks-on-aws-fargate-is-here/.
Formatting will differ from the example to reduce the noise and offload more of the log formatting to 
the application itself.

Logs are sent to CloudWatch.  Log groups are created separately to allow for setting of retention period.

## Tailing Logs

```
aws logs tail platform --follow --profile test
```

## Getting Log Events by Start and / or End Time

See https://awscli.amazonaws.com/v2/documentation/api/latest/reference/logs/get-log-events.html.
Simple example below.

```
aws logs get-log-events --log-group-name platform \
                        --start-time `date -d 2021-08-25T14:50:00Z +%s`000 \
                        --end-time   `date -d 2021-08-26T14:50:00Z +%s`000 \
                        --profile test
```

# Getting a Shell 

This could need some dialing in but given one container the following works well.  Use the name of the pod
after --tty.

```
kubectl exec --stdin --tty platform-deployment-68499488d8-flgzp -- /bin/bash
```

# Metrics Server

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Dashboard

https://docs.aws.amazon.com/eks/latest/userguide/dashboard-tutorial.html

# SSH Port Forwarding with Pods

This is possible, if desired.  Make sure the bastion host has access to the pods.  You 
could allow through EKS primary security group.  For an example of this, see how the 
load balancer is set up for access to pods in alb.tf.

TODO: how to get targets for a target group?
 
Once you have access set up for the ports you want:

```
ssh test-bastion -L 9991:10.2.2.156:9990
```

In this example we access the Wildfly managment console from localhost:9991.  
