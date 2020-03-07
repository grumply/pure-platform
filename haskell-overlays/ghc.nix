{ haskellLib }:

self: super: { 
  Cabal = self.callHackage "Cabal" "3.0.0.0" {};
  cabal-install = self.callHackage "cabal-install" "3.0.0.0" {};
}
