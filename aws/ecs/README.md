Set TF_VAR_ecr to your container repo.  

```
# IAC ECR
export TF_VAR_ecr=<aws account ID>.dkr.ecr.<region>.amazonaws.com

# IAC ECS Docker container image
export TF_VAR_app_image="$TF_VAR_ecr/my-app:latest"
```