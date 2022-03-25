{ modulesPath, inputs, config, lib, ... }:
{
  imports = [
    inputs.serokell-nix.nixosModules.ec2

    inputs.self.nixosModules.mtg
  ];

  vault-secrets.secrets.mtg = {
    user = "mtg";
  };

  services.mtg = {
    enable = true;
    secretFile = "${config.vault-secrets.secrets.mtg}/secret";
  };

  systemd.services.mtg.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = "mtg";
  };

  users.users.mtg = {
    isSystemUser = true;
    group = "mtg";
  };

  users.groups.mtg = {};

  networking.hostName = "mekbuda";
  wireguard-ip-address = "172.21.0.13";
}
