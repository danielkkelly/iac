variable "region" {}
variable "env" {}
variable "replication_region" {}

/*
 * This is the Elastic Load Balancing Account ID for the regions us-east-[1,2].  Update
 * it for your region
 */
variable "alb_account" {
  default = {
    us-east-1 = "127311923021"
    us-east-2 = "033677994240"
  }
}

variable "alb_deletion_protection" {
  default = false
}

variable "cidr_blocks_ingress" {
  default = ["0.0.0.0/0"]
}

variable "egress_ports" {
  type = list
  default = [80, 8080, 443, 8443]
}

# Variables for app subnets, to which we'll allow egress
variable "cidr_block_subnet_pri_1" {}
variable "cidr_block_subnet_pri_2" {}

# To silence TF warnings
variable "key_pair_name" {}
variable "cidr_block_vpc" {}
variable "cidr_block_subnet_pub_1" {}
variable "cidr_block_subnet_pub_2" {}
variable "cidr_block_subnet_rds_1" {}
variable "cidr_block_subnet_rds_2" {}
variable "cidr_block_subnet_vpn_1" {}

# Web application firewall managed rules
variable "managed_rules" {
  type = list(object({
    name            = string
    priority        = number
    override_action = string
    excluded_rules  = list(string)
  }))
  description = "List of Managed WAF rules."
  default = [
    {
      name            = "AWSManagedRulesCommonRuleSet",
      priority        = 10
      override_action = "none"
      excluded_rules  = []
    },
    {
      name            = "AWSManagedRulesAmazonIpReputationList",
      priority        = 20
      override_action = "none"
      excluded_rules  = []
    },
    {
      name            = "AWSManagedRulesKnownBadInputsRuleSet",
      priority        = 30
      override_action = "none"
      excluded_rules  = []
    },
    {
      name            = "AWSManagedRulesSQLiRuleSet",
      priority        = 40
      override_action = "none"
      excluded_rules  = []
    },
    {
      name            = "AWSManagedRulesLinuxRuleSet",
      priority        = 50
      override_action = "none"
      excluded_rules  = []
    },
    {
      name            = "AWSManagedRulesUnixRuleSet",
      priority        = 60
      override_action = "none"
      excluded_rules  = []
    }
  ]
}