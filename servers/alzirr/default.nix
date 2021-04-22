{ modulesPath, inputs, config, lib, ... }:
{
  imports = [
    ./platform.nix    # hetzner-specific configuration
    ./deployment.nix  # deployment payload
  ];

  networking.hostName = "alzirr";
  wireguard-ip-address = "172.21.0.25";
}
