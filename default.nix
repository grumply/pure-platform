{ nixpkgsFunc ? import ./nixpkgs
, system ? builtins.currentSystem
, config ? {}
, enableLibraryProfiling ? false
, iosSdkVersion ? "11.4"
, iosSdkLocation ? "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS${iosSdkVersion}.sdk"
, iosSupportForce ? false
}:
let iosSupport =
      if system != "x86_64-darwin" then false
      else if iosSupportForce || builtins.pathExists iosSdkLocation then true
      else builtins.trace "Warning: No iOS sdk found at ${iosSdkLocation}; iOS support disabled.  To enable, either install a version of Xcode that provides that SDK or override the value of iosSdkVersion to match your installed version." false;
    globalOverlay = self: super: {
      all-cabal-hashes = super.all-cabal-hashes.override {
        src-spec = {
          owner = "commercialhaskell";
          repo = "all-cabal-hashes";
          rev = "6c7ac64f43122567867760dfa6d0014301d1cfd9";
          sha256 = "14m7c0iapz1svqk4hm0a9gpxnkbwj2fk8g8b1js5p8nrvqawgm1z";
        };
      };
    };
    nixpkgs = nixpkgsFunc ({
      inherit system;
      overlays = [globalOverlay];
      config = {
        allowUnfree = true;
        allowBroken = true; # GHCJS is marked broken in 011c149ed5e5a336c3039f0b9d4303020cff1d86
        permittedInsecurePackages = [
          "webkitgtk-2.4.11"
        ];
        packageOverrides = pkgs: {
          webkitgtk = pkgs.webkitgtk216x;
          # cabal2nix's tests crash on 32-bit linux; see https://github.com/NixOS/cabal2nix/issues/272
          ${if system == "i686-linux" then "cabal2nix" else null} = pkgs.haskell.lib.dontCheck pkgs.cabal2nix;
        };
      } // config;
    });
    inherit (nixpkgs) fetchurl fetchgit fetchgitPrivate fetchFromGitHub;
    nixpkgsCross = {
      android = nixpkgs.lib.mapAttrs (_: args: if args == null then null else nixpkgsFunc args) rec {
        arm64 = {
          system = "x86_64-linux";
          overlays = [globalOverlay];
          crossSystem = {
            config = "aarch64-unknown-linux-android";
            arch = "arm64";
            libc = "bionic";
            withTLS = true;
            openssl.system = "linux-generic64";
            platform = nixpkgs.pkgs.platforms.aarch64-multiplatform;
          };
          config.allowUnfree = true;
        };
        arm64Impure = arm64 // {
          crossSystem = arm64.crossSystem // { useAndroidPrebuilt = true; };
        };
        armv7a = {
          system = "x86_64-linux";
          overlays = [globalOverlay];
          crossSystem = {
            config = "arm-unknown-linux-androideabi";
            arch = "armv7";
            libc = "bionic";
            withTLS = true;
            openssl.system = "linux-generic32";
            platform = nixpkgs.pkgs.platforms.armv7l-hf-multiplatform;
          };
          config.allowUnfree = true;
        };
        armv7aImpure = armv7a // {
          crossSystem = armv7a.crossSystem // { useAndroidPrebuilt = true; };
        };
      };
      ios =
        let config = {
              allowUnfree = true;
              packageOverrides = p: {
                darwin = p.darwin // {
                  ios-cross = p.darwin.ios-cross.override {
                    # Depending on where ghcHEAD is in your nixpkgs checkout, you may need llvm 39 here instead
                    inherit (p.llvmPackages_39) llvm clang;
                  };
                };
                buildPackages = p.buildPackages // {
                  osx_sdk = p.buildPackages.callPackage ({ stdenv }:
                    let version = "10";
                    in stdenv.mkDerivation rec {
                    name = "iOS.sdk";

                    src = p.stdenv.cc.sdk;

                    unpackPhase    = "true";
                    configurePhase = "true";
                    buildPhase     = "true";
                    target_prefix = stdenv.lib.replaceStrings ["-"] ["_"] p.targetPlatform.config;
                    setupHook = ./setup-hook-ios.sh;

                    installPhase = ''
                      mkdir -p $out/
                      echo "Source is: $src"
                      cp -r $src/* $out/
                    '';

                    meta = with stdenv.lib; {
                      description = "The IOS OS ${version} SDK";
                      maintainers = with maintainers; [ copumpkin ];
                      platforms   = platforms.darwin;
                      license     = licenses.unfree;
                    };
                  }) {};
                };
              };
            };
        in nixpkgs.lib.mapAttrs (_: args: if args == null then null else nixpkgsFunc args) {
        simulator64 = {
          system = "x86_64-darwin";
          overlays = [globalOverlay];
          crossSystem = {
            useIosPrebuilt = true;
            # You can change config/arch/isiPhoneSimulator depending on your target:
            # aarch64-apple-darwin14 | arm64  | false
            # arm-apple-darwin10     | armv7  | false
            # i386-apple-darwin11    | i386   | true
            # x86_64-apple-darwin14  | x86_64 | true
            config = "x86_64-apple-darwin14";
            arch = "x86_64";
            isiPhoneSimulator = true;
            sdkVer = iosSdkVersion;
            useiOSCross = true;
            openssl.system = "darwin64-x86_64-cc";
            libc = "libSystem";
          };
          inherit config;
        };
        arm64 = {
          system = "x86_64-darwin";
          overlays = [globalOverlay];
          crossSystem = {
            useIosPrebuilt = true;
            # You can change config/arch/isiPhoneSimulator depending on your target:
            # aarch64-apple-darwin14 | arm64  | false
            # arm-apple-darwin10     | armv7  | false
            # i386-apple-darwin11    | i386   | true
            # x86_64-apple-darwin14  | x86_64 | true
            config = "aarch64-apple-darwin14";
            arch = "arm64";
            isiPhoneSimulator = false;
            sdkVer = iosSdkVersion;
            useiOSCross = true;
            openssl.system = "ios64-cross";
            libc = "libSystem";
          };
          inherit config;
        };
      };
    };
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
    # All imports of sources need to go here, so that they can be explicitly cached
    sources = {
      ghcjs-boot = hackGet ./ghcjs-boot;
      shims = hackGet ./shims;
      ghcjs = hackGet ./ghcjs;
    };
    inherit (nixpkgs.stdenv.lib) optional optionals;
    optionalExtension = cond: overlay: if cond then overlay else _: _: {};
in with haskellLib;
let overrideCabal = pkg: f: if pkg == null then null else haskellLib.overrideCabal pkg f;
    replaceSrc = pkg: src: version: overrideCabal pkg (drv: {
      inherit src version;
      sha256 = null;
      revision = null;
      editedCabalFile = null;
    });
    combineOverrides = old: new: (old // new) // {
      overrides = nixpkgs.lib.composeExtensions old.overrides new.overrides;
    };
    makeRecursivelyOverridable = x: old: x.override old // {
      override = new: makeRecursivelyOverridable x (combineOverrides old new);
    };

    # huh?
    foreignLibSmuggleHeaders = pkg: overrideCabal pkg (drv: {
      postInstall = ''
        cd dist/build/${pkg.pname}/${pkg.pname}-tmp
        for header in $(find . | grep '\.h'$); do
          local dest_dir=$out/include/$(dirname "$header")
          mkdir -p "$dest_dir"
          cp "$header" "$dest_dir"
        done
      '';
    });
    extendHaskellPackages = haskellPackages: makeRecursivelyOverridable haskellPackages {
      overrides = self: super: {
        pure              = self.callPackage (hackGet ./pure)              {};
        pure-cond         = self.callPackage (hackGet ./pure-cond)         {};
        pure-core         = self.callPackage (hackGet ./pure-core)         {};
        pure-css          = self.callPackage (hackGet ./pure-css)          {};
        pure-default      = self.callPackage (hackGet ./pure-default)      {};
        pure-dom          = self.callPackage (hackGet ./pure-dom)          {};
        pure-ease         = self.callPackage (hackGet ./pure-ease)         {};
        pure-events       = self.callPackage (hackGet ./pure-events)       {};
        pure-html         = self.callPackage (hackGet ./pure-html)         {};
        pure-json         = self.callPackage (hackGet ./pure-json)         {};
        pure-lifted       = self.callPackage (hackGet ./pure-lifted)       {};
        pure-limiter      = self.callPackage (hackGet ./pure-limiter)      {};
        pure-loader       = self.callPackage (hackGet ./pure-loader)       {};
        pure-localstorage = self.callPackage (hackGet ./pure-localstorage) {};
        pure-modal        = self.callPackage (hackGet ./pure-modal)        {};
        pure-portal       = self.callPackage (hackGet ./pure-portal)       {};
        pure-popup        = self.callPackage (hackGet ./pure-popup)        {};
        pure-prop         = self.callPackage (hackGet ./pure-prop)         {};
        pure-proxy        = self.callPackage (hackGet ./pure-proxy)        {};
        pure-queue        = self.callPackage (hackGet ./pure-queue)        {};
        pure-random-pcg   = self.callPackage (hackGet ./pure-random-pcg)   {};
        pure-render       = self.callPackage (hackGet ./pure-render)       {};
        pure-responsive   = self.callPackage (hackGet ./pure-responsive)   {};
        pure-router       = self.callPackage (hackGet ./pure-router)       {};
        pure-server       = self.callPackage (hackGet ./pure-server)       {};
        pure-spacetime    = self.callPackage (hackGet ./pure-spacetime)    {};
        pure-spinners     = self.callPackage (hackGet ./pure-spinners)     {};
        pure-sticky       = self.callPackage (hackGet ./pure-sticky)       {};
        pure-styles       = self.callPackage (hackGet ./pure-styles)       {};
        pure-svg          = self.callPackage (hackGet ./pure-svg)          {};
        pure-tagsoup      = self.callPackage (hackGet ./pure-tagsoup)      {};
        pure-test         = self.callPackage (hackGet ./pure-test)         {};
        pure-theme        = self.callPackage (hackGet ./pure-theme)        {};
        pure-time         = self.callPackage (hackGet ./pure-time)         {};
        pure-timediff-simple = self.callPackage (hackGet ./pure-timediff-simple) {};
        pure-transition   = self.callPackage (hackGet ./pure-transition)   {};
        pure-try          = self.callPackage (hackGet ./pure-try)          {};
        pure-txt          = self.callPackage (hackGet ./pure-txt)          {};
        pure-txt-trie     = self.callPackage (hackGet ./pure-txt-trie)     {};
        pure-variance     = self.callPackage (hackGet ./pure-variance)     {};
        pure-visibility   = self.callPackage (hackGet ./pure-visibility)   {};
        pure-websocket    = self.callPackage (hackGet ./pure-websocket)    {};
        pure-uri          = self.callPackage (hackGet ./pure-uri)          {};
        pure-xml          = self.callPackage (hackGet ./pure-xml)          {};
        ef                = self.callPackage (hackGet ./ef)                {};
        excelsior         = self.callPackage (hackGet ./excelsior)         {};

        websockets        = self.callHackage "websockets" "0.12.2.0"       {};
        tagsoup           = self.callHackage "tagsoup" "0.14.6"            {};

        roles             = self.callHackage "roles" "0.2.0.0"             {};

        } // (if enableLibraryProfiling then {
          mkDerivation = expr: super.mkDerivation (expr // { enableLibraryProfiling = true; });
        } else {});
    };
    haskellOverlays = import ./haskell-overlays {
      inherit
        haskellLib
        nixpkgs jdk fetchFromGitHub
        stage2Script;
    };
    stage2Script = nixpkgs.runCommand "stage2.nix" {
      GEN_STAGE2 = builtins.readFile (nixpkgs.path + "/pkgs/development/compilers/ghcjs/gen-stage2.rb");
      buildCommand = ''
        echo "$GEN_STAGE2" > gen-stage2.rb && chmod +x gen-stage2.rb
        patchShebangs .
        ./gen-stage2.rb "${sources.ghcjs-boot}" >"$out"
      '';
      nativeBuildInputs = with nixpkgs; [
        ruby cabal2nix
      ];
    } "";
    ghcjsCompiler = ghc.callPackage (nixpkgs.path + "/pkgs/development/compilers/ghcjs/base.nix") {
      bootPkgs = ghc;
      ghcjsSrc = sources.ghcjs;
      ghcjsBootSrc = sources.ghcjs-boot;
      shims = sources.shims;
      stage2 = import stage2Script;
    };
    ghcjsPackages = nixpkgs.callPackage (nixpkgs.path + "/pkgs/development/haskell-modules") {
      ghc = ghcjsCompiler;
      compilerConfig = nixpkgs.callPackage (nixpkgs.path + "/pkgs/development/haskell-modules/configuration-ghc-7.10.x.nix") { inherit haskellLib; };
      packageSetConfig = nixpkgs.callPackage (nixpkgs.path + "/pkgs/development/haskell-modules/configuration-ghcjs.nix") { inherit haskellLib; };
      inherit haskellLib;
    };
  ghcjs = (extendHaskellPackages ghcjsPackages).override {
    overrides = nixpkgs.lib.foldr nixpkgs.lib.composeExtensions (_: _: {}) [
      haskellOverlays.ghcjs
    ];
  };
  ghcHEAD = (extendHaskellPackages nixpkgs.pkgs.haskell.packages.ghcHEAD).override {
    overrides = nixpkgs.lib.foldr nixpkgs.lib.composeExtensions (_: _: {}) [
      haskellOverlays.ghc-head
    ];
  };
  ghc8_2_1 = (extendHaskellPackages nixpkgs.pkgs.haskell.packages.ghc821).override {
    overrides = nixpkgs.lib.foldr nixpkgs.lib.composeExtensions (_: _: {}) [
      haskellOverlays.ghc-8_2_1
    ];
  };
  ghc = (extendHaskellPackages nixpkgs.pkgs.haskell.packages.ghc802).override {
    overrides = nixpkgs.lib.foldr nixpkgs.lib.composeExtensions (_: _: {}) [
      haskellOverlays.ghc-8
    ];
  };
  ghcAndroidArm64 = (extendHaskellPackages nixpkgsCross.android.arm64Impure.pkgs.haskell.packages.ghc821).override {
    overrides = nixpkgs.lib.foldr nixpkgs.lib.composeExtensions (_: _: {}) [
      haskellOverlays.ghc-8_2_1
      haskellOverlays.disableTemplateHaskell
      haskellOverlays.android
    ];
  };
  ghcAndroidArmv7a = (extendHaskellPackages nixpkgsCross.android.armv7aImpure.pkgs.haskell.packages.ghc821).override {
    overrides = nixpkgs.lib.foldr nixpkgs.lib.composeExtensions (_: _: {}) [
      haskellOverlays.ghc-8_2_1
      haskellOverlays.disableTemplateHaskell
      haskellOverlays.android
    ];
  };
  ghcIosSimulator64 = (extendHaskellPackages nixpkgsCross.ios.simulator64.pkgs.haskell.packages.ghc821).override {
    overrides = nixpkgs.lib.foldr nixpkgs.lib.composeExtensions (_: _: {}) [
      haskellOverlays.ghc-8_2_1
    ];
  };
  ghcIosArm64 = (extendHaskellPackages nixpkgsCross.ios.arm64.pkgs.haskell.packages.ghc821).override {
    overrides = nixpkgs.lib.foldr nixpkgs.lib.composeExtensions (_: _: {}) [
      haskellOverlays.ghc-8_2_1
      haskellOverlays.disableTemplateHaskell
      haskellOverlays.ios
    ];
  };
  ghcIosArmv7 = (extendHaskellPackages nixpkgsCross.ios.armv7.pkgs.haskell.packages.ghc821).override {
    overrides = nixpkgs.lib.foldr nixpkgs.lib.composeExtensions (_: _: {}) [
      haskellOverlays.ghc-8_2_1
      haskellOverlays.disableTemplateHaskell
      haskellOverlays.ios
    ];
  };
  #TODO: Separate debug and release APKs
  #TODO: Warn the user that the android app name can't include dashes
  android = androidWithHaskellPackages { inherit ghcAndroidArm64 ghcAndroidArmv7a; };
  androidWithHaskellPackages = { ghcAndroidArm64, ghcAndroidArmv7a }: import ./android {
    nixpkgs = nixpkgsFunc { system = "x86_64-linux"; };
    inherit nixpkgsCross ghcAndroidArm64 ghcAndroidArmv7a overrideCabal;
  };
  ios = iosWithHaskellPackages ghcIosArm64;
  iosWithHaskellPackages = ghcIosArm64: {
    buildApp = import ./ios {
      inherit ghcIosArm64;
      nixpkgs = nixpkgsFunc { system = "x86_64-darwin"; };
      inherit (nixpkgsCross.ios.arm64) libiconv;
    };
  };
in let this = rec {
  inherit nixpkgs
          nixpkgsCross
          overrideCabal
          hackGet
          extendHaskellPackages
          foreignLibSmuggleHeaders
          stage2Script
          ghc
          ghcHEAD
          ghc8_2_1
          ghc8_0_1
          ghcIosSimulator64
          ghcIosArm64
          ghcIosArmv7
          ghcAndroidArm64
          ghcAndroidArmv7a
          ghcjs
          android
          androidWithHaskellPackages
          ios
          iosWithHaskellPackages;
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

  attrsToList = s: map (name: { inherit name; value = builtins.getAttr name s; }) (builtins.attrNames s);
  mapSet = f: s: builtins.listToAttrs (map ({name, value}: {
    inherit name;
    value = f value;
  }) (attrsToList s));
  mkSdist = pkg: pkg.override {
    mkDerivation = drv: ghc.mkDerivation (drv // {
      postConfigure = ''
        ./Setup sdist
        mkdir "$out"
        mv dist/*.tar.gz "$out/${drv.pname}-${drv.version}.tar.gz"
        exit 0
      '';
      doHaddock = false;
    });
  };
  sdists = mapSet mkSdist ghc;
  mkHackageDocs = pkg: pkg.override {
    mkDerivation = drv: ghc.mkDerivation (drv // {
      postConfigure = ''
        ./Setup haddock --hoogle --hyperlink-source --html --for-hackage --haddock-option=--built-in-themes
        cd dist/doc/html
        mkdir "$out"
        tar cz --format=ustar -f "$out/${drv.pname}-${drv.version}-docs.tar.gz" "${drv.pname}-${drv.version}-docs"
        exit 0
      '';
      doHaddock = false;
    });
  };
  hackageDocs = mapSet mkHackageDocs ghc;
  mkReleaseCandidate = pkg: nixpkgs.stdenv.mkDerivation (rec {
    name = pkg.name + "-rc";
    sdist = mkSdist pkg + "/${pkg.pname}-${pkg.version}.tar.gz";
    docs = mkHackageDocs pkg + "/${pkg.pname}-${pkg.version}-docs.tar.gz";

    builder = builtins.toFile "builder.sh" ''
      source $stdenv/setup

      mkdir "$out"
      echo -n "${pkg.pname}-${pkg.version}" >"$out/pkgname"
      ln -s "$sdist" "$docs" "$out"
    '';

    # 'checked' isn't used, but it is here so that the build will fail if tests fail
    checked = overrideCabal pkg (drv: {
      doCheck = true;
      src = sdist;
    });
  });
  releaseCandidates = mapSet mkReleaseCandidate ghc;

  androidDevTools = [
    ghc.haven
    nixpkgs.maven
    nixpkgs.androidsdk
  ];

  # Tools that are useful for development under both ghc and ghcjs
  generalDevTools = haskellPackages:
    let nativeHaskellPackages = ghc;
    in [
    nativeHaskellPackages.Cabal
    nativeHaskellPackages.cabal-install
    nixpkgs.cabal2nix
    nixpkgs.curl
    nixpkgs.nix-prefetch-scripts
    nixpkgs.nodejs
    nixpkgs.pkgconfig
    nixpkgs.closurecompiler
  ] ++ optionals (system == "x86_64-linux") androidDevTools;

  nativeHaskellPackages = haskellPackages:
    if haskellPackages.isGhcjs or false
    then haskellPackages.ghc
    else haskellPackages;

  workOn = haskellPackages: package: (overrideCabal package (drv: {
    buildDepends = (drv.buildDepends or []) ++ generalDevTools (nativeHaskellPackages haskellPackages);
  })).env;

  workOnMulti' = { env, packageNames, tools ? _: [] }:
    let ghcEnv = env.ghc.withPackages (packageEnv: builtins.concatLists (map (n: (packageEnv.${n}.override { mkDerivation = x: { out = builtins.filter (p: builtins.all (nameToAvoid: (p.pname or "") != nameToAvoid) packageNames) ((x.buildDepends or []) ++ (x.libraryHaskellDepends or []) ++ (x.executableHaskellDepends or []) ++ (x.testHaskellDepends or [])); }; }).out) packageNames));
    in nixpkgs.runCommand "shell" (ghcEnv.ghcEnvVars // {
      buildInputs = [
        ghcEnv
      ] ++ generalDevTools env ++ tools env;
    }) "";

  workOnMulti = env: packageNames: workOnMulti' { inherit env packageNames; };

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
    "i686-linux"
    "x86_64-darwin"
  ];

  isSuffixOf = suffix: s:
    let suffixLen = builtins.stringLength suffix;
    in builtins.substring (builtins.stringLength s - suffixLen) suffixLen s == suffix;

  pureEnv = platform:
    let haskellPackages = builtins.getAttr platform this;
        ghcWithStuff = if platform == "ghc" || platform == "ghcjs" then haskellPackages.ghcWithHoogle else haskellPackages.ghcWithPackages;
    in ghcWithStuff (p: import ./packages.nix { haskellPackages = p; inherit platform; });

  tryPurePackages = generalDevTools ghc
    ++ builtins.map pureEnv platforms;

  demoVM = (import "${nixpkgs.path}/nixos" {
    configuration = {
      imports = [
        "${nixpkgs.path}/nixos/modules/virtualisation/virtualbox-image.nix"
        "${nixpkgs.path}/nixos/modules/profiles/demo.nix"
      ];
      environment.systemPackages = tryPurePackages;
    };
  }).config.system.build.virtualBoxOVA;

  lib = haskellLib;
  inherit cabal2nixResult sources system iosSupport;
  project = args: import ./project this (args ({ pkgs = nixpkgs; } // this));
  tryPureShell = pinBuildInputs ("shell-" + system) tryPurePackages [];
}; in this
