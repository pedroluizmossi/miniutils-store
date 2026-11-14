#!/usr/bin/env bash
# Publishes (adds or updates) an app in the store, from its repository and tag.
#
#   tools/publish.sh pedroluizmossi/miniutils-apps repos-v0.2.0
#   tools/publish.sh pedroluizmossi/miniutils-plugin-pulso v0.3.0
#   tools/publish.sh owner/repo main --app-version 0.3.0 --path my-app --license MIT
#
# Steps: updates main; `miniutils --store-entry` builds the entry from the manifest at that
# commit (and, for an external app, the tag's Release, checking each executable's SHA-256);
# test-installs it into a throwaway folder; shows the diff and the link to compare the code;
# after your "s", signs with MINIUTILS_STORE_KEY, checks the signature and pushes.
#
# Needs: git, a miniutils build with --store-entry, MINIUTILS_STORE_KEY (private key path).
source "$(dirname "$0")/lib.sh"

[[ $# -ge 2 ]] || die "uso: tools/publish.sh <dono/repo | https://…> <tag> [--path p] [--app-version v] [--license l]"
repo=$1
tag=$2
shift 2

require_key
require_clean_main

"$MINIUTILS" --store-entry registry.json "$repo" "$tag" "$@" | tee "$TMP/report"
id=$(sed -n 's/^id: //p' "$TMP/report")
version=$(sed -n 's/^version: //p' "$TMP/report")
[[ -n "$id" && -n "$version" ]] || die "o miniutils não disse qual app atualizou"

verify_index "$id"

echo
git --no-pager diff --stat registry.json
git --no-pager diff registry.json
echo
echo "Revise o código antes de assinar (link 'comparar' acima, ou o repositório no commit novo)."
if ! ask "Assinar e publicar $id $version?"; then
    git checkout -q -- registry.json
    echo "cancelado: registry.json voltou ao que era"
    exit 1
fi
sign_and_push "store: $id $version"
