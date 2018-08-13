with import ./. {};
let inherit (nixpkgs.lib) optionals;
    inputs = builtins.concatLists [
      (map (system: (import ./. { inherit system; }).tryPureShell) cacheTargetSystems)
    ];
    getOtherDeps = purePlatform: [
      purePlatform.nixpkgs.cabal2nix
    ];
    otherDeps = builtins.concatLists (
      map (system: getOtherDeps (import ./. { inherit system; })) cacheTargetSystems
    );
in pinBuildInputs "pure-platform" inputs otherDeps