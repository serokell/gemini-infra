{ modulesPath, inputs, config, pkgs, lib, ... }:
let
  profile-root = "/nix/var/nix/profiles/per-user/deploy";
  vs = config.vault-secrets.secrets;
  ports = {
    cors-proxy = 9999;
  };
in
with lib;
{
  imports = [
    inputs.serokell-nix.nixosModules.ec2
    inputs.self.nixosModules.cors-proxy
    inputs.tzbot.nixosModules.default
  ];

  networking.firewall =
    { allowedTCPPorts = [ config.services.murmur.port ];
      allowedUDPPorts = [ config.services.murmur.port ];
    };

  users.users.deploy = {
    isSystemUser = true;
    useDefaultShell = true;
    group = "deploy";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAdYHfE6k3bQ8xRy8r0MmOeLzyFlTuVbPPjVjXjeRUXD tzbot"
    ];
  };

  serokell-users.wheelUsers = [ "diogo" ];

  security.sudo.extraRules = [
    {
      users = [ "deploy" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/systemctl restart tzbot";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  users.groups.deploy = {};

  services.nginx = {
    enable = true;
    openFirewall = true;
    addSecurityHeaders = false;
    virtualHosts."ligo-webide-cors-proxy.serokell.team" = {
      enableACME = true;
      forceSSL = true;
      locations."/".proxyPass = "http://127.0.0.1:${toString ports.cors-proxy}";
    };
  };

  services.cors-proxy = {
    enable = true;
    port = ports.cors-proxy;
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

  services.tzbot = {
    enable = true;
    package = "${profile-root}/tzbot";
    botConfig = {
      maxRetries = 3;
      cacheUsersInfo = "3m";
      cacheConversationMembers = "3m";
      feedbackChannel = "C05QQKHU5KN"; # Channel ID for `#tzbot-feedback`
      feedbackFile = "/var/lib/tzbot/feedback.log";
      cacheReportDialog = "1h";
      inverseHelpUsageChance = 15;
      logLevel = "Info";
    };
    slackAppToken = "$SLACK_APP_TOKEN";
    slackBotToken = "$SLACK_BOT_TOKEN";
  };
  systemd.services.tzbot.serviceConfig.EnvironmentFile = "${config.vault-secrets.secrets.tzbot}/environment";
  systemd.services.tzbot.after = [ "network.target" "tzbot-secrets.service" ];
  vault-secrets.secrets.tzbot = { user = "tzbot"; };

  networking.hostName = "tejat-prior";
  wireguard-ip-address = "172.21.0.37";
}
