#!/usr/bin/env bash

# ── pretty print ────────────────────────────────────────────────────────────
info()    { printf "  [i] %s\n" "$*"; }
ok()      { printf "  [\033[32m✓\033[0m] %s\n" "$*"; }
err()     { printf "  [\033[31mx\033[0m] %s\n" "$*" >&2; }
warn()    { printf "  [\033[33m!\033[0m] %s\n" "$*"; }
ask()     { printf "  [?] %s " "$*"; }

# ── defaults ─────────────────────────────────────────────────────────────────
INSTALL_DIR="${1:-$HOME/.vvman}"
VV_SCRIPT_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/vv.sh"
VV_SCRIPT_DST="$INSTALL_DIR/vv.sh"
BASHRC="$HOME/.bashrc"
SOURCE_LINE="source \"$VV_SCRIPT_DST\"  # vvman"

# ── checks ───────────────────────────────────────────────────────────────────
if [[ ! -f "$VV_SCRIPT_SRC" ]]; then
    err "vv.sh not found next to install.sh (looked in $(dirname "$VV_SCRIPT_SRC"))"
    exit 1
fi

# ── banner ───────────────────────────────────────────────────────────────────
echo ""
echo "  vvman installer"
echo "  ───────────────────────────────────────"
info "Install directory : $INSTALL_DIR"
info "Main script       : $VV_SCRIPT_DST"
info "Shell config      : $BASHRC"
echo ""

# ── prompt ───────────────────────────────────────────────────────────────────
warn "The following line will be appended to $BASHRC:"
echo ""
echo "      $SOURCE_LINE"
echo ""
info "Run \`vv uninstall\` at any time to remove it."
echo ""
ask "Proceed? [y/N]"
read -r answer

if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    info "Aborted."
    exit 0
fi

echo ""

# ── create install dir ───────────────────────────────────────────────────────
if [[ -d "$INSTALL_DIR" ]]; then
    warn "Directory already exists: $INSTALL_DIR"
else
    mkdir -p "$INSTALL_DIR" || { err "Failed to create $INSTALL_DIR"; exit 1; }
    ok "Created $INSTALL_DIR"
fi

# ── copy vv.sh ───────────────────────────────────────────────────────────────
cp "$VV_SCRIPT_SRC" "$VV_SCRIPT_DST" || { err "Failed to copy vv.sh"; exit 1; }
chmod +x "$VV_SCRIPT_DST"
ok "Copied vv.sh to $INSTALL_DIR"

# ── write source line to .bashrc ─────────────────────────────────────────────
if grep -qF "# vvman" "$BASHRC" 2>/dev/null; then
    warn "Source line already present in $BASHRC — skipping."
else
    echo "" >> "$BASHRC"
    echo "$SOURCE_LINE" >> "$BASHRC"
    ok "Appended source line to $BASHRC"
fi

# ── done ─────────────────────────────────────────────────────────────────────
echo ""
ok "Installation complete."
info "Reload your shell or run:  source \"$VV_SCRIPT_DST\""
echo ""
