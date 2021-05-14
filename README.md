# Homework Assignment Completed by John Clark

## What's in this code
This Terraform code consists of a module that can be used to spin up multiple AWS environments with the following:
   - A VPC
   - Up to 3 private subnets split across 3 availability zones
   - Up to 3 public subnets split across 3 availability zones
   - An AuroraDB cluster spanning the private subnets
   - An EC2 Linux instance in a public subnet that can
     be used to SSH tunnel to the Aurora database

### The following deployments are supported:
 - Multiple instances each in a unique AWS region
 - Multiple instances within the same AWS region
   - If spinning up more than one instance in the same region, specify a unique `env_name` value for each


### Prerequisites:
 - A pre-existing SSH keypair defined in the AWS region that is specified in the `keypair_name` variable in the `main.tf` for each instance.

### What's in this repo:
1. The `vpc-auroradb-module`
2. Three example instances. Two are in the `us-west-2` region, and one is in the `us-east-2` region.

### How to use the examples
To use one of the examples:
1. cd into the example directory
2. Modify the `main.tf` as desired
3. Run the following commands:
```bash
terraform init
terraform plan
terraform apply
```