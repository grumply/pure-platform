### Enabling the binary cache on NixOS

When using Nix on NixOS, only root can add binary caches to the system.  This will force `try-pure` to rebuild GHCJS from scratch, which takes hours.  To use the binary cache, you can add the following lines to your `/etc/nixos/configuration.nix`:

```
nix.binaryCaches = [ "https://cache.nixos.org" "https://nixcache.purehs.org" ];
nix.binaryCachePublicKeys = [ "nixcache.purehs.org.key:I56gZt71cbMA6tm8x+1gD6fQyITnE+Q4DgNQIXd7sJg="
];
```

If you already have one of these variables set up, just add these values to the existing lists.

Once it's been added, run `sudo nixos-rebuild switch` to make the change take effect, then run `./try-pure` as normal.

Note: If you'd prefer not to use `nixcache.purehs.org` by default on your system, you can add it to `nix.trustedBinaryCaches` instead of `nix.binaryCaches`.  This way, scripts like `try-pure` will be allowed to use it, but other nix commands will ignore it.  Once it's in `nix.trustedBinaryCaches`, you can always pass `--option extra-binary-caches https://nixcache.purehs.org` to nix commands such as `nix-build` and `nix-shell` manually if you'd like to use it for a particular build.