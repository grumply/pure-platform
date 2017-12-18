{ haskellLib, fetchFromGitHub }:

let
  # TODO upstream into Haskell lib
  dontUseCustomSetup = p: haskellLib.overrideCabal p (drv: {
    preCompileBuildDriver = assert (drv.preCompileBuildDriver or null) == null; ''
      rm Setup.hs || rm Setup.lhs
    '';
  });

in self: super: {
  # Aeson's TH splices refer to names that aren't exported
  aeson = haskellLib.overrideCabal super.aeson (drv: {
    # Export all modules, and some additional functions
    preConfigure = ''
      sed -i '/^library/,/^test-suite/ s/other-modules:/exposed-modules:/' *.cabal
      sed -i "/^module Data.Aeson.TH/,/) where/ { /^module/b; /) where/ { s/) where/, LookupField (..), parseTypeMismatch, parseTypeMismatch', valueConName, keyValuePairWith) where/; b }; }" Data/Aeson/TH.hs
      ${drv.preConfigure or ""}
    '';
  });

  # These custom Setup.lhs files don't work
  distributive = dontUseCustomSetup super.distributive;
  comonad = dontUseCustomSetup super.comonad;
  semigroupoids = dontUseCustomSetup (haskellLib.appendConfigureFlag super.semigroupoids "-f-doctests");

  cryptonite = haskellLib.appendConfigureFlag super.cryptonite "-f-integer-gmp";

  profunctors = haskellLib.overrideCabal super.profunctors (drv: {
    preConfigure = ''
      sed -i 's/^{-# ANN .* #-}$//' src/Data/Profunctor/Unsafe.hs
    '';
  });
  lens = haskellLib.overrideCabal super.lens (drv: {
    preConfigure = ''
      sed -i 's/^{-# ANN .* #-}$//' $(find src -name '*.hs')
    '';
    doCheck = false;
    jailbreak = true;
  });

  pure = super.pure.override {
    useTemplateHaskell = false;
  };
  # TODO: this is probably a good idea too
  #alex = self.ghc.bootPkgs.alex;
  happy = self.ghc.bootPkgs.happy;
}
