{ system ? builtins.currentSystem }:
(import ./. { inherit system; }).tryPureShell