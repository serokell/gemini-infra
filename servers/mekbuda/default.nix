{ modulesPath, inputs, config, lib, ... }:
{
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
    inputs.serokell-nix.nixosModules.mtg
  ];

  vault-secrets.secrets.mtg = {
    user = "mtg";
  };

  services.mtg = {
    enable = true;
    secretFile = config.vault-secrets.secrets.mtg;
  };

  systemd.services.mtg.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = "mtg";
  };

  users.users.mtg = {
    isSystemUser = true;
  };

  networking.hostName = "mekbuda";
}
