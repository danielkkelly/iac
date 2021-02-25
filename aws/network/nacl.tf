/*
 * RDS
 */
resource "aws_network_acl" "rds" {
  vpc_id = aws_vpc.vpc.id
  subnet_ids = [aws_subnet.subnet_rds_1.id, aws_subnet.subnet_rds_2.id]
}

locals {
    pri_subnet_cidr_blocks = {
        30 = var.cidr_block_subnet_pri_1, 
        31 = var.cidr_block_subnet_pri_2
    } 
}

resource "aws_network_acl_rule" "rds_pri_ingress" {
    for_each = local.pri_subnet_cidr_blocks
    network_acl_id = aws_network_acl.rds.id
    rule_number    = each.key
    egress         = false
    protocol       = "tcp"
    rule_action    = "allow"
    cidr_block     = each.value
    from_port      = 3306
    to_port        = 3306
}

resource "aws_network_acl_rule" "rds_egress" {
  network_acl_id = aws_network_acl.rds.id
  rule_number    = 35
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}