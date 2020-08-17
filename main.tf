# Configure the AWS Provider
provider "aws" {
  version    = "~> 3.0"
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_vpc" "vpc_example"{
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = "true"
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "subnet-us-east-1-1a" {
  vpc_id            = aws_vpc.vpc_example.id
  cidr_block        = var.subnet_1a_cidr_block
  availability_zone = var.subnet_1a_az
  tags = {
    Name = var.subnet_1a_name
  }
}

resource "aws_subnet" "subnet-us-east-1-1b" {
  vpc_id            = aws_vpc.vpc_example.id
  cidr_block        = var.subnet_1b_cidr_block
  availability_zone = var.subnet_1b_az
  tags = {
    Name = var.subnet_1b_name
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
    Name = var.route_table_name
  }
}

resource "aws_main_route_table_association" "route-table-with-vpc" {
  vpc_id         = aws_vpc.vpc_example.id
  route_table_id = aws_route_table.route-table-example.id
}

resource "aws_security_group" "sg-example" {
  name        = var.security_group_name
  description = var.security_group_description
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
    Name = var.security_group_name
  }
}

resource "aws_instance" "web1" {
  ami                         = var.instance_ami
  instance_type               = var.instance_type
  associate_public_ip_address = "true"
  subnet_id                   = aws_subnet.subnet-us-east-1-1a.id
  vpc_security_group_ids      = [aws_security_group.sg-example.id]
  key_name                    = var.instance_key_name
  tags = {
    type = var.instance_tag_type
  }
  provisioner "local-exec" {
    command = "sleep 120; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ec2-user --private-key '${var.private_key_path}' -i ansible/aws_ec2.yaml ansible/main.yml"
  }
}

resource "aws_instance" "web2" {
  ami                         = var.instance_ami
  instance_type               = var.instance_type
  associate_public_ip_address = "true"
  subnet_id                   = aws_subnet.subnet-us-east-1-1b.id
  vpc_security_group_ids      = [aws_security_group.sg-example.id]
  key_name                    = var.instance_key_name
  tags = {
    type = var.instance_tag_type
  }
  provisioner "local-exec" {
    command = "sleep 120; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ec2-user --private-key '${var.private_key_path}' -i ansible/aws_ec2.yaml ansible/main.yml"
  }
}

resource "aws_lb_target_group" "target-group-example" {
  name     = var.target_group_name
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
  name               = var.lb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg-example.id]
  subnets            = [
    aws_subnet.subnet-us-east-1-1a.id,
    aws_subnet.subnet-us-east-1-1b.id
  ]

  tags = {
    Name = var.lb_name
  }
}

output "elb_public_ip" {
  value = aws_lb.lb-example.dns_name
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