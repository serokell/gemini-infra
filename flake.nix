{
  description = "NixOS systems for internal services";

  nixConfig = {
    flake-registry = "https://github.com/serokell/flake-registry/raw/master/flake-registry.json";
  };

  inputs = {
    nixpkgs-new.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-compat = {
      flake = false;
    };
    hermetic.url = "github:serokell/hermetic";
    stevenblack-hosts = {
      url = "github:StevenBlack/hosts/3.7.1";
      flake = false;
    };
    composition-c4.url = "github:fossar/composition-c4";
    subspace = {
      url = "github:serokell/subspace";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-new, serokell-nix, deploy-rs, flake-utils, vault-secrets
    , composition-c4, ... }@inputs:
    let
      inherit (nixpkgs.lib) filterAttrs const recursiveUpdate;
      inherit (builtins) readDir mapAttrs;
      allOverlays = [
        serokell-nix.overlay
        vault-secrets.overlay
        composition-c4.overlay
        self.overlay
      ];
      system = "x86_64-linux";
      servers = mapAttrs (path: _: import (./servers + "/${path}"))
        (filterAttrs (_: t: t == "directory") (readDir ./servers));
      mkSystem = nixpkgs: config:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ config ./common.nix { nixpkgs.overlays = allOverlays; } ];
          specialArgs = {
            inputs = inputs;
            libPath = toString ./lib;
          };
        };

      terraformFor = pkgs: pkgs.terraform.withPlugins (p: with p; [ aws vault hcloud ]);

      vpcModule = builtins.fetchGit {
        url = "git+ssh://git@github.com/terraform-aws-modules/terraform-aws-vpc.git";
        rev = "96d22b8c39a918d163657c31adfa60b1f3f9e4b5";
      };
    in {
      nixosConfigurations = mapAttrs (const (mkSystem nixpkgs)) servers // {
        propus = mkSystem nixpkgs-new servers.propus;
      };

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
    } // flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = serokell-nix.lib.pkgsWith nixpkgs.legacyPackages.${system} allOverlays;
        terraform = terraformFor pkgs;
        # Terraform doesn't expose any other binaries, so that works
        terraform-pinned = pkgs.writeScriptBin "terraform" ''
          mkdir -p $PWD/terraform/.terraform_nix/modules/
          rm -rf $PWD/terraform/.terraform_nix/modules/vpc
          ln -s ${vpcModule} $PWD/terraform/.terraform_nix/modules/vpc
          ${terraform}/bin/terraform "$@"
        '';
      in {
        packages = { inherit (pkgs.extend self.overlay) mtg suitecrm; };

        devShell = pkgs.mkShell {
          VAULT_ADDR = "https://vault.serokell.org:8200";
          SSH_OPTS = "${builtins.concatStringsSep " " self.deploy.sshOpts}";
          buildInputs = [
            deploy-rs.packages.${system}.deploy-rs
            pkgs.vault
            (pkgs.vault-push-approle-envs self)
            (pkgs.vault-push-approles self)
            terraform-pinned
            pkgs.nixUnstable
            pkgs.aws
          ];
        };

        checks = deploy-rs.lib.${system}.deployChecks self.deploy // {
          trailing-whitespace = pkgs.build.checkTrailingWhitespace ./.;
          terraform = pkgs.runCommand "terraform-check" {
            src = ./terraform;
            buildInputs = [ terraform ];
          } ''
            terraform init -backend=false
            terraform validate
            touch $out
          '';
        };
      });
}
