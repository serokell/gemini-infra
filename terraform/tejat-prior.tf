resource "aws_instance" "tejat-prior" {
  key_name = "Chris" # eu-west-2

  # Networking
  availability_zone = module.vpc.azs[2]
  subnet_id = module.vpc.public_subnets[2]
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.egress_all.id,
    aws_security_group.http.id,
    aws_security_group.mumble.id,
    aws_security_group.ssh.id,
    aws_security_group.wireguard.id,
  ]

  # Instance parameters
  instance_type = "t3a.micro"
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
resource "aws_eip" "tejat-prior" {
  instance = aws_instance.tejat-prior.id
  vpc = true
}

resource "aws_route53_record" "tejat-prior_gemini_serokell_team_ipv4" {
  zone_id = aws_route53_zone.gemini_serokell_team.zone_id
  name    = "tejat-prior.${aws_route53_zone.gemini_serokell_team.name}"
  type    = "A"
  ttl     = "60"
  records = [aws_eip.tejat-prior.public_ip]
}

resource "aws_route53_record" "tejat-prior_gemini_serokell_team_ipv6" {
  zone_id = aws_route53_zone.gemini_serokell_team.zone_id
  name    = "tejat-prior.${aws_route53_zone.gemini_serokell_team.name}"
  type    = "AAAA"
  ttl     = "60"
  records = [aws_instance.tejat-prior.ipv6_addresses[0]]
}

resource "aws_route53_record" "mumble_cname" {
  zone_id = data.aws_route53_zone.serokell_team.zone_id
  name    = "mumble.${data.aws_route53_zone.serokell_team.name}"
  type    = "CNAME"
  ttl     = "60"
  records = [aws_route53_record.tejat-prior_gemini_serokell_team_ipv4.name]
}

resource "aws_route53_record" "ligo_webide_cname" {
  zone_id = data.aws_route53_zone.serokell_team.zone_id
  name    = "ligo-webide.${data.aws_route53_zone.serokell_team.name}"
  type    = "CNAME"
  ttl     = "60"
  records = [aws_route53_record.tejat-prior_gemini_serokell_team_ipv4.name]
}
