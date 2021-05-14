#
#  vpc-auroradb-module
#
#  A Terraform module that can be used to create multiple
#  AWS environments with the following:
#   - A VPC
#   - Up to 3 private subnets split across 3 availability zones
#   - Up to 3 public subnets split across 3 availability zones
#   - An AuroraDB cluster spanning the private subnets
#   - An EC2 Linux instance in a public subnet that can
#     be used to SSH tunnel to the Aurora database
#
#  Author: John Clark (jfclarkjr3141@gmail.com)
#
#  Last Updated: 5/13/2021
#

# Create a VPC
resource "aws_vpc" "main-vpc" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-${var.env_name}"
  }
}

# Create the private subnets
resource "aws_subnet" "private_subnet" {
  count = length(var.priv_subnet_list)
  vpc_id     = aws_vpc.main-vpc.id
  cidr_block = var.priv_subnet_list[count.index]
  availability_zone = var.az_list[count.index]

  tags = {
    Name = "Private subnet ${count.index} - ${var.env_name}"
  }
}

# Create the public subnets
resource "aws_subnet" "public_subnet" {
  count = length(var.public_subnet_list)
  vpc_id     = aws_vpc.main-vpc.id
  cidr_block = var.public_subnet_list[count.index]
  availability_zone = var.az_list[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "Public subnet ${count.index} - ${var.env_name}"
  }
}

# Create the DB Subnet Group
resource "aws_db_subnet_group" "subnet-group-auroradb" {
  name       = "subnet-group-${var.env_name}"
  description = "Terraform RDS subnet group"
  subnet_ids = aws_subnet.private_subnet[*].id

  tags = {
    Name = "Database Subnet Group - ${var.env_name}"
  }
}

# Create an internet gateway for access to/from the public subnets
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main-vpc.id

  tags = {
    Name = "Internet Gateway - ${var.env_name}"
  }
}

# Create a route table
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Public Internet Route Table - ${var.env_name}"
  }
}

# Associate the route table with the public subnets
resource "aws_route_table_association" "a" {
  count = length(var.public_subnet_list)
  subnet_id      = "${aws_subnet.public_subnet[count.index].id}"
  route_table_id = aws_route_table.rt.id
}

# Create a security group for inbound SSH
resource "aws_security_group" "allow_ssh" {
  name        = "secGroup-${var.env_name}"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main-vpc.id

  ingress {
    description      = "SSH Inbound"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Allow inbound SSH to public subnet - ${var.env_name}"
  }
}

# Create a security group for DB access
resource "aws_security_group" "allow_db_access" {
  name        = "DbSecGroup-${var.env_name}"
  description = "Allow inbound traffic to DB"
  vpc_id      = aws_vpc.main-vpc.id

  ingress {
    description      = "Inbound DB"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = concat(var.priv_subnet_list[*], var.public_subnet_list[*])
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Allow DB connections from private subnets - ${var.env_name}"
  }
}

# Create 
resource "aws_network_interface" "ec2-net" {
  subnet_id   = aws_subnet.public_subnet[0].id
  security_groups = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "Network interface for jump host - ${var.env_name}"
  }
}

# Look up the latest Amazon Linux 2 image 
# in the cuurent region
data "aws_ami" "amazon-linux2" {
 most_recent = true
 owners = ["amazon"]

 filter {
   name   = "name"
   values = ["amzn2-ami-hvm-*-gp2"]
 }
}

# Create the jump host using the image found
resource "aws_instance" "ec2-linux-vm" {
  ami           = "${data.aws_ami.amazon-linux2.id}"
  instance_type = "t2.micro"
  key_name = "${var.keypair_name}"

  network_interface {
    network_interface_id = aws_network_interface.ec2-net.id
    device_index         = 0
  }

  tags = {
    Name = "Linux jump host - ${var.env_name}"
  }
}

# Aurora cluster
resource "aws_rds_cluster" "aur_cluster" {
  cluster_identifier      = "aurora-cluster-${var.env_name}"
  engine                  = "aurora-mysql"
  engine_version          = "5.7.mysql_aurora.2.03.2"
  database_name           = "mydb"
  master_username         = "admin"
  master_password         = "${var.db_master_password}"
  backup_retention_period = 5
  preferred_backup_window = "08:00-10:00"
  db_subnet_group_name = aws_db_subnet_group.subnet-group-auroradb.name
  vpc_security_group_ids = [aws_security_group.allow_db_access.id]
  skip_final_snapshot = true
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  count              = 2
  identifier         = "aur-clust-inst-${var.env_name}-${count.index}"
  cluster_identifier = aws_rds_cluster.aur_cluster.id
  instance_class     = "db.t2.small"
  engine             = aws_rds_cluster.aur_cluster.engine
  engine_version     = aws_rds_cluster.aur_cluster.engine_version
  publicly_accessible = false
  db_subnet_group_name = aws_db_subnet_group.subnet-group-auroradb.name
}