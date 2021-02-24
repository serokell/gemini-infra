[
  (self: super:
    let
      ghc864 = self.callPackage (import
        (builtins.fetchTarball
          { url = "https://github.com/nixos/nixpkgs-channels/archive/nixos-19.03.tar.gz"; sha256 = "11z6ajj108fy2q5g8y4higlcaqncrbjm3dnv17pvif6avagw4mcb"; })
        {
          overlays = [ ];
        }).haskell.compiler.ghc864.override
        { };
    in
    {
      haskell = super.haskell // {
        compiler = super.haskell.compiler // { inherit ghc864; };
      };
    })
]
