#!/usr/bin/env bash
# Accepts a pull request that adds or updates an app (someone else's, or one opened by hand).
#
#   tools/accept.sh 12
#
# Steps: checks out the PR; refuses it if it touches anything but registry.json; shows the
# diff; test-installs every entry from the PR's index into a throwaway folder; after your
# "s", merges exactly the commit that was checked (--match-head-commit), then signs on main,
# checks the signature and pushes.
#
# Needs: git, gh (logged in), a miniutils build with --store-entry, MINIUTILS_STORE_KEY.
source "$(dirname "$0")/lib.sh"

[[ $# -eq 1 && "$1" =~ ^[0-9]+$ ]] || die "uso: tools/accept.sh <número do PR>"
pr=$1
command -v gh >/dev/null || die "precisa do gh (GitHub CLI) com login"

require_key
require_clean_main

head=$(gh pr view "$pr" --json headRefOid --jq .headRefOid)
files=$(gh pr view "$pr" --json files --jq '.files[].path')
[[ "$files" == "registry.json" ]] || die "o PR $pr mexe em mais do que registry.json:"$'\n'"$files"

gh pr checkout "$pr" --detach >/dev/null
[[ "$(git rev-parse HEAD)" == "$head" ]] || die "o PR mudou durante a conferência; rode de novo"
git --no-pager diff main...HEAD -- registry.json
verify_index
cp registry.json "$TMP/checked.json"
git checkout -q main

echo
echo "Revise o código de cada app que mudou (repositório e commit do diff acima)."
ask "Aceitar o PR $pr e assinar?" || { echo "cancelado"; exit 1; }

gh pr merge "$pr" --squash --match-head-commit "$head" --delete-branch
git pull -q --ff-only
# sign only what was checked (a squash on top of a newer main could differ)
cmp -s registry.json "$TMP/checked.json" || die "o registry.json do main depois do merge não é o conferido; confira e assine à mão"
sign_and_push "store: sign after #$pr"
