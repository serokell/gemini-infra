{ pkgs, lib, ... }:
let
  inherit (import ./common.nix pkgs) mkAWS;
  inherit (pkgs.lib) mkAddressRecords;
in {
  resource.aws_instance.tejat-prior = mkAWS {
    key_name = "Chris"; # eu-west-2

    volume_size = "40";
    tags = {
      Name = "tejat-prior";
    };

    vpc_security_group_ids = [
      "\${aws_security_group.egress_all.id}"
      "\${aws_security_group.http.id}"
      "\${aws_security_group.ssh.id}"
      "\${aws_security_group.wireguard.id}"
    ];
  };

  # Public DNS
  resource.aws_eip.tejat-prior = {
    instance = "\${aws_instance.tejat-prior.id}";
    domain = "vpc";
  };
  resource.aws_route53_record = mkAddressRecords [{
    resource = "tejat-prior_gemini_serokell_team";
    zone_id = "\${aws_route53_zone.gemini_serokell_team.zone_id}";
    name = "tejat-prior.\${aws_route53_zone.gemini_serokell_team.name}";
    ipv4_records = ["\${aws_eip.tejat-prior.public_ip}"];
    ipv6_records = ["\${aws_instance.tejat-prior.ipv6_addresses[0]}"];
  }];
}
