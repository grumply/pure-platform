{ nixpkgs ? import <nixpkgs> {}
, system ? builtins.currentSystem
, config ? {}
}:
let inherit (nixpkgs) fetchurl fetchgit fetchgitPrivate fetchFromGitHub;
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
        pure              = self.callPackage (hackGet ./pure)              {};
        pure-async        = self.callPackage (hackGet ./pure-async)        {};
        # pure-bench        = self.callPackage (hackGet ./pure-bench)        {};
        pure-cache        = self.callPackage (hackGet ./pure-cache)        {};
        pure-cond         = self.callPackage (hackGet ./pure-cond)         {};
        pure-core         = self.callPackage (hackGet ./pure-core)         {};
        pure-css          = self.callPackage (hackGet ./pure-css)          {};
        pure-default      = self.callPackage (hackGet ./pure-default)      {};
        pure-dom          = self.callPackage (hackGet ./pure-dom)          {};
        pure-ease         = self.callPackage (hackGet ./pure-ease)         {};
        pure-events       = self.callPackage (hackGet ./pure-events)       {};
        pure-forms        = self.callPackage (hackGet ./pure-forms)        {};
        pure-grid         = self.callPackage (hackGet ./pure-grid)         {};
        pure-html         = self.callPackage (hackGet ./pure-html)         {};
        pure-json         = self.callPackage (hackGet ./pure-json)         {};
        pure-lazyloader   = self.callPackage (hackGet ./pure-lazyloader)   {};
        pure-lifted       = self.callPackage (hackGet ./pure-lifted)       {};
        pure-limiter      = self.callPackage (hackGet ./pure-limiter)      {};
        pure-loader       = self.callPackage (hackGet ./pure-loader)       {};
        pure-localstorage = self.callPackage (hackGet ./pure-localstorage) {};
        pure-modal        = self.callPackage (hackGet ./pure-modal)        {};
        pure-paginate     = self.callPackage (hackGet ./pure-paginate)     {};
        pure-periodically = self.callPackage (hackGet ./pure-periodically) {};
        pure-portal       = self.callPackage (hackGet ./pure-portal)       {};
        pure-popup        = self.callPackage (hackGet ./pure-popup)        {};
        pure-prop         = self.callPackage (hackGet ./pure-prop)         {};
        pure-proxy        = self.callPackage (hackGet ./pure-proxy)        {};
        pure-queue        = self.callPackage (hackGet ./pure-queue)        {};
        pure-radar        = self.callPackage (hackGet ./pure-radar)        {};
        pure-random-pcg   = self.callPackage (hackGet ./pure-random-pcg)   {};
        pure-readfile     = self.callPackage (hackGet ./pure-readfile)     {};
        pure-render       = self.callPackage (hackGet ./pure-render)       {};
        pure-responsive   = self.callPackage (hackGet ./pure-responsive)   {};
        pure-router       = self.callPackage (hackGet ./pure-router)       {};
        pure-scroll-loader = self.callPackage (hackGet ./pure-scroll-loader) {};
        pure-search       = self.callPackage (hackGet ./pure-search)       {};
        pure-server       = self.callPackage (hackGet ./pure-server)       {};
        pure-spacetime    = self.callPackage (hackGet ./pure-spacetime)    {};
        pure-spinners     = self.callPackage (hackGet ./pure-spinners)     {};
        pure-state        = self.callPackage (hackGet ./pure-state)        {};
        pure-sticky       = self.callPackage (hackGet ./pure-sticky)       {};
        pure-styles       = self.callPackage (hackGet ./pure-styles)       {};
        pure-suspense     = self.callPackage (hackGet ./pure-suspense)     {};
        pure-svg          = self.callPackage (hackGet ./pure-svg)          {};
        pure-tagsoup      = self.callPackage (hackGet ./pure-tagsoup)      {};
        pure-template     = self.callPackage (hackGet ./pure-template)     {};
        pure-test         = self.callPackage (hackGet ./pure-test)         {};
        pure-theme        = self.callPackage (hackGet ./pure-theme)        {};
        pure-time         = self.callPackage (hackGet ./pure-time)         {};
        pure-tlc          = self.callPackage (hackGet ./pure-tlc)          {};
        pure-transition   = self.callPackage (hackGet ./pure-transition)   {};
        pure-try          = self.callPackage (hackGet ./pure-try)          {};
        pure-txt          = self.callPackage (hackGet ./pure-txt)          {};
        pure-txt-interpolate = self.callPackage (hackGet ./pure-txt-interpolate) {};
        pure-txt-search   = self.callPackage (hackGet ./pure-txt-search)   {};
        pure-txt-trie     = self.callPackage (hackGet ./pure-txt-trie)     {};
        pure-variance     = self.callPackage (hackGet ./pure-variance)     {};
        pure-visibility   = self.callPackage (hackGet ./pure-visibility)   {};
        pure-websocket    = self.callPackage (hackGet ./pure-websocket)    {};
        pure-uri          = self.callPackage (hackGet ./pure-uri)          {};
        pure-xml          = self.callPackage (hackGet ./pure-xml)          {};
        ef                = self.callPackage (hackGet ./ef)                {};
        excelsior         = self.callPackage (hackGet ./excelsior)         {};

	      pure-semantic-ui  = self.callPackage (hackGet ./pure-semantic-ui)  {};

        websockets        = self.callHackage "websockets" "0.12.4.0"       {};
        tagsoup           = self.callHackage "tagsoup" "0.14.6"            {};

	      haskell-src-meta  = self.callHackage "haskell-src-meta" "0.8.0.3"  {};

        roles             = self.callHackage "roles" "0.2.0.0"             {};

        hasktags          = dontCheck super.hasktags;

        comonad           = dontCheck super.comonad;
        semigroupoids     = dontCheck super.semigroupoids;

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

  ghc = (extendHaskellPackages nixpkgs.pkgs.haskell.packages.ghc844).override {
    overrides = foldr composeExtensions (_: _: {}) [
       (ghcjsPkgs (nixpkgs.pkgs.haskell.compiler.ghcjs84.override {
        ghcjsSrc = fetchgit {
          url = "https://github.com/ghcjs/ghcjs.git";
          branchName = "ghc-8.4";
          rev = "00a8993a8d9c35b33b84a83b0aec5171c582a4f3";
          sha256 = "0a9qna5qffskfgw9a4jwvzfd81c41vw36k46hw52hw9xxynvk7x9";
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
      cabal-install
      ghcid
      hasktags
      hlint;
    inherit (nixpkgs)
      cabal2nix
      curl
      nix-prefetch-scripts
      nodejs
      pkgconfig
      closurecompiler;
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

  # The systems that we want to build for on the current system
  cacheTargetSystems = [
    "x86_64-linux"
    "x86_64-darwin"
  ];

  pureEnv = platform:
    let haskellPackages = builtins.getAttr platform this;
        ghcWithStuff = if platform == "ghc" || platform == "ghcjs" then haskellPackages.ghcWithHoogle else haskellPackages.ghcWithPackages;
    in ghcWithStuff (p: import ./packages.nix { haskellPackages = p; inherit platform; });

  tryPurePackages = generalDevTools ghc
    ++ builtins.map pureEnv platforms;

  lib = haskellLib;
  inherit system;
  project = args: import ./project this (args ({ pkgs = nixpkgs; } // this));
  tryPureShell = pinBuildInputs ("shell-" + system) tryPurePackages [];
}; in this
