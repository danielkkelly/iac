variable "region" {}
variable "env" {}
variable "key_pair_name" {}

/*
 * This is the Elastic Load Balancing Account ID for the region (us-east-2).  Update
 * it for your region
 */
variable "alb_account" {
    default = "033677994240"
}