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

  # doctest doesn't work on ghcjs, but sometimes dontCheck doesn't seem to get rid of the dependency
  doctest = builtins.trace "Warning: ignoring dependency on doctest" null;

  tagsoup = dontCheck (super.tagsoup);

}