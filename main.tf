# Define provider
provider "aws" {
  region = "your-preferred-region"
}

# Create a VPC
resource "aws_vpc" "mongodb_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create Subnet
resource "aws_subnet" "mongodb_subnet" {
  vpc_id            = aws_vpc.mongodb_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "your-preferred-az"
}

# Create Security Group
resource "aws_security_group" "mongodb_sg" {
  vpc_id = aws_vpc.mongodb_vpc.id

  # Inbound rules
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rules (add more if needed)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# MongoDB Cluster (Example using MongoDB Atlas)
module "mongodb_cluster" {
  source = "terraform-aws-modules/eks/aws"

  # MongoDB Configuration
  cluster_name        = "my-mongodb-cluster"
  node_instance_type  = "t3.medium"
  node_instance_count = 3
  subnet_ids          = [aws_subnet.mongodb_subnet.id]
  security_group_ids  = [aws_security_group.mongodb_sg.id]

  # MongoDB Atlas Configuration
  mongodb_atlas_username = "your-mongodb-atlas-username"
  mongodb_atlas_password = "your-mongodb-atlas-password"
  mongodb_atlas_project_id = "your-mongodb-atlas-project-id"
}
