{ haskellLib, fetchFromGitHub }:

self: super: {
  cabal-install = self.callCabal2nix "cabal-install" ((fetchFromGitHub {
    owner = "haskell";
    repo = "cabal";
    rev = "082cf2066b7206d3b12a9f92d832236e2484b4c1";
    sha256 = "0xzkwwim3chx9sd94b7n41ii9d51xzjlj48ikgn5dqjnxryz2r4k";
  }) + "/cabal-install") {};
  comonad = self.callHackage "comonad" "5.0.2" {};
  distributive = self.callHackage "distributive" "0.5.3" {};
  doctest = self.callHackage "doctest" "0.13.0" {};
  hackage-security = haskellLib.dontCheck (haskellLib.doJailbreak super.hackage-security);
  haddock = null;
  haddock-api = null; #haskellLib.dontCheck super.haddock-api;
  haddock-library = null; #haskellLib.dontHaddock (haskellLib.dontCheck (self.callPackage ./haddock-library.nix {}));
  primitive = self.callHackage "primitive" "0.6.2.0" {};
  profunctors = self.callHackage "profunctors" "5.2.1" {};
  semigroupoids = self.callHackage "semigroupoids" "5.2.1" {};
  syb = self.callHackage "syb" "0.7" {};
  vector = self.callHackage "vector" "0.12.0.1" {};
}
