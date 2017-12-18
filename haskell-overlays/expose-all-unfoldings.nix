{ }:

self: super: {
  mkDerivation = drv: super.mkDerivation (drv // {
    configureFlags = (drv.configureFlags or []) ++ [
      "--${if self.ghc.isGhcjs or false then "ghcjs" else "ghc"}-options=-fexpose-all-unfoldings"
    ];
  });
}
