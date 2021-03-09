{ modulesPath, ... }:
{
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
    ./edna.nix
  ];

  # Deployment user
  users.users.deploy = {
    useDefaultShell = true;
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOA+/SMYgdibz1vkEKl2Hyi5epcZ91Q+vjWUoLiATj4R edna" ];
  };

  # Allow the deployment user to restart CD services
  security.sudo.extraRules =
    [ {
      users = [ "deploy" ];
      commands = let
        restartCmd = "/run/current-system/sw/bin/systemctl restart";
      in [
        {
          command = "${restartCmd} docker-backend";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${restartCmd} docker-frontend";
          options = [ "NOPASSWD" ];
        }
      ];
    } ];

  networking.hostName = "castor";
}
