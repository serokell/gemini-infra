resource "aws_instance" "propus" {
  key_name = "balsoft" # eu-west-2

  # Networking
  availability_zone = module.vpc.azs[2]
  subnet_id = module.vpc.public_subnets[2]
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.egress_all.id,
    aws_security_group.ssh.id,
    aws_security_group.http.id,
    aws_security_group.wireguard.id,
  ]

  # Instance parameters
  instance_type = "t3a.large"
  monitoring = true

  # Disk type, size, and contents
  lifecycle { ignore_changes = [ ami ] }
  ami = data.aws_ami.nixos.id
  root_block_device {
    volume_type = "gp2"
    volume_size = "20"
  }
}

# Public DNS
resource "aws_route53_record" "propus_gemini_serokell_team_ipv4" {
  zone_id = aws_route53_zone.gemini_serokell_team.zone_id
  name    = "propus.${aws_route53_zone.gemini_serokell_team.name}"
  type    = "A"
  ttl     = "60"
  records = [aws_instance.propus.public_ip]
}

resource "aws_route53_record" "propus_gemini_serokell_team_ipv6" {
  zone_id = aws_route53_zone.gemini_serokell_team.zone_id
  name    = "propus.${aws_route53_zone.gemini_serokell_team.name}"
  type    = "AAAA"
  ttl     = "60"
  records = [aws_instance.propus.ipv6_addresses[0]]
}

resource "aws_route53_record" "meet_serokell_net_cname" {
  zone_id = data.aws_route53_zone.serokell_net.zone_id
  name    = "meet.${data.aws_route53_zone.serokell_net.name}"
  type    = "CNAME"
  ttl     = "60"
  records = ["propus.gemini.serokell.team"]
}
