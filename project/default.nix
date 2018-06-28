this:

let
  inherit (this) nixpkgs;
  inherit (nixpkgs.lib) mapAttrs mapAttrsToList escapeShellArg 
    optionalString concatStringsSep concatMapStringsSep;
in

# This function simplifies the definition of Haskell projects that
# have multiple packages. It provides shells for incrementally working
# on all your packages at once using `cabal.project` files, using any
# version of GHC provided by `pure-platform`, including GHCJS. It
# also produces individual derivations for each package, which can
# ease devops or integration with other Nix setups.
#
# Example:
#
# > default.nix
#
#     (import ./pure-platform {}).project ({ pkgs, ... }: {
#       packages = {
#         common = ./common;
#         backend = ./backend;
#         frontend = ./frontend;
#       };
#
#       shells = {
#         ghc = ["common" "backend" "frontend"];
#         ghcjs = ["common" "frontend"];
#       };
#
#       android.frontend = {
#         executableName = "frontend";
#         applicationId = "org.example.frontend";
#         displayName = "Example App";
#       };
#     })
#
# > example commands
#
#     $ nix-build -A ghc.backend
#     $ nix-build -A ghcjs.frontend
#     $ nix-build -A android.frontend
#     $ nix-shell -A shells.ghc
#     $ nix-shell -A shells.ghcjs
#
{ name ? "pure-project"
  # An optional name for your entire project.

, packages
  # :: { <package name> :: Path }
  #
  # An attribute set of local packages being developed. Keys are the
  # cabal package name and values are the path to the source
  # directory.

, shells ? {}
  # :: { <platform name> :: [PackageName] }
  #
  # The `shells` field defines which platforms we'd like to develop
  # for, and which packages' dependencies we want available in the
  # development sandbox for that platform. Note in the example above
  # that specifying `common` is important; otherwise it will be
  # treated as a dependency that needs to be built by Nix for the
  # sandbox. You can use these shells with `cabal.project` files to
  # build all three packages in a shared incremental environment, for
  # both GHC and GHCJS.

, overrides ? _: _: {}
  # :: PackageSet -> PackageSet ->  { <package name> :: Derivation }
  #
  # A function for overriding Haskell packages. You can use
  # `callHackage` and `callCabal2nix` to bump package versions or
  # build them from GitHub. e.g.
  #
  #     overrides = self: super: {
  #       lens = self.callHackage "lens" "4.15.4" {};
  #       free = self.callCabal2nix "free" (pkgs.fetchFromGitHub {
  #         owner = "ekmett";
  #         repo = "free";
  #         rev = "a0c5bef18b9609377f20ac6a153a20b7b94578c9";
  #         sha256 = "0vh3hj5rj98d448l647jc6b6q1km4nd4k01s9rajgkc2igigfp6s";
  #       }) {};
  #     };

, tools ? _: []
  # A function returning the list of tools to provide in the
  # nix-shells.
  #
  #     tools = ghc: with ghc; [
  #       hpack
  #       pkgs.chromium
  #     ];
  #
  # Some tools, like `ghc-mod`, have to be built with the same GHC as
  # your project. The argument to the `tools` function is the haskell
  # package set of the platform we are developing for, allowing you to
  # build tools with the correct Haskell package set.

, withHoogle ? true
  # Set to false to disable building the hoogle database when entering
  # the nix-shell.

, android ? {}
  # ::
  # { <app name> ::
  #   { executableName :: String
  #   , applicationId :: String
  #   , displayName :: String
  #   , package :: PackageSet -> Derivation
  #     ^ Optional
  #   }
  # }
  #
  # Use this argument to configure android apps. The returned
  # derivations will be in `android.<app name>`. The `package`
  # argument can be set to use a different Haskell package than the
  # one named <app name>.

, ios ? {}
  # ::
  # { <app name> ::
  #   { executableName :: String
  #   , bundleIdentifier :: String
  #   , bundleName :: String
  #   , package :: PackageSet -> Derivation
  #     ^ Optional
  #   }
  # }
  #
  # Use this argument to configure iOS apps. The returned derivations
  # will be in `ios.<app name>`. The `package` argument can be set to
  # use a different Haskell package than the one named <app name>.

}:
let
  overrides' = nixpkgs.lib.composeExtensions
    (self: super: mapAttrs (name: path: self.callCabal2nix name path {}) packages) overrides;
  mkPkgSet = name: _: this.${name}.override { overrides = overrides'; };
  prj = mapAttrs mkPkgSet shells // {
    shells = mapAttrs (name: pnames:
      this.workOnMulti' {
        env = prj.${name}.override { overrides = self: super: nixpkgs.lib.optionalAttrs withHoogle {
          ghcWithPackages = self.ghcWithHoogle;
        }; };
        packageNames = pnames;
        inherit tools;
      }
    ) shells;

    android =
      mapAttrs (name: config:
        let
          ghcAndroidArm64 = this.ghcAndroidArm64.override { overrides = overrides'; };
          ghcAndroidArmv7a = this.ghcAndroidArmv7a.override { overrides = overrides'; };
        in (this.androidWithHaskellPackages { inherit ghcAndroidArm64 ghcAndroidArmv7a; }).buildApp
          ({ package = p: p.${name}; } // config)
      ) android;

    ios =
      mapAttrs (name: config:
        let ghcIosArm64 = this.ghcIosArm64.override { overrides = overrides'; };
        in (this.iosWithHaskellPackages ghcIosArm64).buildApp
          ({ package = p: p.${name}; } // config)
      ) ios;

    pure = this;
    pure-cond = this;
    pure-core = this;
    pure-css = this;
    pure-default = this;
    pure-dom = this;
    pure-ease = this;
    pure-events = this;
    pure-html = this;
    pure-json = this;
    pure-lifted = this;
    pure-limiter = this;
    pure-localstorage = this;
    pure-queue = this;
    pure-random-pcg = this;
    pure-render = this;
    pure-router = this;
    pure-styles = this;
    pure-svg = this;
    pure-tagsoup = this;
    pure-theme = this;
    pure-time = this;
    pure-transition = this;
    pure-try = this;
    pure-txt = this;
    pure-txt-trie = this;
    pure-websocket = this;
    pure-server = this;
    pure-uri = this;
    pure-xml = this;
    ef = this;
    excelsior = this;

    all = all true;
  };

  ghcLinks = mapAttrsToList (name: pnames: optionalString (pnames != []) ''
    mkdir -p $out/${escapeShellArg name}
    ${concatMapStringsSep "\n" (n: ''
      ln -s ${prj.${name}.${n}} $out/${escapeShellArg name}/${escapeShellArg n}
    '') pnames}
  '') shells;
  mobileLinks = mobileName: mobile: ''
    mkdir -p $out/${escapeShellArg mobileName}
    ${concatStringsSep "\n" (mapAttrsToList (name: app: ''
      ln -s ${app} $out/${escapeShellArg mobileName}/${escapeShellArg name}
    '') mobile)}
  '';

  all = includeRemoteBuilds:
    let tracedMobileLinks = mobileName: system: mobile:
      let
        build = mobileLinks mobileName mobile;
        msg = ''
          Skipping ${mobileName} apps; system is ${this.system}, but ${system} is needed.
          Use `nix-build -A all` to build with remote machines.
          See: https://nixos.org/nixos/manual/options.html#opt-nix.buildMachines
        '';
      in if mobile == {} then ""
        else if includeRemoteBuilds then build
          else if system != this.system then builtins.trace msg ""
            # TODO: This is a bit of a hack. `this.iosSupport` prints
            # a warning and returns false when *the local system*
            # doesn't have the SDK. Just because `includeRemoteBuilds`
            # is off doesn't mean we know this is the system iOS apps
            # will build on. Nonetheless, it's important not to
            # evaluate `this.iosSupport` if we don't need to, as it
            # may `trace` an unnecessary warning.
            else if system == "x86_64-darwin" -> this.iosSupport then build
              else "";
    in nixpkgs.runCommand name { passthru = prj; preferLocalBuild = true; } ''
      ${concatStringsSep "\n" ghcLinks}
      ${tracedMobileLinks "android" "x86_64-linux" prj.android}
      ${tracedMobileLinks "ios" "x86_64-darwin" prj.ios}
    '';
in all false
