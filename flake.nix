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

    nix-npm-buildpackage.url = "github:serokell/nix-npm-buildpackage";
    tzbot.url = "github:serokell/tzbot";
  };

  outputs = { self, nix, nixpkgs, serokell-nix, deploy-rs, flake-utils, vault-secrets
    , composition-c4, nix-npm-buildpackage, ... }@inputs:
    let
      inherit (nixpkgs.lib) nixosSystem filterAttrs const recursiveUpdate;
      inherit (builtins) readDir mapAttrs attrNames;

      allOverlays = [
        serokell-nix.overlay
        vault-secrets.overlay
        composition-c4.overlays.default
        self.overlay
        nix-npm-buildpackage.overlays.default
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

      overlay = import ./packages;

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
        pkgs = serokell-nix.lib.pkgsWith nixpkgs.legacyPackages.${system} allOverlays;

        vpcModule = builtins.fetchGit {
          url = "https://github.com/terraform-aws-modules/terraform-aws-vpc.git";
          rev = "e02118633f268ff1f86021a8fa9f3afcd1c37d85";
        };

        terraform = pkgs.terraform.withPlugins (p: with p; [ aws vault hcloud ]);
        # Terraform doesn't expose any other binaries, so that works
        terraform-pinned = pkgs.writeScriptBin "terraform" ''
          terraformNixDir=".terraform_nix/modules"
          if [ -d "terraform" ]; then
            terraformNixDir="terraform/$terraformNixDir"
          fi

          mkdir -p "$terraformNixDir"
          rm -rf "$terraformNixDir/vpc"
          ln -s ${vpcModule} "$terraformNixDir/vpc"

          ${terraform}/bin/terraform "$@"
        '';
      in {
        packages = { inherit (pkgs.extend self.overlay) mtg; };

        devShell = self.devShells.${system}.default;
        devShells.default = pkgs.mkShell {
          VAULT_ADDR = "https://vault.serokell.org:8200";
          SSH_OPTS = "${builtins.concatStringsSep " " self.deploy.sshOpts}";
          buildInputs = [
            deploy-rs.packages.${system}.deploy-rs
            pkgs.vault
            (pkgs.vault-push-approle-envs self)
            (pkgs.vault-push-approles self)
            terraform-pinned
            nix.packages.${system}.nix
            pkgs.awscli
          ];
        };

        # used in GitHub pipeline
        server-matrix = mkMatrix "server" servers;
        check-matrix = mkMatrix "check" self.checks.${system};

        checks = deploy-rs.lib.${system}.deployChecks self.deploy // {
          trailing-whitespace = pkgs.build.checkTrailingWhitespace ./.;
          terraform = pkgs.runCommand "terraform-check" {  } ''
            cp -r ${./terraform}/. .
            ${terraform-pinned}/bin/terraform init -backend=false
            ${terraform-pinned}/bin/terraform validate
            touch $out
          '';

          inherit (self.packages.${system}) mtg;
        };
      });
}
