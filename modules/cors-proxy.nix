{ config, lib, pkgs, ... }:
let
  cors-proxy = (pkgs.extend (self: super: {nodejs = super.nodejs-14_x;})).buildNpmPackage {
    src = pkgs.fetchFromGitHub {
      owner = "isomorphic-git";
      repo = "cors-proxy";
      # v2.7.1
      rev = "1b1c91e71d946544d97ccc7cf0ac62b859e03311";
      sha256 = "sha256-YnSYVeq9Irc2QexvSuE7wq+hi8OGZhlLE2JlbRqzMi4=";
    };
    postInstall = ''
      wrapProgram $out/bin/npm --prefix PATH : ${pkgs.lib.makeBinPath (with pkgs; [ nodejs-14_x ])}
    '';
  };
  cfg = config.services.cors-proxy;
in {
  options.services.cors-proxy = with lib; {
    enable = mkEnableOption "Enable @isomorphic-git/cors-proxy";
    package = mkOption {
      type = types.package;
      default = cors-proxy;
    };
    port = mkOption {
      type = types.int;
      default = 9999;
      description = ''
        The port to listen to.
      '';
    };
    allowOrigin = mkOption {
      type = types.str;
      default = "*";
      description = ''
        The value for the 'Access-Control-Allow-Origin' CORS header.
      '';
    };
  };
  config = lib.mkIf cfg.enable {
    systemd.services.ligo-webide-cors-proxy = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      script = ''
        ${cfg.package}/bin/npm start
      '';
      environment = {
        PORT = toString cfg.port;
        ALLOW_ORIGIN = cfg.allowOrigin;
      };
    };
  };
}
