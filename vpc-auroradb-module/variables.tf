#
#  variables.tf used by the vpc-auroradb-module
#
#  Author: John Clark (jfclarkjr3141@gmail.com)
#
#  Last Updated: 5/13/2021
#

# Specify a unique environment name. This will be added
# as a suffix to tags for devices created in the environment.
variable "env_name" {
  description = "The unique environment name"
  type        = string
}

# User-defined CIDR for the VPC
variable "vpc_cidr" {
  description = "The CIDR for the VPC"
  type        = string
}

# An SSH keypair used by the EC2 jump host
variable "keypair_name" {
  description = "The name of an SSH keypair defined in AWS"
  type        = string
}

# User-defined private subnet CIDR list
variable "priv_subnet_list" {
  description = "List of CIDRs"
  type        = list(string)
  default     = []
}

# User-defined public subnet CIDR list
variable "public_subnet_list" {
  description = "List of CIDRs"
  type        = list(string)
  default     = []
}

# A list of availibitly zones in the given region
variable "az_list" {
  description = "List of availability zones"
  type        = list(string)
  default     = []
}

# The master database password, to be passed as 
# a command line argument at deployment time
variable "db_master_password" {
  description = "The master password for the AuroraDB cluster"
  type        = string
  sensitive   = true
}

