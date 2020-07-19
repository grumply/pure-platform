# This file should not be run directly; it exists to share setup code between the various scripts in this repository
# Before running this script, DIR should be defined equal to the directory containing this script

REPO="https://github.com/grumply/pure-platform"

NIXOPTS=""

LOGFILE="$0.log"

trap "echo 'It looks like a problem occurred.  Please submit an issue at $REPO/issues - include $LOGFILE to provide more information'; exit 1" ERR

echo "Command: " "$0" "$@" >"$LOGFILE"
exec 3>&1
exec 4>&2
exec > >(tee -ia "$LOGFILE")
exec 2> >(tee -ia "$LOGFILE" >&2)

terminate_logging() {
exec 1>&3
exec 2>&4
exec 3>&-
exec 4>&-
}

# Exit because the user caused an error, with the given error code and message
user_error() {
    >&2 echo "$2"
    trap - ERR
    exit "$1"
}

>&2 echo "If you have any trouble with this script, please submit an issue at $REPO/issues"

git_thunk() {
    case "$1" in
        git) echo "import ((import <nixpkgs> {}).fetchgit (builtins.fromJSON (builtins.readFile ./git.json)))" ;;
        github) echo "import ((import <nixpkgs> {}).fetchFromGitHub (builtins.fromJSON (builtins.readFile ./github.json)))" ;;
    esac
}

# NOTE: Returns the manifest type in OUTPUT_GIT_MANIFEST_TYPE and the manifest contents in OUTPUT_GIT_MANIFEST
get_git_manifest() {
    local NIX_PREFETCH_SCRIPTS="$(nix-build --no-out-link -E "(import <nixpkgs> {}).nix-prefetch-scripts")"
    local NIX="$(nix-build --no-out-link -E "(import <nixpkgs> {}).nix")"
    local REPO="$(echo "$1" | sed 's/\.git$//')"

    local URL="$(git -C "$REPO" config --get remote.origin.url | sed 's_^git@github.com:_git://github.com/_')" # Don't use git@github.com origins, since these can't be accessed by nix
    local REV="$(git -C "$REPO" rev-parse HEAD)"

    local GITHUB_PATTERN="^git://github.com/\([^/]*\)/\([^/]*\)$"
    local GITHUB_ARCHIVE_URL="$(echo "$URL" | sed -n "s_${GITHUB_PATTERN}_https://github.com/\1/\2/archive/$REV.tar.gz_p")"
    if [ -n "$GITHUB_ARCHIVE_URL" -a "$(curl -o /dev/null --silent --head --write-out '%{http_code}' "$GITHUB_ARCHIVE_URL")" -ne 404 ] ; then
        OUTPUT_GIT_MANIFEST_TYPE=github
        local GITHUB_OWNER="$(echo "$URL" | sed "s_${GITHUB_PATTERN}_\1_")"
        local GITHUB_REPO="$(echo "$URL" | sed "s_${GITHUB_PATTERN}_\2_")"
        local SHA256="$($NIX/bin/nix-prefetch-url --unpack --type sha256 "$GITHUB_ARCHIVE_URL")"
        OUTPUT_GIT_MANIFEST="$(cat <<EOF
{
  "owner": "$GITHUB_OWNER",
  "repo": "$GITHUB_REPO",
  "rev": "$REV",
  "sha256": "$SHA256"
}
EOF
)"
    else
        OUTPUT_GIT_MANIFEST_TYPE=git
        OUTPUT_GIT_MANIFEST="$("$NIX_PREFETCH_SCRIPTS"/bin/nix-prefetch-git "$PWD/$REPO" "$REV" 2>/dev/null | sed -e '/^ *"date":/d' -e "s|$(echo "$PWD/$REPO" | sed 's/|/\\|/g')|$(echo "$URL" | sed 's/|/\\|/g')|" 2>/dev/null)"
    fi
}

