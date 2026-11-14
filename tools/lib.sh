# Shared by publish.sh and accept.sh. Everything runs on the maintainer's machine: the
# private key never leaves it and nothing here needs a token or a GitHub secret.

set -euo pipefail

die() {
    echo "erro: $*" >&2
    exit 1
}

ask() {
    local answer
    read -r -p "$1 [s/N] " answer
    [[ "$answer" =~ ^([sS]|sim|[yY]|yes)$ ]]
}

# The store repository root (scripts can be called from anywhere).
STORE=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$STORE"

# The miniutils binary: $MINIUTILS, then the PATH, then a hub build next to this repository.
find_miniutils() {
    if [[ -n "${MINIUTILS:-}" ]]; then
        echo "$MINIUTILS"
        return
    fi
    if command -v miniutils >/dev/null 2>&1; then
        command -v miniutils
        return
    fi
    local b
    for b in ../hub-app-rust/target/release/miniutils ../hub-app-rust/target/debug/miniutils; do
        for exe in "$b" "$b.exe"; do
            [[ -x "$exe" ]] && { echo "$STORE/$exe"; return; }
        done
    done
    die "não achei o miniutils: ponha no PATH ou defina MINIUTILS=/caminho/do/miniutils"
}

MINIUTILS=$(find_miniutils)
"$MINIUTILS" --help 2>/dev/null | grep -q -- "--store-entry" \
    || die "$MINIUTILS é antigo (não tem --store-entry): compile o hub de novo"

# The private key: $MINIUTILS_STORE_KEY (never inside this repository).
require_key() {
    [[ -n "${MINIUTILS_STORE_KEY:-}" ]] || die "defina MINIUTILS_STORE_KEY com o caminho da chave privada da loja"
    [[ -f "$MINIUTILS_STORE_KEY" ]] || die "$MINIUTILS_STORE_KEY não existe"
    case "$(cd "$(dirname "$MINIUTILS_STORE_KEY")" && pwd)/" in
        "$STORE"/*) die "a chave privada não pode ficar dentro do repositório da loja" ;;
    esac
}

require_clean_main() {
    git diff --quiet && git diff --cached --quiet || die "há mudanças não commitadas em $STORE"
    git checkout -q main
    git pull -q --ff-only
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Installs each entry from the local index into a throwaway folder, the way a user would:
# exact commit, grants equal to the manifest, the view opens and (external app) the
# executable for this OS matches the SHA-256. Nothing touches the real MiniUtils folders.
verify_index() {
    local ids=("$@") id
    if [[ ${#ids[@]} -eq 0 ]]; then
        mapfile -t ids < <(grep -o '"id": "[^"]*"' registry.json | sed 's/"id": "\(.*\)"/\1/')
    fi
    for id in "${ids[@]}"; do
        echo "== conferindo $id (instalação de teste)"
        rm -rf "$TMP/plugins" "$TMP/data"
        MINIUTILS_PLUGINS="$TMP/plugins" MINIUTILS_DATA="$TMP/data" \
            "$MINIUTILS" --install "$id" "$STORE/registry.json" --yes >"$TMP/install.log" 2>&1 \
            || { cat "$TMP/install.log"; die "$id não instala a partir deste índice"; }
        echo "   ok"
    done
}

# Signs, checks the signature with the published public key, commits and pushes.
sign_and_push() {
    local message=$1
    "$MINIUTILS" --store-sign registry.json "$MINIUTILS_STORE_KEY" >/dev/null
    MINIUTILS_PLUGINS="$TMP/plugins" "$MINIUTILS" --store "$STORE/registry.json" --key "$(tr -d '[:space:]' <store-key.pub)" \
        | grep -qE '\((signature checked|assinatura conferida)\):' \
        || { git checkout -q -- registry.json.sig; die "a assinatura não confere com store-key.pub (chave errada?); nada foi enviado"; }
    git add registry.json registry.json.sig
    git commit -q -m "$message"
    git push -q origin main
    echo "publicado: $message ($(git rev-parse --short HEAD))"
}
