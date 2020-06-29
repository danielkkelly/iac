provider "aws" {
  region  = var.region
  profile = var.env
}

data "aws_vpc" "vpc" {
  tags = {
    Type = "platform-vpc"
  }
}

module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  cluster_name = var.cluster_name
  subnets      = [var.cidr_block_subnet_pri_1, var.cidr_block_subnet_pri_2]

  tags = {
    Environment = var.env
  }

  vpc_id = data.aws_vpc.vpc.id

  worker_groups = [
    {
      name                          = "worker-group-1"
      instance_type                 = "t2.medium"
      asg_desired_capacity          = 2
      additional_security_group_ids = [aws_security_group.eks_worker_sg.id]
    }
  ]
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}