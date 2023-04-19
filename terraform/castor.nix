{ pkgs, lib, ... }:
let
  inherit (import ./common.nix) mkAWS;
  inherit (pkgs.lib) mkAddressRecords;
in {
  resource.aws_instance.castor = mkAWS {
    key_name = "balsoft"; # eu-west-2

    volume_size = "30";
    tags = {
      Name = "castor";
    };
  };

  # Public DNS
  resource.aws_eip.castor = {
    instance = "\${aws_instance.castor.id}";
    vpc = true;
  };

  resource.aws_route53_record = {
    staging_edna_cname = {
      zone_id = "\${data.aws_route53_zone.serokell_team.zone_id}";
      name = "staging.edna.\${data.aws_route53_zone.serokell_team.name}";
      type = "CNAME";
      ttl = "60";
      records = ["\${aws_route53_record.castor_gemini_serokell_team_ipv4.name}"];
    };
  } // mkAddressRecords [{
    resource = "castor_gemini_serokell_team";
    zone_id = "\${aws_route53_zone.gemini_serokell_team.zone_id}";
    name = "castor.\${aws_route53_zone.gemini_serokell_team.name}";
    ipv4_records = ["\${aws_eip.castor.public_ip}"];
    ipv6_records = ["\${aws_instance.castor.ipv6_addresses[0]}"];
  }];
}
