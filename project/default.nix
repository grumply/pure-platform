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
#     })
#
# > example commands
#
#     $ nix-build -A ghc.backend
#     $ nix-build -A ghcjs.frontend
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

, minimal ? false
  # :: Bool
  #
  # A flag to disable testing, coverage, documentation generation, and
  # profiling. For finer-grained control, use `overrides`. e.g.
  #
  #    overrides = self: super: {
  #      mkDerivation = args: super.mkDerivation (args // {
  #        doCheck = true;
  #        doCoverage = true;
  #        doBenchmark = true;
  #        enableLibraryProfiling = true;
  #        doHaddock = true;
  #      });
  #    };
  #
  # See https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/haskell-modules/generic-builder.nix
  # for the haskell.mkDerivation specification.

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
  #
  # See https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/haskell-modules/generic-builder.nix
  # for the haskell.mkDerivation specification.

, shellToolOverrides ? _: _: {}
  # A function returning a record of tools to provide in the
  # nix-shells.
  #
  #     shellToolOverrides = ghc: super: {
  #       inherit (ghc) hpack;
  #       inherit (pkgs) chromium;
  #       ghc-mod = null;
  #       cabal-install = ghc.callHackage "cabal-install" "2.0.0.1" {};
  #       ghcid = pkgs.haskell.lib.justStaticExecutables super.ghcid;
  #     };
  #
  # Some tools, like `ghc-mod`, have to be built with the same GHC as
  # your project. The argument to the `tools` function is the haskell
  # package set of the platform we are developing for, allowing you to
  # build tools with the correct Haskell package set.
  #
  # The second argument, `super`, is the record of tools provided by
  # default. You can override these defaults by returning values with
  # the same name in your record. They can be disabled by setting them
  # to null.

, tools ? _: []
  # A function returning the list of tools to provide in the
  # nix-shells.
  #
  #     tools = ghc: with ghc; [
  #       pkgs.chromium
  #     ];
  #
  # Some tools, like `ghc-mod`, have to be built with the same GHC as
  # your project. The argument to the `tools` function is the haskell
  # package set of the platform we are developing for, allowing you to
  # build tools with the correct Haskell package set.

, withHoogle ? false
  # Set to true to enable building the hoogle database when entering
  # the nix-shell.

}:
let
  overrides' = nixpkgs.lib.foldr nixpkgs.lib.composeExtensions (_: _: {}) [
    (self: super: mapAttrs (name: path: self.callCabal2nix name path {}) packages)
    (self: super: { mkDerivation = args: super.mkDerivation (args // {
        doCheck = !minimal;
        enableLibraryProfiling = !minimal;
        doHaddock = !minimal;
      });
    })
    overrides
  ];
  mkPkgSet = name: _: this.${name}.override { overrides = overrides'; };
  prj = mapAttrs mkPkgSet shells // {
    shells = mapAttrs (name: pnames:
      this.workOnMulti' {
        env = prj.${name}.override { overrides = self: super: nixpkgs.lib.optionalAttrs withHoogle {
          ghcWithPackages = self.ghcWithHoogle;
        }; };
        packageNames = pnames;
        inherit tools shellToolOverrides;
      }
    ) shells;

    pure = this;
    pure-async = this;
    pure-bench = this;
    pure-bloom = this;
    pure-cache = this;
    pure-cached = this;
    pure-capability = this;
    pure-cond = this;
    pure-contexts = this;
    pure-core = this;
    pure-css = this;
    pure-default = this;
    pure-dom = this;
    pure-ease = this;
    pure-elm = this;
    pure-events = this;
    pure-fetch = this;
    pure-forms = this;
    pure-gestures = this;
    pure-grid = this;
    pure-hooks = this;
    pure-html = this;
    pure-intersection = this;
    pure-json = this;
    pure-lazyloader = this;
    pure-lifted = this;
    pure-limiter = this;
    pure-loader = this;
    pure-localstorage = this;
    pure-locker = this;
    pure-marker = this;
    pure-maybe = this;
    pure-modal = this;
    pure-mutation = this;
    pure-paginate = this;
    pure-periodically = this;
    # pure-portal = this;
    pure-popup = this;
    pure-prop = this;
    pure-proxy = this;
    pure-queue = this;
    pure-radar = this;
    pure-random-pcg = this;
    pure-readfile = this;
    pure-render = this;
    pure-responsive = this;
    pure-router = this;
    pure-scroll-loader = this;
    pure-search = this;
    pure-spacetime = this;
    pure-spinners = this;
    pure-state = this;
    pure-sticky = this;
    pure-stream = this;
    pure-styles = this;
    pure-suspense = this;
    pure-svg = this;
    pure-tagsoup = this;
    pure-template = this;
    pure-test = this;
    pure-theme = this;
    pure-time = this;
    pure-tlc = this;
    pure-transition = this;
    pure-try = this;
    pure-txt = this;
    pure-txt-interpolate = this;
    pure-txt-search = this;
    pure-txt-trie = this;
    pure-websocket = this;
    pure-server = this;
    pure-uri = this;
    pure-variance = this;
    pure-visibility = this;
    pure-xhr = this;
    pure-xss-sanitize = this;
    pure-xml = this;
    ef = this;
    excelsior = this;
    sorcerer = this;

    pure-semantic-ui = this;

  };
in prj
