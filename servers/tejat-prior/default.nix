{ modulesPath, inputs, config, pkgs, lib, ... }:
let
  profile-root = "/nix/var/nix/profiles/per-user/deploy";
  vs = config.vault-secrets.secrets;
in
with lib;
{
  imports = [
    inputs.serokell-nix.nixosModules.ec2
    inputs.tzbot.nixosModules.default
  ];

  users.users.deploy = {
    isSystemUser = true;
    useDefaultShell = true;
    group = "deploy";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOL8Mv5pSRuc5TFdx0YcJK9I93KG80W/TqnCqTk1uqiN"
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
