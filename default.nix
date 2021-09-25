{ nixpkgsFunc ? import ./nixpkgs
, system ? builtins.currentSystem
, config ? {}
}:
let nixpkgs = nixpkgsFunc config;
    inherit (nixpkgs) fetchurl fetchgit fetchgitPrivate fetchFromGitHub;
    haskellLib = nixpkgs.haskell.lib;
    filterGit = builtins.filterSource (path: type: !(builtins.any (x: x == baseNameOf path) [".git" "tags" "TAGS" "dist"]));
    # Retrieve source that is controlled by the hack-* scripts; it may be either a stub or a checked-out git repo
    hackGet = p:
      if builtins.pathExists (p + "/git.json") then (
        let gitArgs = builtins.fromJSON (builtins.readFile (p + "/git.json"));
        in if builtins.elem "@" (nixpkgs.lib.stringToCharacters gitArgs.url)
        then fetchgitPrivate gitArgs
        else fetchgit gitArgs)
      else if builtins.pathExists (p + "/github.json") then fetchFromGitHub (builtins.fromJSON (builtins.readFile (p + "/github.json")))
      else {
        name = baseNameOf p;
        outPath = filterGit p;
      };
    inherit (nixpkgs.stdenv.lib) optional optionals optionalAttrs;
in with nixpkgs.lib; with haskellLib;
let combineOverrides = old: new: (old // new) // {
      overrides = composeExtensions old.overrides new.overrides;
    };
    makeRecursivelyOverridable = x: old: x.override old // {
      override = new: makeRecursivelyOverridable x (combineOverrides old new);
    };
    ghcjsPkgs = ghcjs: self: super: {
      ghcjs = ghcjs.overrideAttrs (o: {
        patches = (o.patches or []);
        phases = [ "unpackPhase" "patchPhase" "buildPhase" ];
      });
    };

    extendHaskellPackages = haskellPackages: makeRecursivelyOverridable haskellPackages {
      overrides = self: super: {
        pure              = self.callPackage (hackGet ./packages/pure)              {};
        pure-async        = self.callPackage (hackGet ./packages/pure-async)        {};
        pure-bench        = self.callPackage (hackGet ./packages/pure-bench)        {};
        pure-bloom        = self.callPackage (hackGet ./packages/pure-bloom)        {};
        pure-cache        = self.callPackage (hackGet ./packages/pure-cache)        {};
        pure-cached       = self.callPackage (hackGet ./packages/pure-cached)       {};
        pure-capability   = self.callPackage (hackGet ./packages/pure-capability)   {};
        pure-cond         = self.callPackage (hackGet ./packages/pure-cond)         {};
        pure-contexts     = self.callPackage (hackGet ./packages/pure-contexts)     {};
        pure-core         = self.callPackage (hackGet ./packages/pure-core)         {};
        pure-css          = self.callPackage (hackGet ./packages/pure-css)          {};
        pure-default      = self.callPackage (hackGet ./packages/pure-default)      {};
        pure-dom          = self.callPackage (hackGet ./packages/pure-dom)          {};
        pure-ease         = self.callPackage (hackGet ./packages/pure-ease)         {};
        pure-elm          = self.callPackage (hackGet ./packages/pure-elm)          {};
        pure-events       = self.callPackage (hackGet ./packages/pure-events)       {};
        pure-fetch        = self.callPackage (hackGet ./packages/pure-fetch)        {};
        pure-forms        = self.callPackage (hackGet ./packages/pure-forms)        {};
        pure-gestures     = self.callPackage (hackGet ./packages/pure-gestures)     {};
        pure-grid         = self.callPackage (hackGet ./packages/pure-grid)         {};
        pure-hooks        = self.callPackage (hackGet ./packages/pure-hooks)        {};
        pure-html         = self.callPackage (hackGet ./packages/pure-html)         {};
        pure-intersection = self.callPackage (hackGet ./packages/pure-intersection) {};
        pure-json         = self.callPackage (hackGet ./packages/pure-json)         {};
        pure-lazyloader   = self.callPackage (hackGet ./packages/pure-lazyloader)   {};
        pure-lifted       = self.callPackage (hackGet ./packages/pure-lifted)       {};
        pure-limiter      = self.callPackage (hackGet ./packages/pure-limiter)      {};
        pure-loader       = self.callPackage (hackGet ./packages/pure-loader)       {};
        pure-localstorage = self.callPackage (hackGet ./packages/pure-localstorage) {};
        pure-locker       = self.callPackage (hackGet ./packages/pure-locker)       {};
        pure-marker       = self.callPackage (hackGet ./packages/pure-marker)       {};
        pure-maybe        = self.callPackage (hackGet ./packages/pure-maybe)        {};
        pure-modal        = self.callPackage (hackGet ./packages/pure-modal)        {};
        pure-mutation     = self.callPackage (hackGet ./packages/pure-mutation)     {};
        pure-paginate     = self.callPackage (hackGet ./packages/pure-paginate)     {};
        pure-periodically = self.callPackage (hackGet ./packages/pure-periodically) {};
        # pure-portal       = self.callPackage (hackGet ./packages/pure-portal)       {};
        pure-popup        = self.callPackage (hackGet ./packages/pure-popup)        {};
        pure-prop         = self.callPackage (hackGet ./packages/pure-prop)         {};
        pure-proxy        = self.callPackage (hackGet ./packages/pure-proxy)        {};
        pure-queue        = self.callPackage (hackGet ./packages/pure-queue)        {};
        pure-radar        = self.callPackage (hackGet ./packages/pure-radar)        {};
        pure-random-pcg   = self.callPackage (hackGet ./packages/pure-random-pcg)   {};
        pure-readfile     = self.callPackage (hackGet ./packages/pure-readfile)     {};
        pure-render       = self.callPackage (hackGet ./packages/pure-render)       {};
        pure-responsive   = self.callPackage (hackGet ./packages/pure-responsive)   {};
        pure-router       = self.callPackage (hackGet ./packages/pure-router)       {};
        pure-scroll-loader = self.callPackage (hackGet ./packages/pure-scroll-loader) {};
        pure-search       = self.callPackage (hackGet ./packages/pure-search)       {};
        pure-server       = self.callPackage (hackGet ./packages/pure-server)       {};
        pure-sorcerer     = self.callPackage (hackGet ./packages/pure-sorcerer)     {};
        pure-spacetime    = self.callPackage (hackGet ./packages/pure-spacetime)    {};
        pure-spinners     = self.callPackage (hackGet ./packages/pure-spinners)     {};
        pure-state        = self.callPackage (hackGet ./packages/pure-state)        {};
        pure-stream       = self.callPackage (hackGet ./packages/pure-stream)       {};
        pure-sticky       = self.callPackage (hackGet ./packages/pure-sticky)       {};
        pure-styles       = self.callPackage (hackGet ./packages/pure-styles)       {};
        pure-suspense     = self.callPackage (hackGet ./packages/pure-suspense)     {};
        pure-svg          = self.callPackage (hackGet ./packages/pure-svg)          {};
        pure-tagsoup      = self.callPackage (hackGet ./packages/pure-tagsoup)      {};
        pure-template     = self.callPackage (hackGet ./packages/pure-template)     {};
        pure-test         = self.callPackage (hackGet ./packages/pure-test)         {};
        pure-theme        = self.callPackage (hackGet ./packages/pure-theme)        {};
        pure-time         = self.callPackage (hackGet ./packages/pure-time)         {};
        pure-tlc          = self.callPackage (hackGet ./packages/pure-tlc)          {};
        pure-transition   = self.callPackage (hackGet ./packages/pure-transition)   {};
        pure-try          = self.callPackage (hackGet ./packages/pure-try)          {};
        pure-txt          = self.callPackage (hackGet ./packages/pure-txt)          {};
        pure-txt-interpolate = self.callPackage (hackGet ./packages/pure-txt-interpolate) {};
        pure-txt-search   = self.callPackage (hackGet ./packages/pure-txt-search)   {};
        pure-txt-trie     = self.callPackage (hackGet ./packages/pure-txt-trie)     {};
        pure-variance     = self.callPackage (hackGet ./packages/pure-variance)     {};
        pure-visibility   = self.callPackage (hackGet ./packages/pure-visibility)   {};
        pure-websocket    = self.callPackage (hackGet ./packages/pure-websocket)    {};
        pure-uri          = self.callPackage (hackGet ./packages/pure-uri)          {};
        pure-xhr          = self.callPackage (hackGet ./packages/pure-xhr)          {};
        pure-xml          = self.callPackage (hackGet ./packages/pure-xml)          {};
        pure-xss-sanitize = self.callPackage (hackGet ./packages/pure-xss-sanitize) {};
        ef                = self.callPackage (hackGet ./packages/ef)                {};
        excelsior         = self.callPackage (hackGet ./packages/excelsior)         {};
        origami-fold      = self.callPackage (hackGet ./packages/origami-fold)      {};

	      pure-semantic-ui  = self.callPackage (hackGet ./packages/pure-semantic-ui)  {};

        tagsoup           = self.callHackage "tagsoup" "0.14.6"            {};

        hasktags          = dontCheck super.hasktags;

        comonad           = dontCheck super.comonad;
        semigroupoids     = dontCheck super.semigroupoids;
        lens              = dontCheck super.lens;

        tasty-quickcheck  = dontCheck super.tasty-quickcheck;
        scientific        = dontCheck super.scientific;

        time-compat       = dontCheck super.time-compat;
        uuid-types        = dontCheck super.uuid-types;

        xss-sanitize      = dontCheck super.xss-sanitize;
        Glob              = dontCheck super.Glob;
        network-uri       = dontCheck super.network-uri;
        http-client       = dontCheck super.http-client;
        http-client-tls   = dontCheck super.http-client-tls;
        http-conduit      = dontCheck super.http-conduit;
        warp              = dontCheck super.warp;
        warp-tls          = dontCheck super.warp-tls;

        # really?
        QuickCheck = 
          (overrideCabal super.QuickCheck (old: {
            doCheck = false;
          }));
        };
    };
    haskellOverlays = import ./haskell-overlays {
      inherit
        haskellLib
        nixpkgs hackGet fetchFromGitHub;
      inherit (nixpkgs) lib;
    };

  ghcjs = (extendHaskellPackages ghcjsPackages).override {
    overrides = foldr composeExtensions (_: _: {}) [
      haskellOverlays.ghcjs
    ];
  };
  ghcjsPackages = nixpkgs.callPackage (nixpkgs.path + "/pkgs/development/haskell-modules") {
    ghc = ghc.ghcjs;
    buildHaskellPackages = ghc.ghcjs.bootPkgs;
    compilerConfig = nixpkgs.callPackage (nixpkgs.path + "/pkgs/development/haskell-modules/configuration-ghc-8.4.x.nix") { inherit haskellLib; };
    packageSetConfig = nixpkgs.callPackage (nixpkgs.path + "/pkgs/development/haskell-modules/configuration-ghcjs.nix") { inherit haskellLib; };
    inherit haskellLib;
  };

  ghc = (extendHaskellPackages nixpkgs.pkgs.haskell.packages.ghc865).override {
    overrides = foldr composeExtensions (_: _: {}) [
      (ghcjsPkgs (nixpkgs.pkgs.haskell.compiler.ghcjs86.override {
        ghcjsSrc = fetchgit {
          url = "https://github.com/ghcjs/ghcjs.git";
          branchName = "ghc-8.6";
          rev = "e87195eaa2bc7e320e18cf10386802bc90b7c874";
          sha256 = "02mwkf7aagxqi142gcmq048244apslrr72p568akcab9s0fn2gvy";
          fetchSubmodules = true;
        };
      }))
      haskellOverlays.ghc
    ];
  };
in let this = rec {
  inherit nixpkgs
          hackGet
          extendHaskellPackages
          ghc
          ghcjs;
  setGhcLibdir = ghcLibdir: inputGhcjs:
    let libDir = "$out/lib/ghcjs-${inputGhcjs.version}";
        ghcLibdirLink = nixpkgs.stdenv.mkDerivation {
          name = "ghc_libdir";
          inherit ghcLibdir;
          buildCommand = ''
            mkdir -p ${libDir}
            echo "$ghcLibdir" > ${libDir}/ghc_libdir_override
          '';
        };
    in inputGhcjs // {
    outPath = nixpkgs.buildEnv {
      inherit (inputGhcjs) name;
      paths = [ inputGhcjs ghcLibdirLink ];
      postBuild = ''
        mv ${libDir}/ghc_libdir_override ${libDir}/ghc_libdir
      '';
    };
  };

  platforms = [
    "ghcjs"
    "ghc"
  ];
 
  # Tools that are useful for development under both ghc and ghcjs
  generalDevToolsAttrs = haskellPackages:
    let nativeHaskellPackages = ghc;
    in {
    inherit (nativeHaskellPackages)
      Cabal
      cabal-install;
    inherit (nixpkgs)
      cabal2nix
      curl
      nix-prefetch-scripts
      nodejs-12_x
      pkgconfig;
  };

  generalDevTools = haskellPackages: builtins.attrValues (generalDevToolsAttrs haskellPackages);

  workOn = haskellPackages: package: (overrideCabal package (drv: {
      buildDepends = (drv.buildDepends or []) ++ generalDevTools (nativeHaskellPackages haskellPackages);
    })).env;

  workOnMulti' = { env, packageNames, tools ? _: [], shellToolOverrides ? _: _: {} }:
    let inherit (builtins) listToAttrs filter attrValues all concatLists;
        combinableAttrs = [
          "benchmarkDepends"
          "benchmarkFrameworkDepends"
          "benchmarkHaskellDepends"
          "benchmarkPkgconfigDepends"
          "benchmarkSystemDepends"
          "benchmarkToolDepends"
          "buildDepends"
          "buildTools"
          "executableFrameworkDepends"
          "executableHaskellDepends"
          "executablePkgconfigDepends"
          "executableSystemDepends"
          "executableToolDepends"
          "extraLibraries"
          "libraryFrameworkDepends"
          "libraryHaskellDepends"
          "libraryPkgconfigDepends"
          "librarySystemDepends"
          "libraryToolDepends"
          "pkgconfigDepends"
          "setupHaskellDepends"
          "testDepends"
          "testFrameworkDepends"
          "testHaskellDepends"
          "testPkgconfigDepends"
          "testSystemDepends"
          "testToolDepends"
        ];
        concatCombinableAttrs = haskellConfigs: listToAttrs (map (name: { inherit name; value = concatLists (map (haskellConfig: haskellConfig.${name} or []) haskellConfigs); }) combinableAttrs);
        getHaskellConfig = p: (overrideCabal p (args: {
          passthru = (args.passthru or {}) // {
            out = args;
          };
        })).out;
        notInTargetPackageSet = p: all (pname: (p.pname or "") != pname) packageNames;
        baseTools = generalDevToolsAttrs env;
        overriddenTools = attrValues (baseTools // shellToolOverrides env baseTools);
        depAttrs = mapAttrs (_: v: filter notInTargetPackageSet v) (concatCombinableAttrs (concatLists [
          (map getHaskellConfig (attrVals packageNames env))
          [{
            buildTools = overriddenTools ++ tools env;
          }]
        ]));

    in (env.mkDerivation (depAttrs // {
      pname = "work-on-multi--combined-pkg";
      version = "0";
      license = null;
    })).env;

  workOnMulti = env: packageNames: workOnMulti' { inherit env packageNames; };

  nativeHaskellPackages = haskellPackages:
    if haskellPackages.isGhcjs or false
    then haskellPackages.ghc
    else haskellPackages;

  # A simple derivation that just creates a file with the names of all of its inputs.  If built, it will have a runtime dependency on all of the given build inputs.
  pinBuildInputs = drvName: buildInputs: otherDeps: nixpkgs.runCommand drvName {
    buildCommand = ''
      mkdir "$out"
      echo "$propagatedBuildInputs $buildInputs $nativeBuildInputs $propagatedNativeBuildInputs $otherDeps" > "$out/deps"
    '';
    inherit buildInputs otherDeps;
  } "";

  pureEnv = platform:
    let haskellPackages = builtins.getAttr platform this;
        ghcWithStuff = if platform == "ghc" || platform == "ghcjs" then haskellPackages.ghcWithHoogle else haskellPackages.ghcWithPackages;
    in ghcWithStuff (p: import ./packages.nix { haskellPackages = p; inherit platform; });

  tryPurePackages = generalDevTools ghc ++ builtins.map pureEnv platforms;

  lib = haskellLib;

  inherit system;

  project = args: import ./project this (args ({ pkgs = nixpkgs; } // this));

  tryPureShell = pinBuildInputs ("shell-" + system) tryPurePackages [];

}; in this
