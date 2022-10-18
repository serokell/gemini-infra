{ modulesPath, inputs, config, pkgs, lib, ... }:
let
  profile-root = "/nix/var/nix/profiles/per-user/deploy";
in
with lib;
{
  imports = [
    inputs.serokell-nix.nixosModules.ec2
  ];

  networking.firewall =
    { allowedTCPPorts = [ config.services.murmur.port ];
      allowedUDPPorts = [ config.services.murmur.port ];
    };

  users.users.deploy = {
    isSystemUser = true;
    useDefaultShell = true;
    group = "deploy";
  };

  security.sudo.extraRules = [
    {
      users = [ "deploy" ];
      commands = [{
        command = "/run/current-system/sw/bin/systemctl restart container@ligo-webide-thing.service";
        options = [ "NOPASSWD" ];
      }];
    }
  ];

  users.groups.deploy = {};

  containers.ligo-webide-thing = {
    autoStart = true;
    config = {
      imports = [ inputs.ligo-webide.nixosModules.default ];
      services.ligo-webide = {
        enable = true;
        package = "${profile-root}/backend";
        ligo-package = "${profile-root}/ligo";
        tezos-client-package = "${profile-root}/tezos-client";
      };
      services.ligo-webide-frontend = {
        serverName = "localhost";
        enable = true;
        package = "${profile-root}/frontend";
      };
    };
    bindMounts."${profile-root}".hostPath = "${profile-root}";
    ephemeral = true;
    privateNetwork = true;
    hostAddress = "192.168.100.10";
    localAddress = "192.168.100.11";
  };
  networking.nat.enable = true;
  networking.nat.internalInterfaces = ["ve-+"];
  networking.nat.externalInterface = "ens5";

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
  wireguard-ip-address = "172.21.0.37";
}
