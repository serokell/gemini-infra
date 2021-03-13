{ config, inputs, ... }: {
  imports = [
    inputs.serokell-nix.nixosModules.common
    inputs.serokell-nix.nixosModules.serokell-users
    inputs.vault-secrets.nixosModules.vault-secrets
  ];

  networking.domain = "gemini.serokell.team";

  systemd.services.amazon-init.enable = false;

  vault-secrets = {
    vaultPrefix = "kv/sys/gemini/${config.networking.hostName}";
    vaultAddress = "https://vault.serokell.org:8200";
    approlePrefix = "gemini-${config.networking.hostName}";
  };
}
