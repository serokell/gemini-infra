{ stdenv, fetchFromGitHub, php, c4, ... }:
stdenv.mkDerivation rec {
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
}
