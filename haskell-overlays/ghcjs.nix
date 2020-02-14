{ haskellLib, nixpkgs, fetchFromGitHub, hackGet }:

with haskellLib;

self: super: {
  ghcWithPackages = selectFrom: self.callPackage (nixpkgs.path + "/pkgs/development/haskell-modules/with-packages-wrapper.nix") {
    inherit (self) llvmPackages;
    packages = selectFrom self;
  };

 ghcjs-base = overrideCabal (self.callCabal2nix "ghcjs-base" (fetchFromGitHub {
    owner = "ghcjs";
    repo = "ghcjs-base";
    rev = "6be0e992e292db84ab42691cfb172ab7cd0e709e";
    sha256 = "0nk7a01lprf40zsiph3ikwcqcdb1lghlj17c8zzhiwfmfgcc678g";
  }) {}) (drv: {
    jailbreak = true;
    doCheck = false; #TODO: This should be unnecessary
    patches = (drv.patches or []) ++ [./ghcjs-base.patch];
  });

  ghc = super.ghc // {
    withPackages = self.ghcWithPackages;
  };

  # doctest doesn't work on ghcjs, but sometimes dontCheck doesn't seem to get rid of the dependency
  doctest = builtins.trace "Warning: ignoring dependency on doctest" null;

  cereal = dontCheck super.cereal;

  tagsoup = dontCheck super.tagsoup;

}
