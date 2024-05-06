{ pkgs, lib, ... }:
let
  inherit (pkgs.lib) mkAddressRecords;
in {
  resource.aws_route53_record = lib.mapAttrs (_: lib.recursiveUpdate { ttl = "60"; }) {
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
    auth-tt_serokell_io = {
      zone_id = "\${data.aws_route53_zone.serokell_io.zone_id}";
      name = "auth-tt.serokell.io";
      type = "CNAME";
      records = ["alzirr.\${aws_route53_zone.gemini_serokell_team.name}"];
    };
  } // mkAddressRecords [{
    resource = "alzirr_gemini_serokell_team";
    zone_id = "\${aws_route53_zone.gemini_serokell_team.zone_id}";
    name = "alzirr.gemini.serokell.team";
    ipv4_records = ["135.181.78.88"];
    ipv6_records = ["2a01:4f9:4b:1667::1"];
  }];
}
