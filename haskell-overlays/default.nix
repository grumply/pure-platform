{ lib
, haskellLib
, nixpkgs, fetchFromGitHub
, hackGet
}:

rec {
  disableTemplateHaskell = import ./disable-template-haskell.nix {
    inherit haskellLib fetchFromGitHub;
  };
  exposeAllUnfoldings = import ./expose-all-unfoldings.nix { };

  ghc = import ./ghc.nix { inherit haskellLib; };

  ghcjs = import ./ghcjs.nix {
    inherit haskellLib nixpkgs fetchFromGitHub hackGet;
  };
}