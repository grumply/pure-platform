{ haskellLib
, nixpkgs, jdk, fetchFromGitHub
, stage2Script
}:

rec {
  disableTemplateHaskell = import ./disable-template-haskell.nix {
    inherit haskellLib fetchFromGitHub;
  };
  ghc = import ./ghc.nix { inherit haskellLib stage2Script; };
  ghc-8 = nixpkgs.lib.composeExtensions
    ghc
    (import ./ghc-8.x.y.nix { });
  ghc-8_2_1 = nixpkgs.lib.composeExtensions
    ghc-8
    (import ./ghc-8.2.1.nix { inherit haskellLib fetchFromGitHub; });
  ghc-head = nixpkgs.lib.composeExtensions
    ghc-8
    (import ./ghc-head.nix { inherit haskellLib fetchFromGitHub; });

  ghcjs = import ./ghcjs.nix {
    inherit haskellLib nixpkgs fetchFromGitHub;
  };
  android = import ./android { inherit haskellLib; inherit (nixpkgs) jdk; };
  ios = import ./ios.nix { inherit haskellLib; };
}
