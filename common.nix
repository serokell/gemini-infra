{ config, inputs, ... }: {
  imports = [
    inputs.serokell-nix.nixosModules.common
    inputs.serokell-nix.nixosModules.serokell-users
    inputs.serokell-nix.nixosModules.vault-secrets
  ];

  networking.domain = "gemini.serokell.team";

  vault-secrets = {
    vaultPathPrefix = "kv/sys/gemini";
    vaultAddress = "https://vault.serokell.org:8200";
    namespace = config.networking.hostName;
    approlePrefix = "gemini-${config.networking.hostName}";
  };
}
