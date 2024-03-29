provider "aws" {
  region  = var.region
  profile = var.env
}

data "aws_vpc" "vpc" {
  tags = {
    Type = "platform-vpc"
  }
}

data "aws_subnet_ids" "subnet_ids" {
  vpc_id = data.aws_vpc.vpc.id
  tags = {
    Kubernetes = 1
    Type       = "private"
  }
}

data "aws_subnet" "subnet_id" {
  for_each = data.aws_subnet_ids.subnet_ids.ids
  id       = each.value
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_cluster_version
  subnets         = [for s in data.aws_subnet.subnet_id : s.id]

  # Creates the OIDC provider
  enable_irsa = true

  # We use the AWS command line to update kubeconfig based on cluster name
  write_kubeconfig = false

  tags = {
    Environment = var.env
  }

  vpc_id = data.aws_vpc.vpc.id

  fargate_profiles = {
    platform = {
      selectors = [
        {
          namespace = "kube-system"
        },
        {
          namespace = "default"
        },
        {
          namespace = "cert-manager"
        }
      ]

      tags = {
        Environment = var.env
      }
    }
  }

  /* Uncomment if you want managed node groups (EC2 instances managed by AWS)

  node_groups_defaults = {
    ami_type  = "AL2_x86_64"
    disk_size = 50
  }

  node_groups = {
    node-group-1 = {
      desired_capacity = 1
      max_capacity     = 3
      min_capacity     = 1

      instance_type = "t2.medium"
      k8s_labels = {
        Environment = var.env
      }
    }
  }
  */
}

resource "kubernetes_service_account" "lbc_service_account" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = "${aws_iam_role.lbc_iam_role.arn}"
    }
  }
}

/* 
 * Fargate Logging
 */
module "cloudwatch_log_group" {
  source = "../cloudwatch-log-group"
  region = var.region
  env    = var.env
  name   = "eks"
}

resource "kubernetes_namespace" "aws_observability" {
  metadata {
    annotations = {
      name = "aws-observability"
    }
    labels = {
      aws-observability = "enabled"
    }
    name = "aws-observability"
  }
}

resource "kubernetes_config_map" "aws_logging_config_map" {
  metadata {
    name      = "aws-logging"
    namespace = "aws-observability"
  }

  data = {
    "output.conf" = templatefile("${path.module}/logging/output.conf.tpl",
      {
        region = var.region
        env    = var.env
      }
    )
    "parsers.conf" = file("${path.module}/logging/parsers.conf")
    "filters.conf" = file("${path.module}/logging/filters.conf")
  }
}