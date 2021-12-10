{ modulesPath, inputs, config, pkgs, ... }:
{
  imports = [
    inputs.serokell-nix.nixosModules.ec2
    inputs.hermetic.nixosModules.hermetic
    inputs.self.nixosModules.suitecrm
  ];

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  nixpkgs.overlays = [ inputs.composition-c4.overlay ];

  services.nginx.virtualHosts.suitecrm = {
      serverName = "suitecrm.serokell.team";
      default = true;

      enableACME = true;
      forceSSL = true;
    };

  services.suitecrm =
    { enable = true;
      suitecrmPackage = with pkgs; stdenv.mkDerivation rec {
        pname = "SuiteCRM";
        version = "7.12.1";

        src = fetchFromGitHub {
          owner = "salesagility";
          repo = "SuiteCRM";
          rev = "v" + version;
          sha256 = "sha256-7Zbr+5COkanJd9CLOtX11dz4i/enhFW9FrrA2i8sw4E=";
        };

        composerDeps = c4.fetchComposerDeps {
          inherit src;
        };

        nativeBuildInputs = [
          php.packages.composer
          c4.composerSetupHook
        ];

        installPhase = ''
          runHook preInstall

          composer install --no-scripts
          cp -r . $out

          runHook postInstall
        '';
      };
    };

  networking.hostName = "pollux";
  wireguard-ip-address = "172.21.0.33";
}
