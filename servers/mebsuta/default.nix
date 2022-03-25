{ modulesPath, inputs, config, lib, pkgs, ... }:

let
  vs = config.vault-secrets.secrets;
in
{
  imports = [
    inputs.serokell-nix.nixosModules.hetzner-cloud
    inputs.subspace.nixosModule
  ];

  networking.hostName = "mebsuta";
  wireguard-ip-address = "172.21.0.34";

  hetzner.ipv6Address = "2a01:4f9:c010:2e68::1";

  networking.wireguard.enable = true;

  # ensure ethernet interface name is eth0
  networking.usePredictableInterfaceNames = false;

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = 1;

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  networking.firewall.allowedUDPPorts = [
    53 # iodined: TODO
    53222 # wireguard
  ];

  vault-secrets.secrets.iodined = {
    user = "iodined";
    group = "iodined";
  };

  services.iodine.server = {
    enable = true;
    domain = "dtun.serokell.net";
    passwordFile = "${vs.iodined}/password";
    ip = "10.53.0.1/16";
    extraConfig = "-c";
  };

  services.subspace = {
    enable = true;
    httpInsecure = false;
    httpHost = "vpn.serokell.net";
    letsencrypt = false;
  };

  services.nginx = {
    enable = true;
    virtualHosts."vpn.serokell.net" = {
      enableACME = true;
      forceSSL = true;
      locations."/".proxyPass = "http://localhost:3331";
    };
  };
}
