terraform {
  backend "s3" {
    bucket = "serokell-gemini-tfstate"
    dynamodb_table = "serokell-gemini-tfstate-lock"
    encrypt = true
    key    = "gemini/terraform.tfstate"
    region = "eu-west-2"
  }

  ## Prevent unwanted updates
  required_version = "1.0.4" # Use nix-shell or nix develop

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.43.0"
    }
    hcloud = {
      source = "nixpkgs/hcloud"
      version = "~> 1.26.0"
    }
    vault = {
      source = "hashicorp/vault"
      version = "~> 2.11.0"
    }
  }
}

resource "aws_route53_zone" "gemini_serokell_team" {
  name = "gemini.serokell.team"
}

data "aws_route53_zone" "serokell_team" {
  name = "serokell.team"
}

data "aws_route53_zone" "serokell_io" {
  name = "serokell.io"
}

data "aws_route53_zone" "serokell_net" {
  name = "serokell.net"
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

resource "hcloud_ssh_key" "zhenya" {
  name = "zhenya"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDVESCckOB+2NoojRR+rMl2N4OTf7PQR2BvcxF7cMeRtpSDnMQwbitJNCm0tNygUa8Sn5obaS0HSTfvefIPaDOhgDwi/hGznHiCI3+cAesi/GXXq5p+ota/Ab2oQOFsAquy3sGxNaMhVwU2FU8uyDmiCEbS8kKWAW/YXVqRTPsbkkNBJIwetvzXyrFrYZeCdShZmcPtOGHLpUByKhXkQHXpZ86Bbu9NH/0GsFamADlRaoQQa1+oTWPCWvwsctsAUcHw4/jpeHQffCFATYYS57xYXKkjMZJHypDyjJB9U40bX/HZYaTMP4fDlXeEO/OU2YkAJdt0NBylcE1WzFrOKRNBCcgfgHBzsD3rxMvVNPAl/JXTiEBpXZoza8p+gmQRMMe9SDQLz9pRN7paRsAi1qaQnFV1DbCBPrY2OezJujIuRKc8t0D3nEgg5rcYi2fcFkJscwAsvspTBnK9LCC5ojqa0O5BGTYwlxp2cUkFbWyM2oaRqcQo3ypPaJBybo/TF2FqqHlWNlckwOPPTGngThT6kkFEF+kqMUlUdokiWcpl2K7psfl5RdYGIFfey74NiqoSZ9gyta2WBkY7J41YrsQh20vtGhWWYl/+pDo3cggqmP0fEmD5CaPZXimvHjOjfcxGMooPpkOl3G3I0eQSpvlPpLZHEhh5fThFIAF2RxN/IQ== zhenyavinogradov@gmail.com"
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

# Allow Mumble traffic
resource "aws_security_group" "mumble" {
  name = "mumble"
  description = "Allow inbound and outbound traffic of Mumble(Murmur) server"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port = 64738
    to_port = 64738
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port = 64738
    to_port = 64738
    protocol = "udp"
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

# Allow wireguard traffic
resource "aws_security_group" "wireguard" {
  name = "wireguard"
  description = "Allow inbound and outbound traffic for wireguard"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port        = 51820
    to_port          = 51820
    protocol         = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Network resources
module "vpc" {
  source = "./.terraform_nix/modules/vpc"

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
