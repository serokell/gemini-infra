{ pkgs, lib, libPath, ... }:
let
  inherit (builtins) toJSON;
  inherit (lib) recursiveUpdate;
  inherit (pkgs) writeText;
  defaultConfig = import "${libPath}/common/edna/backend-config.nix";
  configFile = writeText "config.yaml" (toJSON (recursiveUpdate defaultConfig {
    db.initialisation.mode = "enable";
  }));
in
{
  virtualisation.oci-containers.containers.backend.volumes = [
    "${configFile}:/config.yaml:ro"
  ];

  services.nginx.virtualHosts.edna.serverAliases = [ "demo.edna.serokell.team" ];
}
