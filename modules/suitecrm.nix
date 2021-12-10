{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.services.suitecrm;

  phpFpmAddress =
    if cfg.phpFpmAddress == null then
      config.services.phpfpm.pools.suitecrm.socket
    else
      cfg.phpFpmAddress;
in
{
  options.services.suitecrm = {
    enable = mkEnableOption
      "Enable SuiteCRM service, WARNING: will hijack the nginx service's suitecrm location.";

    suitecrmPackage = mkOption {
      type = with types; package;
      description = ''
        A package of SuiteCRM transformed with <literal>composer install --no-scripts</literal>.
        <literal>--no-scripts</literal> is neccessary because a post-install tries to delete some
        unused parts of dependencies, which are already in the store.
      '';
    };

    setupDatabase = mkOption {
      type = types.bool;
      description = ''
        Whether to setup a MySQL database automatically or not.
      '';
      default = true;
    };

    phpFpmAddress = mkOption {
      type = with types; nullOr str;
      description = ''
        If <literal>null</literal> a php-fpm pool will be setup automatically, if not
        <literal>null</literal> the at the specified address will be used.
      '';
      default = null;
    };
  };

  config = mkIf cfg.enable {
    users.users.suitecrm = {
      isSystemUser = true;
      home = "/var/www/suitecrm";
      group = "suitecrm";
    };

    users.groups.suitecrm = {
      gid = 1024;
    };

    systemd.services.suitecrm =
      { before = [ "phpfpm-suitecrm.service" ];
        wantedBy = [ "multi-user.target" ];
        script =
          ''
            set -xe

            _www_dir="/var/www/suitecrm"
            _base_dir="/var/suitecrm"
            _persist_folders=("custom" "themes" "data" "upload")

            mkdir -p "$_www_dir"
            if ! [[ -f "$_www_dir/.first_run" ]]
            then
              touch "$_www_dir/.first_run"

              mkdir -p "$_www_dir"
              cp -Raf "${cfg.suitecrmPackage}/." "$_www_dir/"

              mkdir -p $_base_dir
              for dir in ''${_persist_folders[@]}
              do
                  mkdir -p "$_base_dir/$dir"
                  cp -Raf "${cfg.suitecrmPackage}/$dir/." "$_base_dir/$dir/"
                  rm -r "$_www_dir/$dir"
                  ln -s "$_base_dir/$dir" "$_www_dir/$dir"
              done

              touch "$_base_dir/config.php"
              ln -s "$_base_dir/config.php" "$_www_dir/config.php"
            fi

            chown suitecrm:nginx -R "$_www_dir" "$_base_dir"
            chmod u=rwX,g=rwX,o=rX -R /var/www "$_base_dir"
          '';

        serviceConfig.Type = "oneshot";
      };

    services.mysql = mkIf cfg.setupDatabase {
      enable = true;

      ensureUsers =
        [ { name = "suitecrm";
            ensurePermissions = {
              "suitecrm.*" = "ALL PRIVILEGES";
            };
          }
        ];

      ensureDatabases =
        [ "suitecrm"
        ];
    };


    services.nginx = {
      enable = true;
      virtualHosts.suitecrm = {
        locations."/" = {
          index = "index.php";
          root = "/var/www/suitecrm";
        };

        locations."~ [^/]\.php(/|$)" = {
          root = "/var/www/suitecrm";
          extraConfig = ''
          fastcgi_split_path_info ^(.+?\.php)(/.*)$;
          if (!-f $document_root$fastcgi_script_name) {
              return 404;
          }

          include ${pkgs.nginx}/conf/fastcgi_params;
          fastcgi_index index.php;
          fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
          fastcgi_pass unix:${phpFpmAddress};
        '';
        };
      };
    };

    services.phpfpm = mkIf (cfg.phpFpmAddress == null) {
      pools.suitecrm = {
        user = "suitecrm";
        group = "nginx";

        phpPackage = pkgs.php74.withExtensions ({ all, ... }: with all;
          [ curl
            intl
            json
            gd
            mbstring
            mysqli
            pdo_mysql
            openssl
            soap
            xml
            zip
            zlib
            imap
            session
            ldap
            pdo
          ]);

        settings = {
          "pm" = "dynamic";
          "pm.max_children" = 75;
          "pm.start_servers" = 10;
          "pm.min_spare_servers" = 5;
          "pm.max_spare_servers" = 20;
          "pm.max_requests" = 500;

          "listen.owner" = "nginx";

        };
        phpOptions = ''
            upload_max_filesize = 20M
            post_max_size = 21M
        '';
    };
  };
  };
}
