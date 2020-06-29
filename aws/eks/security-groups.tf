data "aws_security_group" "bastion_sg" {
  tags = {
    Name = "platform-bastion"
  }
}

resource "aws_security_group" "eks_worker_sg" {
  name_prefix = "platform-eks-worker"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    
    security_groups = [data.aws_security_group.bastion_sg.id]
  }
}