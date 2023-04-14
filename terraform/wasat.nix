{ lib, ... }:
let inherit (import ./common.nix) mkHcloud;
in {
  resource.hcloud_server.wasat = mkHcloud {
    name = "wasat";
    ssh_keys = ["\${hcloud_ssh_key.zhenya.id}"];
  };

  resource.aws_route53_record = lib.mapAttrs (_: lib.recursiveUpdate { ttl = "60"; }) {
    wasat_gemini_serokell_team_ipv4 = {
      zone_id = "\${aws_route53_zone.gemini_serokell_team.zone_id}";
      name = "wasat.\${aws_route53_zone.gemini_serokell_team.name}";
      type = "A";
      records = ["\${hcloud_server.wasat.ipv4_address}"];
    };

    wasat_gemini_serokell_team_ipv6 = {
      zone_id = "\${aws_route53_zone.gemini_serokell_team.zone_id}";
      name = "wasat.\${aws_route53_zone.gemini_serokell_team.name}";
      type = "AAAA";
      records = ["\${hcloud_server.wasat.ipv6_address}"];
    };

    # serokell.net DNS records (can't be a CNAME becase it's a zone apex)
    serokell_net_ipv4 = {
      zone_id = "\${data.aws_route53_zone.serokell_net.zone_id}";
      name = "serokell.net";
      type = "A";
      records = ["\${hcloud_server.wasat.ipv4_address}"];
    };

    serokell_net_ipv6 = {
      zone_id = "\${data.aws_route53_zone.serokell_net.zone_id}";
      name = "serokell.net";
      type = "AAAA";
      records = ["\${hcloud_server.wasat.ipv6_address}"];
    };
  };
}
