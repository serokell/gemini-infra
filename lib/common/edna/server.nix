{pkgs, lib, config, ...}:
  let
    inherit (builtins) toJSON;
    inherit (pkgs) writeText;

    vs = config.vault-secrets.secrets;
    profile = "/nix/var/nix/profiles/per-user/deploy/edna-docker";
  in
  {
    networking.firewall.allowedTCPPorts = [ 80 443 ];

    vault-secrets.secrets.docker-backend.quoteEnvironmentValues = false;

    virtualisation.docker = {
      enable = true;
      logLevel = "warn";
      storageDriver = "overlay2";
      networks.edna = {};
    };

    virtualisation.oci-containers.containers = let
      commonOptions = {
        extraOptions = [
          # Put all nodes on the same private network
          "--network=edna"

          # PostgreSQL during initdb
          "--shm-size=256MB"
        ];
      };

    in
    {
      frontend = {
        image = "ghcr.io/serokell/edna-frontend";
        imageFile = "${profile}/frontend.tar.gz";

        ports = [
          "8080:80"
        ];
      } // commonOptions;

      backend = {
        image = "ghcr.io/serokell/edna-backend";
        imageFile = "${profile}/backend.tar.gz";
        dependsOn = [ "postgres" ];

        environmentFiles = [ "${vs.docker-backend}/environment" ];

        cmd = [
          "-c" "/config.yaml"
        ];
      } // commonOptions;

      postgres = let
        datadir = "/var/lib/postgresql/data/pgdata";
        pginit = writeText "init.sql"
        ''
          CREATE DATABASE edna;
        '';
      in
      {
        image = "postgres";
        volumes = [
          "/root/pgdata:${datadir}"
          "${pginit}:/docker-entrypoint-initdb.d/init.sql"
        ];

        environment = {
          PGDATA = datadir;
          POSTGRES_PASSWORD = "12345";
          POSTGRES_USER = "postgres";
        };
      } // commonOptions;
    };

    services.nginx.enable = true;
    services.nginx.virtualHosts.edna = {
      default = true;

      serverName = with config.networking; "${hostName}.${domain}";
      enableACME = true;
      forceSSL = true;

      locations."/".proxyPass = "http://localhost:8080/";
    };
  }
