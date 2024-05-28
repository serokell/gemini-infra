{
  description = "NixOS systems for internal services";

  nixConfig = {
    flake-registry = "https://github.com/serokell/flake-registry/raw/master/flake-registry.json";
  };

  inputs = {
    nix.url = "github:nixos/nix/2.10-maintenance";
    flake-compat.flake = false;
    hermetic.url = "github:serokell/hermetic";
    stevenblack-hosts = {
      url = "github:StevenBlack/hosts/3.7.1";
      flake = false;
    };
    composition-c4.url = "github:fossar/composition-c4";
    subspace = {
      url = "github:serokell/subspace";
      # subspace fails with
      # subspace-start: line 11: 1607212 Bad system call         (core dumped)
      # with newer nixpkgs
      # inputs.nixpkgs.follows = "nixpkgs";
    };

    tzbot.url = "github:serokell/tzbot";

    tzbot.inputs.serokell-nix.follows = "serokell-nix";

    serokell-nix.inputs.nixpkgs.follows = "nixpkgs";
    vault-secrets.inputs.nixpkgs.follows = "nixpkgs";

    terranix-simple = {
      url = "git+ssh://git@github.com/serokell/terranix-simple";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    terranix.url = "github:terranix/terranix";
    terranix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nix, nixpkgs, serokell-nix, deploy-rs, flake-utils, vault-secrets
    , composition-c4, terranix, terranix-simple, ... }@inputs:
    let
      inherit (nixpkgs.lib) nixosSystem filterAttrs const recursiveUpdate;
      inherit (builtins) readDir mapAttrs attrNames;

      allOverlays = [
        serokell-nix.overlay
        vault-secrets.overlays.default
        composition-c4.overlays.default
        terranix-simple.overlay
      ];

      servers = mapAttrs (path: _: import (./servers + "/${path}"))
        (filterAttrs (_: t: t == "directory") (readDir ./servers));

      system = "x86_64-linux";

      mkSystem = config:
        nixosSystem {
          inherit system;
          modules = [ config ./common.nix { nixpkgs.overlays = allOverlays; } ];
          specialArgs = {
            inputs = inputs;
            libPath = toString ./lib;
          };
        };

      # make a matrix to use in GitHub pipeline
      mkMatrix = name: attrs: {
        include = map (v: { ${name} = v; }) (attrNames attrs);
      };

    in {
      nixosConfigurations = mapAttrs (const mkSystem) servers;

      nixosModules = import ./modules;

      deploy = {
        magicRollback = true;
        autoRollback = true;
        sshOpts = [ "-p" "17788" ];
        nodes = mapAttrs (_: nixosConfig: {
          hostname =
            "${nixosConfig.config.networking.hostName}.${nixosConfig.config.networking.domain}";

          profiles.system.user = "root";
          profiles.system.path =
            deploy-rs.lib.${system}.activate.nixos nixosConfig;
        }) self.nixosConfigurations;
      };
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgsAllowUnfree = import nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg: builtins.elem (pkg.pname) [ "terraform" "vault" ];
        };
        pkgs = serokell-nix.lib.pkgsWith pkgsAllowUnfree allOverlays;

        tfConfigAst = terranix.lib.terranixConfigurationAst {
          inherit system pkgs;
          modules = [
            terranix-simple.terranixModules
            ./terraform/main.nix
            ./terraform/alhena.nix
            ./terraform/alzirr.nix
            ./terraform/castor.nix
            ./terraform/jishui.nix
            ./terraform/mebsuta.nix
            ./terraform/tejat-prior.nix
            ./terraform/wasat.nix
          ];
        };

        tf-lib = serokell-nix.lib.terraform { inherit pkgs tfConfigAst; };

      in {
        devShell = self.devShells.${system}.default;
        devShells.default = pkgs.mkShell {
          VAULT_ADDR = "https://vault.serokell.org:8200";
          SSH_OPTS = "${builtins.concatStringsSep " " self.deploy.sshOpts}";
          buildInputs = [
            deploy-rs.packages.${system}.deploy-rs
            pkgs.vault
            (pkgs.vault-push-approle-envs self)
            (pkgs.vault-push-approles self)
            nix.packages.${system}.nix
            pkgs.awscli
          ];
        };

        # used in GitHub pipeline
        server-matrix = mkMatrix "server" servers;
        check-matrix = mkMatrix "check" self.checks.${system};

        checks = deploy-rs.lib.${system}.deployChecks self.deploy // {
          trailing-whitespace = pkgs.build.checkTrailingWhitespace ./.;
          inherit (tf-lib) tf-validate;
        };

        apps = tf-lib.mkApps ["apply" "plan" "destroy"];
      });
}
