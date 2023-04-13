{ lib, ... }:
{
  resource.aws_route53_record = lib.mapAttrs (_: lib.recursiveUpdate { ttl = "60"; }) {
    alzirr_gemini_serokell_team_ipv4 = {
      zone_id = "\${aws_route53_zone.gemini_serokell_team.zone_id}";
      name = "alzirr.gemini.serokell.team";
      type = "A";
      records = ["135.181.78.88"];
    };

    alzirr_gemini_serokell_team_ipv6 = {
      zone_id = "\${aws_route53_zone.gemini_serokell_team.zone_id}";
      name = "alzirr.gemini.serokell.team";
      type = "AAAA";
      records = ["2a01:4f9:4b:1667::1"];
    };

    tt_serokell_io = {
      zone_id = "\${data.aws_route53_zone.serokell_io.zone_id}";
      name = "tt.serokell.io";
      type = "CNAME";
      records = ["alzirr.\${aws_route53_zone.gemini_serokell_team.name}"];
    };

    tt2_serokell_io = {
      zone_id = "\${data.aws_route53_zone.serokell_io.zone_id}";
      name = "tt2.serokell.io";
      type = "CNAME";
      records = ["alzirr.\${aws_route53_zone.gemini_serokell_team.name}"];
    };
  };
}
