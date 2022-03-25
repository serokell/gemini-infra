{ config, pkgs, lib, options, inputs, ... }:
let
  swampwalk-profile = "/nix/var/nix/profiles/per-user/deploy/swampwalk";
  swampwalk-frontend-profile = "/nix/var/nix/profiles/per-user/deploy/swampwalk-frontend";

  swampwalk2-profile = "/nix/var/nix/profiles/per-user/deploy/swampwalk2";
  swampwalk2-frontend-profile = "/nix/var/nix/profiles/per-user/deploy/swampwalk2-frontend";
in
{
  nix.nixPath = options.nix.nixPath.default ++ [ "nixpkgs-overlays=/etc/nix/overlays.nix" ];
  environment.etc."nix/overlays.nix".source = "${./overlays.nix}";
  nixpkgs.overlays = import ./overlays.nix;

  serokell-users = {
    wheelUsers = [ "sweater" ];
    regularUsers = [ "slowpnir" "diogo" ];
  };

  environment.systemPackages = with pkgs; [
    stack
    git
    htop
    nnn
    vim
    rsync
    tmux
    python
    rebar3
    elixir
    erlang
    cargo
    gcc
  ];

  systemd.services.swampwalk = {
    wantedBy = [ "multi-user.target" ];
    environment.TODO_SWAMP_1_BASE_PATH = "/home/share";
    environment.NIX_PATH = builtins.concatStringsSep ":" (options.nix.nixPath.default ++ [ "nixpkgs-overlays=/etc/nix/overlays.nix" ]);
    path = [ "/run/wrappers" ];
    serviceConfig = {
      Restart = "on-failure";
      User = "sweater";
      Group = "users";
      ExecStart = "${swampwalk-profile}/bin/swampwalk-server";
    };
  };

  systemd.services.swampwalk2 = {
    wantedBy = [ "multi-user.target" ];
    environment.TODO_SWAMP_2_BASE_PATH = "/home/share2";
    environment.NIX_PATH = builtins.concatStringsSep ":" config.nix.nixPath;
    path = [ "/run/wrappers" ];
    serviceConfig = {
      Restart = "on-failure";
      User = "sweater";
      Group = "users";
      ExecStart = "${swampwalk2-profile}/bin/swampwalk-server";
    };
  };

  users.users.deploy = {
    isSystemUser = true;
    useDefaultShell = true;

    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA1MvqWKMAejgaBfm0mXqwRK7QZ6NNOzCGj9aX+tiiow" ];

    group = "deploy";
  };

  users.groups.deploy = {};

  security.sudo.extraRules = [{
    users = [ "deploy" ];
    commands = [
      { command = "/run/current-system/sw/bin/systemctl restart swampwalk";
        options = [ "NOPASSWD" ]; }
      { command = "/run/current-system/sw/bin/systemctl restart swampwalk2";
        options = [ "NOPASSWD" ]; }
    ];
  }];

  # add swampwalk-related executables to PATH
  environment.variables.PATH = "${swampwalk-profile}/bin";

  services.nginx = {
    enable = true;
    openFirewall = true;
    addSecurityHeaders = false;
    virtualHosts = {
      swampwalk = {
        forceSSL = true;
        enableACME = true;

        serverName = with config.networking; "${hostName}.${domain}";
        serverAliases = [ "tt.serokell.io" ];

        locations."/" = {
          root = swampwalk-frontend-profile;
          tryFiles = "$uri /index.html =404";
        };

        locations."/api/ws/" = {
          proxyPass = "http://127.0.0.1:9160/";
          proxyWebsockets = true;
        };

        locations."/api/v0/" = {
          proxyPass = "http://127.0.0.1:8000/";
        };
      };

      swampwalk2 = {
        forceSSL = true;
        enableACME = true;

        serverName = "tt2.serokell.io";

        locations."/" = {
          root = swampwalk2-frontend-profile;
          tryFiles = "$uri /index.html =404";
        };

        locations."/api/ws/" = {
          proxyPass = "http://127.0.0.1:9161/";
          proxyWebsockets = true;
        };

        locations."/api/v0/" = {
          proxyPass = "http://127.0.0.1:9001/";
        };
      };
    };
  };

  vault-secrets.secrets.oauth2_proxy.environmentVariableNamePrefix = "OAUTH2_PROXY";
  services.oauth2_proxy = {
    enable = true;

    # contains oauth2 client id, oauth2 client secret, and a cookie secret seed for signing cookies
    keyFile = "${config.vault-secrets.secrets.oauth2_proxy}/environment";

    requestLogging = false; # don't log each request
    redirectURL = "https://tt.serokell.io/oauth2/callback"; # callback url for the auth provider
    email.domains = [ "serokell.io" ]; # only allow users with '@serokell.io' email address
    extraConfig.whitelist-domain = [ "tt.serokell.io" "tt2.serokell.io" ]; # allowed domains to redirect to after authentication
    cookie.domain = "serokell.io"; # domain to set cookie for after authentication
    nginx.virtualHosts = [ "swampwalk" "swampwalk2" ]; # vhosts to use the proxy for

    # default cookie name '_oauth2_proxy' is used by jupiter for
    # all '.serokell.io' subdomains, use a different name for tt
    cookie.name = "_oauth2_proxy_tt";
  };

  users.users.oauth2_proxy.group = "oauth2_proxy";
  users.groups.oauth2_proxy = {};
}
