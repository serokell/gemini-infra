{ lib, ... }:
let
  inherit (import ./common.nix) mkAWS;
in {
  resource.aws_instance.jishui = mkAWS {
    key_name = "Chris"; # eu-west-2

    volume_size = "30";
    tags = {
      Name = "jishui";
    };
  };

  # Public DNS
  resource.aws_eip.jishui = {
    instance = "\${aws_instance.jishui.id}";
    vpc = true;
  };

  resource.aws_route53_record = lib.mapAttrs (_: lib.recursiveUpdate { ttl = "60"; }) {
    jishui_gemini_serokell_team_ipv4 = {
      zone_id = "\${aws_route53_zone.gemini_serokell_team.zone_id}";
      name = "jishui.\${aws_route53_zone.gemini_serokell_team.name}";
      type = "A";
      records = ["\${aws_eip.jishui.public_ip}"];
    };

    demo_edna_cname = {
      zone_id = "\${data.aws_route53_zone.serokell_team.zone_id}";
      name = "demo.edna.\${data.aws_route53_zone.serokell_team.name}";
      type = "CNAME";
      records = ["\${aws_route53_record.jishui_gemini_serokell_team_ipv4.name}"];
    };

    jishui_gemini_serokell_team_ipv6 = {
      zone_id = "\${aws_route53_zone.gemini_serokell_team.zone_id}";
      name = "jishui.\${aws_route53_zone.gemini_serokell_team.name}";
      type = "AAAA";
      records = ["\${aws_instance.jishui.ipv6_addresses[0]}"];
    };
  };
}
