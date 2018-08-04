{ haskellLib, nixpkgs, fetchFromGitHub }:

self: super: {
  ghcWithPackages = selectFrom: self.callPackage (nixpkgs.path + "/pkgs/development/haskell-modules/with-packages-wrapper.nix") {
    inherit (self) llvmPackages;
    haskellPackages = self;
    packages = selectFrom self;
  };

  ghcjs-base = haskellLib.doJailbreak (haskellLib.appendPatch (self.callCabal2nix "ghcjs-base" (fetchFromGitHub {
    owner = "ghcjs";
    repo = "ghcjs-base";
    rev = "92bfcf42ffddb9676c4e288efd5750a06c4f4799";
    sha256 = "14ndxrp2xsa0jz75zdaiqylbkzq8p7afg78vv418mv2c497rj08z";
  }) {}) ./ghcjs-base.patch);

  ghc = super.ghc // {
    withPackages = self.ghcWithPackages;
  };

  # doctest doesn't work on ghcjs, but sometimes dontCheck doesn't seem to get rid of the dependency
  doctest = builtins.trace "Warning: ignoring dependency on doctest" null;
}
