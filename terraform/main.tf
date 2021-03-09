terraform {
  backend "s3" {
    bucket = "serokell-gemini-tfstate"
    dynamodb_table = "serokell-gemini-tfstate-lock"
    encrypt = true
    key    = "gemini/terraform.tfstate"
    region = "eu-west-2"
  }
  ## Prevent unwanted updates
  required_version = "= 0.12.29" # Use nix-shell or nix develop
}

resource "aws_route53_zone" "gemini_serokell_team" {
  name = "gemini.serokell.team"
}

data "aws_route53_zone" "serokell_team" {
  name = "serokell.team"
}

# Grab the latest NixOS AMI built by Serokell
data "aws_ami" "nixos" {
  most_recent = true

  filter {
    name = "name"
    values = ["NixOS-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["920152662742"] # Serokell
}

resource "aws_key_pair" "balsoft" {
  key_name = "balsoft"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDd2OdcSHUsgezuV+cpFqk9+Svtup6PxIolv1zokVZdqvS8qxLsA/rwYmQgTnuq4/zK/GIxcUCH4OxYlW6Or4M4G7qrDKcLAUrRPWkectqEooWRflZXkfHduMJhzeOAsBdMfYZQ9024GwKr/4yriw2BGa8GbbAnQxiSeTipzvXHoXuRME+/2GsMFAfHFvxzXRG7dNOiLtLaXEjUPUTcw/fffKy55kHtWxMkEvvcdyR53/24fmO3kLVpEuoI+Mp1XFtX3DvRM9ulgfwZUn8/CLhwSLwWX4Xf9iuzVi5vJOJtMOktQj/MwGk4tY/NPe+sIk+nAUKSdVf0y9k9JrJT98S/ cardno:000610645773"
}

# Allow ALL egress traffic
resource "aws_security_group" "egress_all" {
  name = "egress_all"
  description = "Allow inbound and outbound egress traffic"
  vpc_id = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Allow traffic for the prometheus exporter
resource "aws_security_group" "prometheus_exporter_node" {
  name = "prometheus_exporter_node"
  description = "Allow Prometheus Node Exporter data scraping"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port = 9100
    to_port = 9100
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Allow SSH traffic
resource "aws_security_group" "ssh" {
  name = "ssh"
  description = "Allow inbound and outbound traffic for ssh"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port = 17788
    to_port = 17788
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Allow HTTP(S) traffic
resource "aws_security_group" "http" {
  name = "http"
  description = "Allow inbound and outbound http(s) traffic"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Allow mtg traffic
resource "aws_security_group" "mtg" {
  name = "mtg"
  description = "Allow inbound and outbound traffic of mtg server"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port = 3128
    to_port = 3128
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Network resources
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "= v2.46.0"

  name = "gemini-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  public_subnets   = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  public_subnet_ipv6_prefixes     = [0, 1, 2]

  enable_ipv6                     = true
  assign_ipv6_address_on_creation = true

  enable_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support = true

  enable_dhcp_options              = true
  dhcp_options_domain_name         = "gemini.serokell.team"

  tags = {
    Terraform = "true"
    Environment = "production"
  }
}


output "gemini_ns" {value = [ aws_route53_zone.gemini_serokell_team.name_servers ]}
