{ haskellLib, fetchFromGitHub }:

self: super: {
  bifunctors = haskellLib.dontCheck super.bifunctors;
}
