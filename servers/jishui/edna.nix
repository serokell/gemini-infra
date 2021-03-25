{ pkgs, lib, config, libPath, ... }:
let
  inherit (builtins) toJSON;
  inherit (lib) recursiveUpdate;
  inherit (pkgs) writeText;

  vs = config.vault-secrets.secrets;

  defaultConfig = import "${libPath}/common/edna/backend-config.nix";
  configFile = writeText "config.yaml" (toJSON (recursiveUpdate defaultConfig {
    db.initialisation.mode = "enable";
  }));
in
{
  virtualisation.oci-containers.containers.backend.volumes = [
    "${configFile}:/config.yaml:ro"
  ];

  vault-secrets.secrets.nginx = {
    secretsAreBase64 = true;
    user = "nginx";
  };

  services.nginx.virtualHosts.edna = {
    basicAuthFile = "${vs.nginx}/edna.htpasswd";
    serverAliases = [ "demo.edna.serokell.team" ];
  };
}
