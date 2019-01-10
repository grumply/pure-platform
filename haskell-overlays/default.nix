{ lib
, haskellLib
, nixpkgs, fetchFromGitHub
, hackGet
}:

rec {
  ghc = import ./ghc.nix { inherit haskellLib; };

  ghcjs = import ./ghcjs.nix {
    inherit haskellLib nixpkgs fetchFromGitHub hackGet;
  };
}