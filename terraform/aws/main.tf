terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_key_pair" "this" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

resource "aws_security_group" "node_exporter_sg" {
  name        = "node-exporter-sg"
  description = "Allow SSH and node exporter port"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Node Exporter"
    from_port   = 9100
    to_port     = 9100
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

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

resource "aws_instance" "node_exporter" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = tolist(data.aws_subnet_ids.default.ids)[0]
  vpc_security_group_ids = [aws_security_group.node_exporter_sg.id]
  key_name               = aws_key_pair.this.key_name

  user_data = <<-EOF
              #!/bin/bash
              set -e
              apt-get update -y
              apt-get install -y wget tar
              useradd --no-create-home --shell /usr/sbin/nologin node_exporter || true
              cd /tmp
              ARCH=$(uname -m)
              if [ "$ARCH" = "x86_64" ]; then ARCH=amd64; fi
              VERSION="1.8.2"
              wget -q https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/node_exporter-${VERSION}.linux-${ARCH}.tar.gz
              tar xzf node_exporter-${VERSION}.linux-${ARCH}.tar.gz
              cp node_exporter-${VERSION}.linux-${ARCH}/node_exporter /usr/local/bin/
              chown node_exporter:node_exporter /usr/local/bin/node_exporter

              cat >/etc/systemd/system/node_exporter.service <<SERVICE
              [Unit]
              Description=Prometheus Node Exporter
              After=network.target

              [Service]
              User=node_exporter
              Group=node_exporter
              Type=simple
              ExecStart=/usr/local/bin/node_exporter

              [Install]
              WantedBy=multi-user.target
              SERVICE

              systemctl daemon-reload
              systemctl enable --now node_exporter
              EOF

  tags = {
    Name = "mahad-node-exporter"
  }
}

output "public_ip" {
  description = "Public IP of the instance"
  value       = aws_instance.node_exporter.public_ip
}
