{ modulesPath, inputs, config, lib, ... }:
{
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
    inputs.self.nixosModules.mtg
  ];

  vault-secrets.secrets.mtg = {
    user = "mtg";
  };

  nixpkgs.overlays = [ inputs.self.overlay ];

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
