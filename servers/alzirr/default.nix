{ modulesPath, inputs, config, lib, ... }:
{
  imports = [
    ./platform.nix    # hetzner-specific configuration
    ./deployment.nix  # deployment payload
  ];

  networking.hostName = "alzirr";
}
