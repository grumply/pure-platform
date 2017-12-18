with import ./. {};
let inherit (nixpkgs.lib) optionals;
    inputs = builtins.concatLists [
      (builtins.attrValues sources)
      (map (system: (import ./. { inherit system; iosSupportForce = true; }).tryPureShell) cacheTargetSystems)
    ];
    getOtherDeps = purePlatform: [
      purePlatform.stage2Script
      purePlatform.nixpkgs.cabal2nix
    ] ++ builtins.concatLists (map
      (crossPkgs: optionals (crossPkgs != null) [
        crossPkgs.buildPackages.haskellPackages.cabal2nix
      ]) [
        purePlatform.nixpkgsCross.ios.arm64
        purePlatform.nixpkgsCross.android.arm64Impure
        purePlatform.nixpkgsCross.android.armv7aImpure
      ]
    );
    otherDeps = builtins.concatLists (
      map (system: getOtherDeps (import ./. { inherit system; })) cacheTargetSystems
    );
in pinBuildInputs "pure-platform" inputs otherDeps