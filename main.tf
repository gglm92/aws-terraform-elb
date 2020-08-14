# Configure the AWS Provider
provider "aws" {
  version    = "~> 3.0"
  region     = "us-east-1"
  access_key = "your_access_key"
  secret_key = "your_secret_key"
}

resource "aws_vpc" "vpc_example"{
  cidr_block           = "12.0.0.0/16"
  enable_dns_hostnames = "true"
  tags = {
    Name = "production"
  }
}

resource "aws_subnet" "subnet-us-east-1-1a" {
  vpc_id            = aws_vpc.vpc_example.id
  cidr_block        = "12.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "subnet-us-east-1-1a"
  }
}

resource "aws_subnet" "subnet-us-east-1-1b" {
  vpc_id            = aws_vpc.vpc_example.id
  cidr_block        = "12.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "subnet-us-east-1-1b"
  }
}

resource "aws_internet_gateway" "igw-example" {
  vpc_id = aws_vpc.vpc_example.id
}

resource "aws_route_table" "route-table-example"{
  vpc_id = aws_vpc.vpc_example.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-example.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.igw-example.id
  }
  tags = {
    Name = "route-table-example"
  }
}

resource "aws_main_route_table_association" "route-table-with-vpc" {
  vpc_id         = aws_vpc.vpc_example.id
  route_table_id = aws_route_table.route-table-example.id
}

resource "aws_security_group" "sg-example" {
  name        = "allow-http-ssh"
  description = "Allow HTTP and SSH inbound traffic"
  vpc_id      = aws_vpc.vpc_example.id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Http from VPC"
    from_port   = 80
    to_port     = 80
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
    Name = "allow-http-ssh"
  }
}

resource "aws_instance" "web1" {
  ami                         = "ami-09d8b5222f2b93bf0"
  instance_type               = "t2.micro"
  associate_public_ip_address = "true"
  subnet_id                   = aws_subnet.subnet-us-east-1-1a.id
  vpc_security_group_ids      = [aws_security_group.sg-example.id]
  key_name                    = "your_key_name"
  tags = {
    type = "ec2instance"
  }
}

resource "aws_instance" "web2" {
  ami                         = "ami-09d8b5222f2b93bf0"
  instance_type               = "t2.micro"
  associate_public_ip_address = "true"
  subnet_id                   = aws_subnet.subnet-us-east-1-1b.id
  vpc_security_group_ids      = [aws_security_group.sg-example.id]
  key_name                    = "your_key_name"
  tags = {
    type = "ec2instance"
  }
}

resource "aws_lb_target_group" "target-group-example" {
  name     = "example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_example.id
}

resource "aws_lb_target_group_attachment" "lb-tg-web1" {
  target_group_arn = aws_lb_target_group.target-group-example.arn
  target_id        = aws_instance.web1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "lb-tg-web2" {
  target_group_arn = aws_lb_target_group.target-group-example.arn
  target_id        = aws_instance.web2.id
  port             = 80
}

resource "aws_lb" "lb-example" {
  name               = "lb-example"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg-example.id]
  subnets            = [
    aws_subnet.subnet-us-east-1-1a.id,
    aws_subnet.subnet-us-east-1-1b.id
  ]

  tags = {
    Name = "lb-example"
  }
}

resource "aws_alb_listener" "lb-example-listener" {  
  load_balancer_arn = aws_lb.lb-example.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {    
    target_group_arn = aws_lb_target_group.target-group-example.arn
    type             = "forward"  
  }
}