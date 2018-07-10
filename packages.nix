{ haskellPackages, platform }:

with haskellPackages;

[
  ##############################################################################
  # Add general packages here                                                  #
  ##############################################################################
  pure
  pure-bench
  pure-cond
  pure-core
  pure-css
  pure-default
  pure-dom
  pure-ease
  pure-events
  pure-html
  pure-json
  pure-lazyloader
  pure-lifted
  pure-limiter
  pure-loader
  pure-localstorage
  pure-modal
  pure-portal
  pure-popup
  pure-prop
  pure-proxy
  pure-queue
  pure-random-pcg
  pure-render
  pure-responsive
  pure-router
  pure-spacetime
  pure-spinners
  pure-sticky
  pure-styles
  pure-svg
  pure-tagsoup
  pure-test
  pure-theme
  pure-time
  pure-timediff-simple
  pure-tlc
  pure-transition
  pure-try
  pure-txt
  pure-txt-trie
  pure-websocket
  pure-server
  pure-uri
  pure-variance
  pure-visibility
  pure-xml
  ef
  excelsior

] ++ (if platform == "ghcjs" then [
  ##############################################################################
  # Add ghcjs-only packages here                                               #
  ##############################################################################

] else []) ++ (if platform == "ghc" then [
  ##############################################################################
  # Add ghc-only packages here                                                 #
  ##############################################################################

] else []) ++ builtins.concatLists (map (x: (x.override { mkDerivation = drv: { out = (drv.buildDepends or []) ++ (drv.libraryHaskellDepends or []) ++ (drv.executableHaskellDepends or []); }; }).out) [ pure pure-bench pure-cond pure-core pure-css pure-default pure-dom pure-ease pure-events pure-html pure-json pure-lazyloader pure-lifted pure-limiter pure-loader pure-localstorage pure-modal pure-portal pure-popup pure-prop pure-proxy pure-random-pcg pure-queue pure-render pure-responsive pure-router pure-spinners pure-sticky pure-styles pure-svg pure-tagsoup pure-test pure-theme pure-time pure-timediff-simple pure-tlc pure-transition pure-try pure-txt pure-txt-trie pure-websocket pure-server pure-uri pure-variance pure-visibility pure-xml ef excelsior ])
