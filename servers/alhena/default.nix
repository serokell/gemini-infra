{ modulesPath, inputs, config, pkgs, ... }:
let
  vs = config.vault-secrets.secrets;
in {
  imports = [
    inputs.serokell-nix.nixosModules.ec2
    inputs.hermetic.nixosModules.hermetic
  ];

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  vault-secrets.secrets.hermetic.environmentVariableNamePrefix = "hermetic";
  services.hermetic = {
    enable = true;
    environmentFile = "${vs.hermetic}/environment";
    package = inputs.hermetic.defaultPackage.${pkgs.stdenv.system};
  };

  services.nginx = {
    enable = true;
    virtualHosts.hermetic = {
      default = true;

      serverName = with config.networking; "${hostName}.${domain}";
      enableACME = true;
      forceSSL = true;
    };
  };

  networking.hostName = "alhena";
  wireguard-ip-address = "172.21.0.9";
}
