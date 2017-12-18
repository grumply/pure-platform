{ haskellLib }:

self: super: {
  cabal-doctest = null;
  cabal-macosx = null;
  mkDerivation = drv: super.mkDerivation (drv // {
    doHaddock = false;
    enableSharedLibraries = false;
    enableSharedExecutables = false;
  });
}
