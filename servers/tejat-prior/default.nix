{ modulesPath, inputs, config, pkgs, lib, ... }:
with lib;
{
  imports = [
    inputs.serokell-nix.nixosModules.ec2
  ];

  networking.firewall =
    { allowedTCPPorts = [ config.services.murmur.port ];
      allowedUDPPorts = [ config.services.murmur.port ];
    };


  containers.ligo-webide-thing = {
    autoStart = true;
    config = {
      imports = [ inputs.ligo-webide.nixosModules.default ];
      services.ligo-webide.enable = true;
      services.ligo-webide-frontend = {
        serverName = "localhost";
        enable = true;
      };
    };
    ephemeral = true;
    privateNetwork = true;
    hostAddress = "192.168.100.10";
    localAddress = "192.168.100.11";
  };

  services.nginx = {
    enable = true;
    openFirewall = true;
    addSecurityHeaders = false;
    virtualHosts."ligo-webide.serokell.team" = {
      enableACME = true;
      forceSSL = true;
      locations."/".proxyPass = "http://192.168.100.11:80";
    };
  };

  services.murmur =
    { enable = true;
      welcometext = "Welcome to the SRE Serokell Mumble server, enjoy your stay!";
      hostName = config.networking.hostName;
      password = "$MURMUR_PASSWORD";
      extraConfig = ''
        allowping = false
        host =
      '';
    };

  vault-secrets.secrets.murmur =
   { user = "murmur";
  };

  systemd.services.murmur.serviceConfig.EnvironmentFile = "${config.vault-secrets.secrets.murmur}/environment";

  networking.hostName = "tejat-prior";
  wireguard-ip-address = "172.21.0.34";
}
