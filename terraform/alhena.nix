{ pkgs, lib, ... }:
let
  inherit (import ./common.nix pkgs) mkAWS;
  inherit (pkgs.lib) mkAddressRecords;
in {
  resource.aws_instance.alhena = mkAWS {
    key_name = "Chris"; # eu-west-2

    volume_size = "20";

    tags = {
      Name = "alhena";
    };
  };

  # Public DNS
  resource.aws_route53_record = mkAddressRecords [{
    resource = "alhena_gemini_serokell_team";
    zone_id = "\${aws_route53_zone.gemini_serokell_team.zone_id}";
    name = "alhena.\${aws_route53_zone.gemini_serokell_team.name}";
    ipv4_records = ["\${aws_instance.alhena.public_ip}"];
    ipv6_records = ["\${aws_instance.alhena.ipv6_addresses[0]}"];
  }];
}
