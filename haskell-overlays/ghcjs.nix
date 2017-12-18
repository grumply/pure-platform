{ haskellLib, nixpkgs, fetchFromGitHub }:

self: super: {
  ghcWithPackages = selectFrom: self.callPackage (nixpkgs.path + "/pkgs/development/haskell-modules/with-packages-wrapper.nix") {
    inherit (self) llvmPackages;
    haskellPackages = self;
    packages = selectFrom self;
  };

  ghcjs-base = haskellLib.doJailbreak (self.callCabal2nix "ghcjs-base" (fetchFromGitHub {
    owner = "ghcjs";
    repo = "ghcjs-base";
    rev = "43804668a887903d27caada85693b16673283c57";
    sha256 = "1pqmgkan6xhpvsb64rh2zaxymxk4jg9c3hdxdb2cnn6jpx7jsl44";
  }) {});

  ghc = super.ghc // {
    withPackages = self.ghcWithPackages;
  };

  diagrams-lib = haskellLib.dontCheck super.diagrams-lib;

}
