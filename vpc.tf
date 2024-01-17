# Configure AWS provider
provider "aws" {
  region = "us-east-1"
}

# Create VPC
resource "aws_vpc" "mongo_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "mongo-vpc"
  }
}

# Create Internet Gateway and attach it to VPC
resource "aws_internet_gateway" "mongo_igw" {
  vpc_id = aws_vpc.mongo_vpc.id

  tags = {
    Name = "mongo-igw"
  }
}

# Create public subnet
resource "aws_subnet" "mongo_public_subnet" {
  vpc_id            = aws_vpc.mongo_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "mongo-public-subnet"
  }
}

# Create routing table and add public route
resource "aws_route_table" "mongo_public_rt" {
  vpc_id = aws_vpc.mongo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mongo_igw.id
  }

  tags = {
    Name = "mongo-public-rt"
  }
}

# Associate public subnet with routing table
resource "aws_route_table_association" "mongo_public_assoc" {
  subnet_id      = aws_subnet.mongo_public_subnet.id
  route_table_id = aws_route_table.mongo_public_rt.id
}

# Create security group for MongoDB
resource "aws_security_group" "mongo_sg" {
  name        = "mongo-sg"
  description = "Allow MongoDB traffic"
  vpc_id      = aws_vpc.mongo_vpc.id

  ingress {
    description = "Allow MongoDB traffic"
    from_port   = 27017
    to_port     = 27017 
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mongo-sg"
  }
}

# Create MongoDB replica set 
resource "aws_instance" "mongo" {
  count         = 3 # create 3 instances
  ami           = "ami-0742b4e673072066f" # MongoDB AMI
  instance_type = "t2.micro"
  key_name      = "mongo-key" # SSH key name

  # Attach public subnet and security group
  subnet_id              = aws_subnet.mongo_public_subnet.id
  vpc_security_group_ids = [aws_security_group.mongo_sg.id]

  tags = {
    Name = "mongo-${count.index + 1}"
    Type = "DB"
  }
}
