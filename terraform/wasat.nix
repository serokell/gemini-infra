{ pkgs, lib, ... }:
let
  inherit (import ./common.nix) mkHcloud;
  inherit (pkgs.lib) mkAddressRecords;
in {
  resource.hcloud_server.wasat = mkHcloud {
    name = "wasat";
    ssh_keys = ["\${hcloud_ssh_key.zhenya.id}"];
  };

  resource.aws_route53_record = mkAddressRecords [
    {
      resource = "wasat_gemini_serokell_team";
      zone_id = "\${aws_route53_zone.gemini_serokell_team.zone_id}";
      name = "wasat.\${aws_route53_zone.gemini_serokell_team.name}";
      ipv4_records = ["\${hcloud_server.wasat.ipv4_address}"];
      ipv6_records = ["\${hcloud_server.wasat.ipv6_address}"];
    }
    # serokell.net DNS records (can't be a CNAME becase it's a zone apex)
    {
      resource = "serokell_net";
      zone_id = "\${data.aws_route53_zone.serokell_net.zone_id}";
      name = "serokell.net";
      ipv4_records = ["\${hcloud_server.wasat.ipv4_address}"];
      ipv6_records = ["\${hcloud_server.wasat.ipv6_address}"];
    }
  ];
}
