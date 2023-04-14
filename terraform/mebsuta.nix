{ lib, ... }:
let inherit (import ./common.nix) mkHcloud;
in {
  resource.hcloud_server.mebsuta = mkHcloud {
    name = "mebsuta";
    ssh_keys = ["\${hcloud_ssh_key.notgne2.id}"];
  };

  resource.aws_route53_record = lib.mapAttrs (_: lib.recursiveUpdate { ttl = "60"; }) {
    mebsuta_gemini_serokell_team_ipv4 = {
      zone_id = "\${aws_route53_zone.gemini_serokell_team.zone_id}";
      name = "mebsuta.\${aws_route53_zone.gemini_serokell_team.name}";
      type = "A";
      records = ["\${hcloud_server.mebsuta.ipv4_address}"];
  };

    mebsuta_gemini_serokell_team_ipv6 = {
      zone_id = "\${aws_route53_zone.gemini_serokell_team.zone_id}";
      name = "mebsuta.\${aws_route53_zone.gemini_serokell_team.name}";
      type = "AAAA";
      records = ["\${hcloud_server.mebsuta.ipv6_address}"];
    };

    vpn_serokell_net_ipv4 = {
      zone_id = "\${data.aws_route53_zone.serokell_net.zone_id}";
      name = "vpn.serokell.net";
      type = "A";
      records = ["\${hcloud_server.mebsuta.ipv4_address}"];
    };

    vpn_serokell_net_ipv6 = {
      zone_id = "\${data.aws_route53_zone.serokell_net.zone_id}";
      name = "vpn.serokell.net";
      type = "AAAA";
      records = ["\${hcloud_server.mebsuta.ipv6_address}"];
    };

    dtunns_serokell_net = {
      zone_id = "\${data.aws_route53_zone.serokell_net.zone_id}";
      name = "dtunns.serokell.net";
      type = "A";
      records = ["\${hcloud_server.mebsuta.ipv4_address}"];
    };

    dtun_serokell_net = {
      zone_id = "\${data.aws_route53_zone.serokell_net.zone_id}";
      name = "dtun.serokell.net";
      type = "NS";
      records = ["\${aws_route53_record.dtunns_serokell_net.name}"];
    };
  };
}
