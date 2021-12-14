{ modulesPath, inputs, config, pkgs, ... }:
{
  imports = [
    inputs.serokell-nix.nixosModules.ec2
    inputs.hermetic.nixosModules.hermetic
    inputs.self.nixosModules.suitecrm
  ];

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  services.nginx.virtualHosts.suitecrm = {
    serverName = "suitecrm.serokell.team";
    default = true;

    enableACME = true;
    forceSSL = true;
  };

  services.suitecrm.enable = true;

  networking.hostName = "pollux";
  wireguard-ip-address = "172.21.0.33";
}
