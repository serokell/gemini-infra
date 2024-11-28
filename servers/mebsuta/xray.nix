{ config, lib, pkgs, ... }:

let
  vs = config.vault-secrets.secrets;
  dataDir = "/var/lib/xray";
  xrayPort = 9433;
  xrayPortAlt = 9434;
in
{
  networking.firewall.allowedTCPPorts = [
    xrayPort xrayPortAlt
  ];
  users.users.xray = {
    isSystemUser = true;
    group = "xray";
    home = dataDir;
    createHome = true;
  };
  users.groups.xray = {};
  vault-secrets.secrets.xray = {
    user = "xray";
    group = "xray";
  };
  services.xray = {
    enable = true;
    settingsFile = "${dataDir}/config.json";
  };
  systemd.services.xray = let
    privateKeyPlaceholder = "<private-key>";
    clientIdPlaceholder = "<client-id>";
    shortIdPlaceholder = "<short-id>";
    # Settings file without secrets that is safe to store in /nix/store
    settings = pkgs.writeText "settings-without-secrets" (builtins.toJSON {
      log = {
        loglevel = "warning";
      };
      inbounds = [
        { port = xrayPort;
          protocol = "vless";
          tag = "vless";
          sniffing = {
            enable = true;
            destOverrides = ["http" "tls"];
          };
          settings = {
            clients = [
              {
                id = clientIdPlaceholder;
                flow = "xtls-rprx-vision";
              }
            ];
            decryption = "none";
          };
          streamSettings = {
            network = "tcp";
            security = "reality";
            realitySettings = {
              show = false;
              dest = "serokell.io:443";
              serverNames = [
                "serokell.io"
              ];
              privateKey = privateKeyPlaceholder;
              shortIds = [ shortIdPlaceholder ];
            };
          };
        }
        { port = xrayPortAlt;
          protocol = "vless";
          tag = "vless-alt";
          sniffing = {
            enable = true;
            destOverrides = ["http" "tls"];
          };
          settings = {
            clients = [
              {
                id = clientIdPlaceholder;
                flow = "xtls-rprx-vision";
              }
            ];
            decryption = "none";
          };
          streamSettings = {
            network = "tcp";
            security = "reality";
            realitySettings = {
              show = false;
              dest = "vpn.serokell.net:443";
              serverNames = [
                "vpn.serokell.net"
              ];
              privateKey = privateKeyPlaceholder;
              shortIds = [ shortIdPlaceholder ];
            };
          };
        }
      ];
      outbounds = [
        { protocol = "freedom";
          tag = "direct";
        }
        { protocol = "blackhole";
          tag = "block";
        }
        # IPv4-only outbound for Google
        { tag = "IPv4";
          protocol = "freedom";
          settings = {
            domainStrategy = "UseIPv4";
          };
        }
      ];
      routing = {
        domainStrategy = "IPIfNonMatch";
        domainMatcher = "hybrid";
        # Force IPv4 for Google, otherwise it keeps giving 403
        rules = [
          { type = "field";
            outboundTag = "IPv4";
            domain = [ "geosite:google" ];
          }
        ];
        balancers = [];
      };
    });
  in {
    # Add secrets from Vault to the config file
    preStart = ''
      cp --no-preserve=mode "${settings}" "${config.services.xray.settingsFile}"
      private_key="$(cat "${vs.xray}/private-key")"
      client_id="$(cat "${vs.xray}/client-id")"
      short_id="$(cat "${vs.xray}/short-id")"
      ${pkgs.gnused}/bin/sed -i -e "s/${privateKeyPlaceholder}/$private_key/g" -e "s/${clientIdPlaceholder}/$client_id/g" -e "s/${shortIdPlaceholder}/$short_id/g" \
        "${config.services.xray.settingsFile}"
    '';
    serviceConfig = {
      # In nixpkgs this service uses DynamicUser=true. However, this doesn't work with vault-secrets because the user that needs
      # to read secrets is not know in prior.
      DynamicUser = lib.mkForce "false";
      User = "xray";
      Group = "xray";
      ReadWritePaths = [ "/var/lib/xray" ];
    };
  };
}
