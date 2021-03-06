# Overview

![Alt text](img/k8-rds.png?raw=true "K8 with RDS")

# Setup

1. Build the cluster using terraform
2. Install kubectl (https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html)
3. run "aws eks --region us-east-1 update-kubeconfig --name platform-eks"

# Test

## Create a service

Create a file called test.yaml with the following content:

```
apiVersion: v1
kind: Namespace
metadata:
  name: test
---
apiVersion: v1
kind: Service
metadata:
  name: my-service
  namespace: test
  labels:
    app: my-app
spec:
  selector:
    app: my-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-deployment
  namespace: test
  labels:
    app: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
```

Then create everything using:

```
kubectl apply -f test.yaml 
```

## Connect

```
kubectl port-forward service/my-service 8080:80  -n default
```

## Remove 

```
kubectl delete namespaces default
```

# CoreDNS

KS assumes that the Kubernetes CoreDNS service runs on EC2, which is not the case with a
fargate-only cluster.  Terraform already creates the appropriate selector.  However, you
need to run the command below to patch the CoreDNS deployment.

```
kubectl patch deployment coredns \
    -n kube-system \
    --type json \
    -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]'
```


# Metrics Server

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Dashboard

https://docs.aws.amazon.com/eks/latest/userguide/dashboard-tutorial.html
