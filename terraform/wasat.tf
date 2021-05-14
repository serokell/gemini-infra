resource "hcloud_server" "wasat" {
  name        = "wasat"
  image       = "ubuntu-20.04"
  server_type = "cx11"
  ssh_keys    = [hcloud_ssh_key.zhenya.id]
  # Install NixOS 20.09
  user_data = <<EOF
    #cloud-config

    runcmd:
      - curl https://raw.githubusercontent.com/elitak/nixos-infect/master/nixos-infect | NIX_CHANNEL=nixos-20.09 bash 2>&1 | tee /tmp/infect.log
EOF
}

resource "aws_route53_record" "wasat_gemini_serokell_team_ipv4" {
  zone_id = aws_route53_zone.gemini_serokell_team.zone_id
  name    = "wasat.${aws_route53_zone.gemini_serokell_team.name}"
  type    = "A"
  ttl     = "60"
  records = [hcloud_server.wasat.ipv4_address]
}

resource "aws_route53_record" "wasat_gemini_serokell_team_ipv6" {
  zone_id = aws_route53_zone.gemini_serokell_team.zone_id
  name    = "wasat.${aws_route53_zone.gemini_serokell_team.name}"
  type    = "AAAA"
  ttl     = "60"
  records = [hcloud_server.wasat.ipv6_address]
}

# serokell.net DNS records (can't be a CNAME becase it's a zone apex)
# (switch later)
# resource "aws_route53_record" "serokell_net_ipv4" {
#   zone_id = data.aws_route53_zone.serokell_net.zone_id
#   name    = "serokell.net"
#   type    = "A"
#   ttl     = "60"
#   records = [hcloud_server.wasat.ipv4_address]
# }

# resource "aws_route53_record" "serokell_net_ipv6" {
#   zone_id = data.aws_route53_zone.serokell_net.zone_id
#   name    = "serokell.net"
#   type    = "AAAA"
#   ttl     = "60"
#   records = [hcloud_server.wasat.ipv6_address]
# }
