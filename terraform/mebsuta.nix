{ pkgs, lib, ... }:
let
  inherit (import ./common.nix) mkHcloud;
  inherit (pkgs.lib) mkAddressRecords;
in {
  resource.hcloud_server.mebsuta = mkHcloud {
    name = "mebsuta";
    ssh_keys = ["\${hcloud_ssh_key.notgne2.id}"];
  };

  resource.aws_route53_record = lib.mapAttrs (_: lib.recursiveUpdate { ttl = "60"; }) {
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
  } // mkAddressRecords [
    {
      resource = "mebsuta_gemini_serokell_team";
      zone_id = "\${aws_route53_zone.gemini_serokell_team.zone_id}";
      name = "mebsuta.\${aws_route53_zone.gemini_serokell_team.name}";
      ipv4_records = ["\${hcloud_server.mebsuta.ipv4_address}"];
      ipv6_records = ["\${hcloud_server.mebsuta.ipv6_address}"];
    }
    {
      resource = "vpn_serokell_net";
      zone_id = "\${data.aws_route53_zone.serokell_net.zone_id}";
      name = "vpn.serokell.net";
      ipv4_records = ["\${hcloud_server.mebsuta.ipv4_address}"];
      ipv6_records = ["\${hcloud_server.mebsuta.ipv6_address}"];
    }
  ];
}
