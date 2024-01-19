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
