#  This is the main.tf for individual instances of the homework
#  assignment. Each instance will have it's own VPC, subnets
#  and database instances. 
#
#  If creating multiple instances in the same AWS region, 
#  give each one a unique env_name below to prevent name conflicts.
#  Otherwise all other settings can remain unchanged.
#
#  WARNING: This requires the name of a pre-existing SSH
#  keypair to be specified below for the keypair_name variable.
#
#  Author: John Clark (jfclarkjr3141@gmail.com)
#
#  Last Updated: 5/13/2021
#

# Specify which AWS region to use
locals {
  myRegion = "us-west-2"
}

# Configure the AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.39"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = local.myRegion
}

# The master database password, to be passed as
# a command line argument at deployment time
variable "db_master_password" {
  description = "The master password for the AuroraDB cluster"
  type        = string
  sensitive   = true
}

# VPC Aurora Module
module "vpc_auroadb_module" {
  source = "../vpc-auroradb-module"

  # Environment name - If using the vpc-module for multiple environments
  # within a single region, the env_name must be unique for each environment
  env_name = "example2"

  # Set the database master password
  db_master_password = var.db_master_password

  # Provide the name of an SSH keypair that
  # exists in the designated AWS region
  keypair_name = "MyKeyPair"

  # Specify the CIDR for the VPC to be created
  vpc_cidr = "192.168.0.0/16"

  # Private subnet definitions. Up to three subnets can be defined.
  priv_subnet_list = ["192.168.1.0/24", "192.168.2.0/24","192.168.3.0/24"]

  # Public subnet definitions. Up to three subnets can be defined.
  public_subnet_list = ["192.168.20.0/24", "192.168.30.0/24","192.168.40.0/24"]

  # List of availability zones in the current region
  az_list = ["${local.myRegion}a","${local.myRegion}b","${local.myRegion}c"]
}