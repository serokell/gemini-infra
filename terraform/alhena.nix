{ lib, ... }:
let
  inherit (import ./common.nix) mkAWS;
in {
  resource.aws_instance.alhena = mkAWS {
    key_name = "Chris"; # eu-west-2

    volume_size = "20";

    tags = {
      Name = "alhena";
    };
  };

  # Public DNS
  resource.aws_route53_record = lib.mapAttrs (_: lib.recursiveUpdate { ttl = "60"; }) {
    alhena_gemini_serokell_team_ipv4 = {
      zone_id = "\${aws_route53_zone.gemini_serokell_team.zone_id}";
      name = "alhena.\${aws_route53_zone.gemini_serokell_team.name}";
      type = "A";
      records = ["\${aws_instance.alhena.public_ip}"];
    };

    alhena_gemini_serokell_team_ipv6 = {
      zone_id = "\${aws_route53_zone.gemini_serokell_team.zone_id}";
      name = "alhena.\${aws_route53_zone.gemini_serokell_team.name}";
      type = "AAAA";
      records = ["\${aws_instance.alhena.ipv6_addresses[0]}"];
    };
  };
}
