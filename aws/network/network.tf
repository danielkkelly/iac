/* 
 * Creates a VPC with six subnets.  Two public subnets with access to an Internet gateway,
 * two private subnets for apps, and two for RDS.  App subnets have access to a NAT
 * gateway.
 */
provider "aws" {
  region  = var.region
  profile = var.env
}

