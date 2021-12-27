{ haskellPackages, platform }:

with haskellPackages;

[ pure
  pure-admin
  pure-async
  pure-auth
  pure-autogrid
  pure-backdrop
  pure-bench
  pure-bloom
  pure-cache
  pure-cached
  pure-capability
  pure-cond
  pure-conjurer
  pure-contenteditable
  pure-contexts
  pure-convoker
  pure-core
  pure-css
  pure-default
  pure-dom
  pure-ease
  pure-elm
  pure-events
  pure-fetch
  pure-forms
  pure-gestures
  pure-grid
  pure-hooks
  pure-html
  pure-intersection
  pure-json
  pure-lazyloader
  pure-lifted
  pure-limiter
  pure-loader
  pure-localstorage
  pure-locker
  pure-magician
  pure-marker
  pure-maybe
  pure-media-library
  pure-modal
  pure-mutation
  pure-notifications
  pure-paginate
  pure-parse
  pure-periodically
  # pure-portal
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
  pure-ribbon
  pure-scroll-loader
  pure-search
  pure-selection
  pure-shadows
  pure-sorcerer
  pure-spacetime
  pure-spinners
  pure-state
  pure-statusbar
  pure-sticky
  pure-stream
  pure-styles
  pure-suspense
  pure-svg
  pure-sync
  pure-tagsoup
  pure-template
  pure-test
  pure-theme
  pure-time
  pure-tlc
  pure-transform
  pure-transition
  pure-try
  pure-txt
  pure-txt-interpolate
  pure-txt-search
  pure-txt-trie
  pure-websocket
  pure-websocket-cache
  pure-server
  pure-uri
  pure-variance
  pure-visibility
  pure-xhr
  pure-xml
  pure-xss-sanitize
  ef
  excelsior
  origami-fold

  pure-semantic-ui

] ++ (if platform == "ghcjs" then [
  ##############################################################################
  # Add ghcjs-only packages here                                               #
  ##############################################################################

] else []) ++ (if platform == "ghc" then [
  ##############################################################################
  # Add ghc-only packages here                                                 #
  ##############################################################################

] else []) ++ builtins.concatLists (map (x: (x.override { mkDerivation = drv: {
  out = (drv.buildDepends or []) ++ (drv.libraryHaskellDepends or []) ++
  (drv.executableHaskellDepends or []); }; }).out) 
    [ pure 
      pure-admin
      pure-async 
      pure-auth 
      pure-autogrid 
      pure-backdrop 
      pure-bench 
      pure-bloom 
      pure-cache 
      pure-cached 
      pure-capability 
      pure-cond 
      pure-conjurer
      pure-contenteditable 
      pure-contexts 
      pure-convoker
      pure-core 
      pure-css 
      pure-default 
      pure-dom 
      pure-ease 
      pure-elm 
      pure-events 
      pure-fetch 
      pure-forms 
      pure-gestures 
      pure-grid 
      pure-hooks 
      pure-html 
      pure-intersection 
      pure-json 
      pure-lazyloader 
      pure-lifted 
      pure-limiter 
      pure-loader 
      pure-localstorage 
      pure-locker 
      pure-magician
      pure-marker 
      pure-modal 
      pure-maybe 
      pure-media-library 
      pure-mutation 
      pure-notifications 
      pure-periodically 
      pure-paginate 
      pure-parse 
      pure-popup 
      pure-prop 
      pure-proxy 
      pure-random-pcg 
      pure-queue 
      pure-radar 
      pure-render 
      pure-readfile 
      pure-responsive 
      pure-router 
      pure-ribbon 
      pure-scroll-loader 
      pure-search 
      pure-selection 
      pure-shadows 
      pure-spinners 
      pure-state 
      pure-statusbar 
      pure-sticky 
      pure-stream 
      pure-styles 
      pure-suspense 
      pure-svg 
      pure-sync 
      pure-tagsoup 
      pure-template 
      pure-test 
      pure-theme 
      pure-time 
      pure-tlc 
      pure-transform 
      pure-transition 
      pure-try 
      pure-txt 
      pure-txt-interpolate 
      pure-txt-search 
      pure-txt-trie 
      pure-websocket 
      pure-websocket-cache 
      pure-server 
      pure-uri 
      pure-variance 
      pure-visibility 
      pure-xhr 
      pure-xml 
      pure-xss-sanitize 
      ef 
      excelsior 
      origami-fold 
      pure-sorcerer 
      pure-semantic-ui
    ])
