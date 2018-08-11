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
    rev = "01014ade3f8f5ae677df192d7c2a208bd795b96c";
    sha256 = "0qr05m0djll3x38dhl85pl798arsndmwfhil8yklhb70lxrbvfrs";
  }) {}) (drv: {
    jailbreak = true;
    doCheck = false; #TODO: This should be unnecessary
    patches = (drv.patches or []) ++ [./ghcjs-base.patch];
  });

  ghc = super.ghc // {
    withPackages = self.ghcWithPackages;
  };

  hlint = null;
  hscolour = null;
  cabal-macosx = null;

  #TODO: These look like real test failures:
  aeson = dontCheck super.aeson;
  # Also, pureMD5 is failing

  #TODO: The following packages' tests fail with errors like this:
  # Error: Cannot find module '/tmp/nix-build-hspec-discover-2.4.4.drv-0/hspec-discover-2.4.4/var h$currentThread = null;'
  hspec-core = dontCheck super.hspec-core;
  hspec-discover = dontCheck super.hspec-discover;
  hspec = dontCheck super.hspec;
  bifunctors = dontCheck super.bifunctors;
  base-compat = dontCheck super.base-compat;
  generic-deriving = dontCheck super.generic-deriving;
  newtype-generics = dontCheck super.newtype-generics;
  lens = disableCabalFlag (dontCheck super.lens) "test-properties";

  # doctest doesn't work on ghcjs, but sometimes dontCheck doesn't seem to get rid of the dependency
  doctest = builtins.trace "Warning: ignoring dependency on doctest" null;

  # These packages require doctest
  http-types = dontCheck super.http-types;

  #TODO: Fix this; it seems like it might indicate a bug in ghcjs
  parsec = dontCheck super.parsec;

  # Need newer version of colour for some semigroup.
  colour = dontCheck (super.colour.overrideAttrs (drv: {
    src = nixpkgs.fetchurl {
      url = "http://hackage.haskell.org/package/colour-2.3.4/colour-2.3.4.tar.gz";
      sha256 = "1sy51nz096sv91nxqk6yk7b92b5a40axv9183xakvki2nc09yhqg";
    };
  }));

  tagsoup = dontCheck (super.tagsoup);

  primitive = doJailbreak (self.callHackage "primitive" "0.6.3.0" {});
  conduit = dontCheck (self.callHackage "conduit" "1.3.0.3" { });
  resourcet = self.callHackage "resourcet" "1.2.1" { };
  unliftio = dontCheck super.unliftio;
  silently = dontCheck super.silently;
}