{ config, pkgs, lib, options, inputs, ... }:
let
  swampwalk2-profile = "/nix/var/nix/profiles/per-user/deploy/swampwalk2";
  swampwalk2-frontend-profile = "/nix/var/nix/profiles/per-user/deploy/swampwalk2-frontend";
in
{
  nix.nixPath = options.nix.nixPath.default ++ [ "nixpkgs-overlays=/etc/nix/overlays.nix" ];
  environment.etc."nix/overlays.nix".source = "${./overlays.nix}";
  nixpkgs.overlays = import ./overlays.nix;

  serokell-users = {
    wheelUsers = [ "sweater" "lierdakil" ];
    regularUsers = [ "diogo" "dmozhevitin" ];
  };

  environment.systemPackages = with pkgs; [
    stack
    git
    htop
    nnn
    vim
    rsync
    tmux
    python3
    rebar3
    elixir
    erlang
    cargo
    gcc
  ];

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

      # hardening options
      CapabilityBoundingSet = [
        "CAP_CHOWN"
        "CAP_SETUID"
        "CAP_SETGID"
        "CAP_FOWNER"
        "CAP_DAC_OVERRIDE"
      ];
      AmbientCapabilities = [ "" ];
      DeviceAllow = "no";
      KeyringMode = "private";
      NotifyAccess = "none";
      PrivateMounts = "yes";
      PrivateTmp = "yes";
      ProtectControlGroups = "yes";
      ProtectProc = "invisible";
      SupplementaryGroups = [ "" ];
      Delegate = "no";
      RemoveIPC = "yes";
      UMask = "0027";
      ProcSubset = "pid";
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
      { command = "/run/current-system/sw/bin/systemctl restart swampwalk2";
        options = [ "NOPASSWD" ]; }
    ];
  }];

  # add swampwalk-related executables to PATH
  environment.variables.PATH = "${swampwalk2-profile}/bin";

  services.nginx = {
    enable = true;
    openFirewall = true;
    addSecurityHeaders = false;
    virtualHosts = {

      swampwalk2 = {
        forceSSL = true;
        enableACME = true;

        serverName = "tt2.serokell.io";
        serverAliases = [ "tt.serokell.io" ];

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

  vault-secrets.secrets.oauth2_proxy = {
    environmentVariableNamePrefix = "OAUTH2_PROXY";
    services = ["oauth2-proxy"];
  };
  services.oauth2-proxy = {
    enable = true;

    # contains oauth2 client id, oauth2 client secret, and a cookie secret seed for signing cookies
    keyFile = "${config.vault-secrets.secrets.oauth2_proxy}/environment";

    requestLogging = false; # don't log each request
    redirectURL = "https://auth-tt.serokell.io/oauth2/callback"; # callback url for the auth provider
    email.domains = [ "serokell.io" ]; # only allow users with '@serokell.io' email address
    extraConfig.whitelist-domain = [ "tt.serokell.io" "tt2.serokell.io" "auth-tt.serokell.io" ]; # allowed domains to redirect to after authentication
    cookie.domain = "serokell.io"; # domain to set cookie for after authentication
    nginx = {
      virtualHosts = { "swampwalk2" = {}; }; # vhosts to use the proxy for
      domain = "auth-tt.serokell.io";
    };
    # default cookie name '_oauth2_proxy' is used by jupiter for
    # all '.serokell.io' subdomains, use a different name for tt
    cookie.name = "_oauth2_proxy_tt";
  };
  services.nginx.virtualHosts."auth-tt.serokell.io" = {
    serverName = "auth-tt.serokell.io";
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      return = "404";
    };
  };
}
