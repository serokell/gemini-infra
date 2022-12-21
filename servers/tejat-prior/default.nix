{ modulesPath, inputs, config, pkgs, lib, ... }:
let
  profile-root = "/nix/var/nix/profiles/per-user/deploy";
  vs = config.vault-secrets.secrets;
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
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINBuEKUhfJWZXUqgE2hN+aekbRj5yU8Q0kT4FjducocP webide" ];
  };

  serokell-users.wheelUsers = [ "sashasashasasha151" "pgujjula" ];

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

  containers.ligo-webide-thing = rec {
    autoStart = true;
    config = {
      imports = [ inputs.ligo-webide.nixosModules.default ];
      services.ligo-webide = {
        enable = true;
        package = "${profile-root}/webide/backend";
        ligo-package = "${profile-root}/webide/ligo";
        tezos-client-package = "${profile-root}/webide/tezos-client";
        gist-token = "/run/gist-token";
      };
      services.ligo-webide-frontend = {
        serverName = "localhost";
        enable = true;
        package = "${profile-root}/webide/frontend";
      };
      services.prometheus.exporters.node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        disabledCollectors = [ "timex" ];
        listenAddress = localAddress;
      };
      networking.firewall.allowedTCPPorts = [ 9100 ];
    };
    bindMounts."${profile-root}".hostPath = "${profile-root}";
    bindMounts."/run/gist-token".hostPath = "${vs.webide}/gist-token";
    ephemeral = true;
    privateNetwork = true;
    hostAddress = "192.168.100.10";
    localAddress = "192.168.100.11";
    forwardPorts = [ { protocol = "tcp"; hostPort = 10100; containerPort = 9100; } ];
  };
  networking.nat.enable = true;
  networking.nat.internalInterfaces = ["ve-+"];
  networking.nat.externalInterface = "ens5";

  vault-secrets.secrets.webide = {};

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
