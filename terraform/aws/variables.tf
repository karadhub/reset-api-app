variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Key pair name"
  type        = string
}

variable "public_key_path" {
  description = "Path to your public SSH key (e.g., ~/.ssh/id_rsa.pub)"
  type        = string
}
