#!/usr/bin/env bash
set -euo pipefail

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

. "$DIR/common-setup.sh"

CONFIG_DIR="$HOME/.pure-platform"

TMPDIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'cache')
trap "rm -rf \"$TMPDIR\"" EXIT

(
    cd "$DIR"

nix-push --dest "$TMPDIR" --key-file ~/.pure-platform/nixcache.purehs.org-1 "$(nix-instantiate $NIXOPTS --add-root "$DIR/gc-roots/cache.drv" --indirect ./cache.nix "$@")"

    sed -i '/^\(System\|Deriver\): /d' "$TMPDIR/"*.narinfo # Get rid of these, because they can vary in apparently-meaningless between systems

    nix-shell $NIXOPTS -E 'with (import ./. {}).nixpkgs; runCommand "shell" { buildInputs = [ awscli ]; shellHook = "export SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt"; } ""' --run "AWS_CONFIG_FILE=$HOME/.pure-platform/aws/config HOME=/var/empty aws s3 sync --size-only --cache-control 'public, max-age=315360000' --expires 'Tue, 01 Feb 2050 00:00:00 GMT' '$TMPDIR/' s3://nixcache.purehs.org/"
)