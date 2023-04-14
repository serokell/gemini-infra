{
  mkAWS = let
    security-group = [
      "\${aws_security_group.egress_all.id}"
      "\${aws_security_group.http.id}"
      "\${aws_security_group.ssh.id}"
      "\${aws_security_group.wireguard.id}"
    ]; in {key_name, volume_size, tags, vpc_security_group_ids ? security-group}: {
      # Networking
      availability_zone = "\${module.vpc.azs[2]}";
      subnet_id = "\${module.vpc.public_subnets[2]}";
      associate_public_ip_address = true;
      inherit key_name tags vpc_security_group_ids;

      # Instance parameters
      instance_type = "t3a.micro";
      monitoring = true;

      # Disk type, size, and contents
      lifecycle.ignore_changes = [ "ami" ];
      ami = "\${data.aws_ami.nixos.id}";
      root_block_device = {
        volume_type = "gp2";
        inherit volume_size;
      };
    };

  mkHcloud = {name, ssh_keys}: {
    inherit name ssh_keys;
    image = "ubuntu-20.04";
    server_type = "cx11";
    lifecycle.ignore_changes = [ "user_data" ];
    # Install NixOS 20.09
    user_data = ''
    #cloud-config

    runcmd:
      - curl https://raw.githubusercontent.com/elitak/nixos-infect/master/nixos-infect | NIX_CHANNEL=nixos-20.09 bash 2>&1 | tee /tmp/infect.log
    '';
  };

}
