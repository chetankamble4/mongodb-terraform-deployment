# Configure AWS provider
provider "aws" {
  region = "us-east-1"
}

# Data source to get latest Amazon Linux AMI
data "aws_ami" "amzlinux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Create VPC
resource "aws_vpc" "mongo_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "mongodb-vpc"
  }
}

# Create Internet Gateway and attach to VPC
resource "aws_internet_gateway" "mongo_igw" {
  vpc_id = aws_vpc.mongo_vpc.id

  tags = {
    Name = "mongodb-igw" 
  }
}

# Create public subnet
resource "aws_subnet" "mongo_public_subnet" {
  vpc_id            = aws_vpc.mongo_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "mongodb-public-subnet"
  }
}

# Create route table and add public route
resource "aws_route_table" "mongo_public_rt" {
  vpc_id = aws_vpc.mongo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mongo_igw.id
  }
}

# Associate route table to public subnet
resource "aws_route_table_association" "mongo_public_assoc" {
  subnet_id      = aws_subnet.mongo_public_subnet.id
  route_table_id = aws_route_table.mongo_public_rt.id
}

# Create security group for MongoDB
resource "aws_security_group" "mongo_sg" {
  name        = "mongodb-sg"
  description = "Allow MongoDB traffic"
  vpc_id      = aws_vpc.mongo_vpc.id

  ingress {
    description = "Allow MongoDB"
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
}

# Create MongoDB replica set
resource "aws_instance" "mongo" {
  count         = 3
  ami           = data.aws_ami.amzlinux.id 
  instance_type = "t2.micro"

  # Attach subnet and SG
  subnet_id              = aws_subnet.mongo_public_subnet.id
  vpc_security_group_ids = [aws_security_group.mongo_sg.id]

  tags = {
    Name = "mongodb-${count.index}"
  }
}

# Output MongoDB instance IPs
output "mongo_instances" {
  value = aws_instance.mongo[*].public_ip
}
