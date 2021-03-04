{
  description = "NixOS systems for internal services";

  inputs = {
    nixpkgs.url = "github:serokell/nixpkgs";
    serokell-nix.url = "github:serokell/serokell.nix";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    deploy-rs.url = "github:serokell/deploy-rs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, serokell-nix, deploy-rs, flake-utils, ... }@inputs:
    let
      inherit (nixpkgs.lib) nixosSystem filterAttrs const recursiveUpdate;
      inherit (builtins) readDir mapAttrs;
      system = "x86_64-linux";
      servers = mapAttrs (path: _: import (./servers + "/${path}"))
        (filterAttrs (_: t: t == "directory") (readDir ./servers));
      mkSystem = config:
        nixosSystem {
          inherit system;
          modules = [ config ./common.nix ];
          specialArgs.inputs = inputs;
        };

      terraformFor = pkgs: pkgs.terraform.withPlugins (p: with p; [ aws ]);
    in {
      nixosConfigurations = mapAttrs (const mkSystem) servers;

      nixosModules = import ./modules;

      overlay = import ./packages;

      deploy.magicRollback = true;
      deploy.autoRollback = true;

      deploy.nodes = mapAttrs (_: nixosConfig: {
        hostname =
          "${nixosConfig.config.networking.hostName}.${nixosConfig.config.networking.domain}";
        sshOpts = [ "-p" "17788" ];

        profiles.system.user = "root";
        profiles.system.path =
          deploy-rs.lib.${system}.activate.nixos nixosConfig;
      }) self.nixosConfigurations;
    } // flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let pkgs = nixpkgs.legacyPackages.${system}.extend serokell-nix.overlay;
      in {

        packages = {
          inherit (pkgs.extend self.overlay) mtg;
        };

        devShell = pkgs.mkShell {
          buildInputs = [
            deploy-rs.packages.${system}.deploy-rs
            (terraformFor pkgs)
            pkgs.nixUnstable
          ];
        };

        checks = deploy-rs.lib.${system}.deployChecks self.deploy // {
          trailing-whitespace = pkgs.build.checkTrailingWhitespace ./.;
          # FIXME VPC provider is not packaged
          # terraform = pkgs.runCommand "terraform-check" {
          #   src = ./terraform;
          #   buildInputs = [ (terraformFor pkgs) ];
          # } ''
          #   cp -r $src ./terraform
          #   terraform init -backend=false terraform
          #   terraform validate terraform
          #   touch $out
          # '';
        };
      });
}
