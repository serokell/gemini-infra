{ pkgs, ... }:
let
  inherit (pkgs.lib) mkAWS mkHcloud;
in {
  mkAWS = {key_name, volume_size, tags, vpc_security_group_ids ? null}@args: mkAWS ({
    availability_zone = "\${module.vpc.azs[2]}";
    subnet_id = "\${module.vpc.public_subnets[2]}";
    instance_type = "t3a.micro";
  } // args);

  mkHcloud = {name, ssh_keys}: mkHcloud {
    inherit name ssh_keys;
    server_type = "cx11";
    image = "ubuntu-20.04";
    # Install NixOS 20.09
    user_data = ''
    #cloud-config

    runcmd:
      - curl https://raw.githubusercontent.com/elitak/nixos-infect/master/nixos-infect | NIX_CHANNEL=nixos-20.09 bash 2>&1 | tee /tmp/infect.log
    '';
  };

}
