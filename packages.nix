{ haskellPackages, platform }:

with haskellPackages;

[
  ##############################################################################
  # Add general packages here                                                  #
  ##############################################################################
  ef
  ef-base
  tlc
  trivial
  pure-core
  pure-default
  pure-dom
  pure-ease
  pure-events
  pure-html
  pure-json
  pure-lifted
  pure-queue
  pure-styles
  pure-svg
  pure-time
  pure-try
  pure-txt

] ++ (if platform == "ghcjs" then [
  ##############################################################################
  # Add ghcjs-only packages here                                               #
  ##############################################################################

] else []) ++ (if platform == "ghc" then [
  ##############################################################################
  # Add ghc-only packages here                                                 #
  ##############################################################################

] else []) ++ builtins.concatLists (map (x: (x.override { mkDerivation = drv: { out = (drv.buildDepends or []) ++ (drv.libraryHaskellDepends or []) ++ (drv.executableHaskellDepends or []); }; }).out) [ ef ef-base tlc trivial pure-core pure-default pure-dom pure-ease pure-events pure-html pure-json pure-lifted pure-queue pure-styles pure-svg pure-time pure-try pure-txt ])
