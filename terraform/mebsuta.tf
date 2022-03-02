resource "hcloud_server" "mebsuta" {
  name        = "mebsuta"
  image       = "ubuntu-20.04"
  server_type = "cx11"
  ssh_keys    = [hcloud_ssh_key.notgne2.id]
  # Install NixOS 20.09
  user_data = <<EOF
    #cloud-config

    runcmd:
      - curl https://raw.githubusercontent.com/elitak/nixos-infect/master/nixos-infect | NIX_CHANNEL=nixos-20.09 bash 2>&1 | tee /tmp/infect.log
EOF
}

resource "aws_route53_record" "mebsuta_gemini_serokell_team_ipv4" {
  zone_id = aws_route53_zone.gemini_serokell_team.zone_id
  name    = "mebsuta.${aws_route53_zone.gemini_serokell_team.name}"
  type    = "A"
  ttl     = "60"
  records = [hcloud_server.mebsuta.ipv4_address]
}

resource "aws_route53_record" "mebsuta_gemini_serokell_team_ipv6" {
  zone_id = aws_route53_zone.gemini_serokell_team.zone_id
  name    = "mebsuta.${aws_route53_zone.gemini_serokell_team.name}"
  type    = "AAAA"
  ttl     = "60"
  records = [hcloud_server.mebsuta.ipv6_address]
}

resource "aws_route53_record" "vpn_serokell_net_ipv4" {
  zone_id = data.aws_route53_zone.serokell_net.zone_id
  name    = "vpn.serokell.net"
  type    = "A"
  ttl     = "60"
  records = [hcloud_server.mebsuta.ipv4_address]
}

resource "aws_route53_record" "vpn_serokell_net_ipv6" {
  zone_id = data.aws_route53_zone.serokell_net.zone_id
  name    = "vpn.serokell.net"
  type    = "AAAA"
  ttl     = "60"
  records = [hcloud_server.mebsuta.ipv6_address]
}

resource "aws_route53_record" "dtunns_serokell_net" {
  zone_id = data.aws_route53_zone.serokell_net.zone_id
  name    = "dtunns.serokell.net"
  type    = "A"
  ttl     = "60"
  records = [hcloud_server.mebsuta.ipv4_address]
}

resource "aws_route53_record" "dtun_serokell_net" {
  zone_id = data.aws_route53_zone.serokell_net.zone_id
  name    = "dtun.serokell.net"
  type    = "NS"
  ttl     = "60"
  records = [aws_route53_record.dtunns_serokell_net.name]
}