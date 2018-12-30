{ haskellPackages, platform }:

with haskellPackages;

[
  ##############################################################################
  # Add general packages here                                                  #
  ##############################################################################
  pure
  pure-cond
  pure-core
  pure-css
  pure-default
  pure-dom
  pure-ease
  pure-events
  pure-forms
  pure-grid
  pure-html
  pure-json
  pure-lazyloader
  pure-lifted
  pure-limiter
  pure-loader
  pure-localstorage
  pure-modal
  pure-paginate
  pure-portal
  pure-popup
  pure-prop
  pure-proxy
  pure-queue
  pure-radar
  pure-random-pcg
  pure-render
  pure-readfile
  pure-responsive
  pure-router
  pure-scroll-loader
  pure-search
  pure-spacetime
  pure-spinners
  pure-state
  pure-sticky
  pure-styles
  pure-svg
  pure-tagsoup
  pure-template
  pure-test
  pure-theme
  pure-time
  pure-tlc
  pure-transition
  pure-try
  pure-txt
  pure-txt-interpolate
  pure-txt-search
  pure-txt-trie
  pure-websocket
  pure-server
  pure-uri
  pure-variance
  pure-visibility
  pure-xml
  ef
  excelsior

  pure-semantic-ui

] ++ (if platform == "ghcjs" then [
  ##############################################################################
  # Add ghcjs-only packages here                                               #
  ##############################################################################

] else []) ++ (if platform == "ghc" then [
  ##############################################################################
  # Add ghc-only packages here                                                 #
  ##############################################################################

] else []) ++ builtins.concatLists (map (x: (x.override { mkDerivation = drv: { out = (drv.buildDepends or []) ++ (drv.libraryHaskellDepends or []) ++ (drv.executableHaskellDepends or []); }; }).out) [ pure pure-cond pure-core pure-css pure-default pure-dom pure-ease pure-events pure-forms pure-grid pure-html pure-json pure-lazyloader pure-lifted pure-limiter pure-loader pure-localstorage pure-modal pure-paginate pure-portal pure-popup pure-prop pure-proxy pure-random-pcg pure-queue pure-radar pure-render pure-readfile pure-responsive pure-router pure-scroll-loader pure-search pure-spinners pure-state pure-sticky pure-styles pure-svg pure-tagsoup pure-template pure-test pure-theme pure-time pure-tlc pure-transition pure-try pure-txt pure-txt-interpolate pure-txt-search pure-txt-trie pure-websocket pure-server pure-uri pure-variance pure-visibility pure-xml ef excelsior pure-semantic-ui])
