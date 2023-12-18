{ modulesPath, inputs, config, lib, pkgs, ... }:

let
  vs = config.vault-secrets.secrets;

  wg-keys = import ./wg-keys.nix;

  # hosts from https://github.com/StevenBlack/hosts
  addn-hosts = pkgs.runCommand "hosts" {} ''
    # Filter for only comments and redirections to 0.0.0.0, so we can be sure
    # nothing funky is going on.
    grep '^#\|^0\.0\.0\.0 ' < ${inputs.stevenblack-hosts}/hosts > $out
  '';

  # forward port 53 on eth0 to wireguard, for networks that block non-standard ports
  iptables-rule = "PREROUTING -t nat -i eth0 -p udp --dport 53 -j REDIRECT --to-port 35944";

in {
  imports = [
    inputs.serokell-nix.nixosModules.hetzner-cloud
  ];

  networking.hostName = "wasat";
  wireguard-ip-address = "172.21.0.28";

  hetzner.ipv6Address = "2a01:4f9:c011:27bc::1";

  # ensure ethernet interface name is eth0
  networking.usePredictableInterfaceNames = false;

  networking.firewall.allowedUDPPorts = [
    53     # wireguard on eth0, dnsmasq on wg-serokell
    35944  # wireguard
  ];

  networking.firewall.extraCommands = "ip46tables -A ${iptables-rule}";
  networking.firewall.extraStopCommands = "ip46tables -D ${iptables-rule}";

  networking.nat = {
    enable = true;
    enableIPv6 = true;
    externalInterface = "eth0";
    internalInterfaces = [ "wg-serokell" ];
  };

  # contains wireguard private key
  vault-secrets.secrets.wireguard-wg-serokell = {};

  networking.wireguard.interfaces.wg-serokell = {
    listenPort = 35944;
    ips = [ "172.20.0.0/16" "fd73:7272:ed50::/48" ];
    privateKeyFile = "${vs.wireguard-wg-serokell}/private_key";
    peers = lib.flip lib.mapAttrsToList wg-keys (ipSuffix: publicKey: {
      allowedIPs = [
        "172.20.0.${ipSuffix}/32"
        "fd73:7272:ed50::${ipSuffix}/128"
      ];
      publicKey = publicKey;
    });
  };

  # dns server blocking malicious hostnames
  services.dnsmasq = {
    enable = true;
    settings.server = [ "1.1.1.1" "1.0.0.1" ];
    resolveLocalQueries = false;
    extraConfig = ''
      interface=wg-serokell
      bind-interfaces
      cache-size=4096
      addn-hosts=${addn-hosts}
    '';
  };

  # dnsmasq needs wireguard interface
  systemd.services.dnsmasq.after = [ "wireguard-wg-serokell.service" "efi.mount"];
}
