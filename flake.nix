{
  description = "NixOS systems for the build cluster";

  inputs = {
    nixpkgs.url = "github:serokell/nixpkgs";
    serokell-nix.url = "github:serokell/serokell.nix";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    deploy-rs.url = "github:serokell/deploy-rs";
  };

  outputs = { self, nixpkgs, serokell-nix, deploy-rs, ... }@inputs:
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

      deployChecks =
        mapAttrs (_: lib: lib.deployChecks self.deploy) deploy-rs.lib;

      terraformFor = pkgs: pkgs.terraform.withPlugins (p: with p; [ aws ]);

      checks = mapAttrs (_: pkgs:
        let pkgs' = pkgs.extend serokell-nix.overlay;
        in {
          trailing-whitespace = pkgs'.build.checkTrailingWhitespace ./.;
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
        }) nixpkgs.legacyPackages;
    in {
      nixosConfigurations = mapAttrs (const mkSystem) servers;

      nixosModules = import ./modules;

      overlay = import ./packages;

      packages = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ]
        (system: {
          inherit (nixpkgs.legacyPackages.${system}.extend self.overlay) mtg;
        });

      deploy.magicRollback = true;
      deploy.autoRollback = true;

      deploy.nodes = mapAttrs (_: nixosConfig: {
        hostname =
          "${nixosConfig.config.networking.hostName}.${nixosConfig.config.networking.domain}";
        sshOpts = [ "-p" "17788" ];

        profiles.system.user = "root";
        profiles.system.path = deploy-rs.lib.${system}.activate.nixos nixosConfig;
      }) self.nixosConfigurations;

      devShell = mapAttrs (system: deploy:
        let pkgs = nixpkgs.legacyPackages.${system}.extend serokell-nix.overlay;
        in pkgs.mkShell {
          buildInputs = [ deploy (terraformFor pkgs) pkgs.nixUnstable ];
        }) deploy-rs.defaultPackage;

      checks = recursiveUpdate deployChecks checks;
    };
}
