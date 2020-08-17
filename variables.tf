variable "aws_region" {
    type        = string
    description = "AWS Region"
}

variable "aws_access_key" {
    type        = string
    description = "AWS Access Key"
}

variable "aws_secret_key" {
    type        = string
    description = "AWS Secret Key"
}

variable "private_key_path" {
    type        = string
    description = "Private key path to connect ec2 machines"
}

variable "vpc_name" {
    type        = string
    description = "VPC name"
}

variable "vpc_cidr_block" {
    type        = string
    description = "cidr block for VPC"
}

variable "subnet_1a_name" {
    type        = string
    description = "Subnet1 name"
}

variable "subnet_1a_cidr_block" {
    type        = string
    description = "cidr block for Subnet1"
}

variable "subnet_1a_az" {
    type        = string
    description = "Availability zone for subnet1"
}

variable "subnet_1b_name" {
    type        = string
    description = "Subnet2 name"
}

variable "subnet_1b_cidr_block" {
    type        = string
    description = "cidr block for Subnet2"
}

variable "subnet_1b_az" {
    type        = string
    description = "Availability zone for subnet2"
}

variable "route_table_name" {
    type        = string
    description = "Route table name"
}

variable "security_group_name" {
    type        = string
    description = "Security group name"
}

variable "security_group_description" {
    type        = string
    description = "Security group description"
}

variable "instance_ami" {
    type        = string
    description = "Amazon Machine Image"
}

variable "instance_type" {
    type        = string
    description = "EC2 machine type"
}

variable "instance_key_name" {
    type        = string
    description = "Key name to use on ec2 machines"
}

variable "instance_tag_type" {
    type        = string
    description = "Tag type to add to ec2 machines"
    default     = "ec2instance"
}

variable "target_group_name" {
    type        = string
    description = "Target group name"
}

variable "lb_name" {
    type        = string
    description = "Load Balancer name"
}
