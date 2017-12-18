{ haskellLib }:

self: super: {
  mkDerivation = drv: super.mkDerivation (drv // {
    enableSplitObjs = false; # Split objects with template haskell doesn't work on ghc 7.8
  });
  bifunctors = haskellLib.dontHaddock super.bifunctors;
}
