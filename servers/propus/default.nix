{ config, pkgs, inputs, lib, ... }: {
  imports = [
    inputs.serokell-nix.nixosModules.ec2
  ];

  networking.hostName = "propus";

  services.jitsi-meet = {
    enable = true;
    hostName = "meet.serokell.net";
  };

  services.jibri = {
    enable = true;
    config = {

    };
  };

  services.nginx.virtualHosts.${config.services.jitsi-meet.hostName} = {
    enableACME = true;
    forceSSL = true;
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  wireguard-ip-address = "172.21.0.123";

}
