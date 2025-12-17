{ config, lib, pkgs, ... }:
let
  cors-proxy = pkgs.buildNpmPackage {
    name = "cors-proxy";
    npmDepsHash = "sha256-csWMR3cHLrdePxaOMnwWeohP/zYaNaHuA+myx43zERg=";
    src = pkgs.fetchFromGitHub {
      owner = "isomorphic-git";
      repo = "cors-proxy";
      # v2.7.1
      rev = "1b1c91e71d946544d97ccc7cf0ac62b859e03311";
      sha256 = "sha256-YnSYVeq9Irc2QexvSuE7wq+hi8OGZhlLE2JlbRqzMi4=";
    };
    dontNpmBuild = true;
    postInstall = ''
      # Remove broken symlinks in node_modules/.bin before fixupPhase checks them
      find $out/lib/node_modules/@isomorphic-git/cors-proxy/node_modules/.bin \
        -type l ! -exec test -e {} \; -delete 2>/dev/null || true

      wrapProgram $out/bin/@isomorphic-git/cors-proxy --prefix PATH : ${pkgs.lib.makeBinPath (with pkgs; [ nodejs_24 ])}
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
        ${cfg.package}/bin/@isomorphic-git/cors-proxy start
      '';
      startLimitBurst = 5;
      startLimitIntervalSec = 300;
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = 10;
      };
      environment = {
        PORT = toString cfg.port;
        ALLOW_ORIGIN = cfg.allowOrigin;
      };
    };
  };
}
