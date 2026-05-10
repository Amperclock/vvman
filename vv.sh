#!/usr/bin/env bash

# ── pretty print ─────────────────────────────────────────────────────────────
_vv_info() { printf "  [i] %s\n" "$*"; }
_vv_ok()   { printf "  [\033[32m✓\033[0m] %s\n" "$*"; }
_vv_err()  { printf "  [\033[31mx\033[0m] %s\n" "$*" >&2; }
_vv_warn() { printf "  [\033[33m!\033[0m] %s\n" "$*"; }

# ── resolve install dir (script lives inside it); work when sourced ───────────
_VV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_VV_ENVS="$_VV_DIR/envs"

# ── detect python ─────────────────────────────────────────────────────────────
_vv_find_python() {
    local candidate version
    for candidate in python3 python python3.13 python3.12 python3.11 python3.10; do
        if command -v "$candidate" &>/dev/null; then
            version="$("$candidate" --version 2>&1)"
            # require Python 3.x
            if [[ "$version" =~ Python\ 3\. ]]; then
                echo "$candidate"
                return 0
            fi
        fi
    done
    return 1
}

_VV_PYTHON="$(_vv_find_python)"
if [[ -z "$_VV_PYTHON" ]]; then
    _vv_warn "No Python 3 found on PATH — \`vv add\` will not work."
fi

# ── main function ─────────────────────────────────────────────────────────────
vv() {
    local cmd="${1:-}"
    shift || true

    case "$cmd" in

        # ── vv add <name> ─────────────────────────────────────────────────────
        add)
            local name="${1:-}"
            if [[ -z "$name" ]]; then
                _vv_err "Usage: vv add <name>"
                return 1
            fi

            if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                _vv_err "Invalid name '$name'. Use only letters, numbers, - and _."
                return 1
            fi

            local reserved
            for reserved in add list remove uninstall; do
                if [[ "$name" == "$reserved" ]]; then
                    _vv_err "'$name' is a reserved command name."
                    return 1
                fi
            done

            if [[ -z "$_VV_PYTHON" ]]; then
                _vv_err "No Python 3 found. Install Python 3 and reload your shell."
                return 1
            fi

            local env_path="$_VV_ENVS/$name"
            if [[ -d "$env_path" ]]; then
                _vv_err "Env '$name' already exists."
                return 1
            fi

            _vv_info "Creating '$name' with $($_VV_PYTHON --version 2>&1) ..."
            mkdir -p "$_VV_ENVS"
            if "$_VV_PYTHON" -m venv "$env_path"; then
                _vv_ok "Env '$name' created at $env_path"
            else
                _vv_err "Failed to create env '$name'."
                return 1
            fi
            ;;

        # ── vv list [-v] ──────────────────────────────────────────────────────
        list)
            local verbose=0
            [[ "${1:-}" == "-v" || "${1:-}" == "--verbose" ]] && verbose=1

            if [[ ! -d "$_VV_ENVS" ]] || [[ -z "$(ls -A "$_VV_ENVS" 2>/dev/null)" ]]; then
                _vv_info "No envs yet. Use \`vv add <name>\` to create one."
                return 0
            fi

            if (( verbose )); then
                printf "\n  %-20s  %-12s  %-10s  %s\n" "NAME" "CREATED" "PACKAGES" "PYTHON"
            else
                printf "\n  %-20s  %-12s  %s\n" "NAME" "CREATED" "PYTHON"
            fi
            printf "  %s\n" "──────────────────────────────────────────────────────────"

            local env
            for env in "$_VV_ENVS"/*/; do
                [[ -d "$env" ]] || continue
                local name created py_ver

                name="$(basename "$env")"
                created="$(date -r "$env" "+%Y-%m-%d" 2>/dev/null || stat -c "%y" "$env" | cut -d' ' -f1)"
                py_ver="$("$env/bin/python" --version 2>&1 | awk '{print $2}')"

                if (( verbose )); then
                    local pkg_count pip_bin
                    pip_bin="$env/bin/pip"
                    if [[ -x "$pip_bin" ]]; then
                        pkg_count="$("$pip_bin" list --format=columns 2>/dev/null | tail -n +3 | wc -l | tr -d ' ')"
                    else
                        pkg_count="?"
                    fi
                    printf "  %-20s  %-12s  %-10s  %s\n" "$name" "$created" "$pkg_count" "$py_ver"
                else
                    printf "  %-20s  %-12s  %s\n" "$name" "$created" "$py_ver"
                fi
            done
            echo ""
            ;;

        # ── vv remove <name> ──────────────────────────────────────────────────
        remove)
            local name="${1:-}"
            if [[ -z "$name" ]]; then
                _vv_err "Usage: vv remove <name>"
                return 1
            fi

            if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                _vv_err "Invalid name '$name'. Use only letters, numbers, - and _."
                return 1
            fi

            local env_path="$_VV_ENVS/$name"
            if [[ ! -d "$env_path" ]]; then
                _vv_err "Env '$name' not found."
                return 1
            fi

            _vv_warn "This will permanently delete '$env_path'."
            printf "  [?] Confirm removal of '$name'? [y/N] "
            read -r answer
            if [[ ! "$answer" =~ ^[Yy]$ ]]; then
                _vv_info "Aborted."
                return 0
            fi

            rm -rf "$env_path"
            _vv_ok "Env '$name' removed."
            ;;

        # ── vv uninstall ──────────────────────────────────────────────────────
        uninstall)
            local bashrc="$HOME/.bashrc"
            local bashrc_backup="$HOME/.bashrc.before_removing_vvman"

            _vv_warn "This will permanently remove $_VV_DIR and the source line from $bashrc."
            printf "  [?] Proceed with uninstall? [y/N] "
            read -r answer
            if [[ ! "$answer" =~ ^[Yy]$ ]]; then
                _vv_info "Aborted."
                return 0
            fi

            # ── backup .bashrc ─────────────────────────────────────────────
            cp "$bashrc" "$bashrc_backup" || { _vv_err "Failed to backup $bashrc"; return 1; }
            _vv_ok "Backed up $bashrc → $bashrc_backup"

            # ── find source line ───────────────────────────────────────────
            local match
            match="$(grep -n "# vvman" "$bashrc" 2>/dev/null)"

            if [[ -z "$match" ]]; then
                _vv_warn "Could not find the vvman source line in $bashrc."
                _vv_warn "Remove it manually, then delete $_VV_DIR."
                return 1
            fi

            local line_num line_content
            line_num="$(echo "$match" | cut -d: -f1)"
            line_content="$(echo "$match" | cut -d: -f2-)"

            echo ""
            _vv_info "Found source line at $bashrc:$line_num"
            printf "  \033[33m%4s\033[0m  %s\n" "$line_num" "$line_content"
            echo ""
            printf "  [?] Delete this line? [y/N] "
            read -r answer
            if [[ ! "$answer" =~ ^[Yy]$ ]]; then
                _vv_info "Aborted. Directory not removed. Delete the source line manually."
                return 0
            fi

            sed -i "${line_num}d" "$bashrc"
            _vv_ok "Source line removed from $bashrc"

            # ── remove install dir ─────────────────────────────────────────
            rm -rf "$_VV_DIR"
            _vv_ok "Removed $_VV_DIR"

            # ── clean up shell session ─────────────────────────────────────
            printf "  [\033[32m✓\033[0m] %s\n" "vvman uninstalled. Reload shell to finalize."
            unset -f vv _vv_find_python _vv_info _vv_ok _vv_err _vv_warn
            unset _VV_DIR _VV_ENVS _VV_PYTHON
            ;;

        # ── unknown / no command ──────────────────────────────────────────────
        "")
            _vv_info "Usage: vv <command> [args]"
            _vv_info "Commands: add, list, remove, uninstall"
            _vv_info "Activate: vv <name>"
            ;;

        # ── vv <name> — activate ──────────────────────────────────────────────
        *)
            if [[ ! "$cmd" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                _vv_err "Invalid name '$cmd'. Use only letters, numbers, - and _."
                return 1
            fi
            local env_path="$_VV_ENVS/$cmd"
            if [[ ! -d "$env_path" ]]; then
                _vv_err "Unknown command or env not found: '$cmd'. Run \`vv\` for usage."
                return 1
            fi
            source "$env_path/bin/activate"
            _vv_ok "Activated '$cmd'"
            ;;

    esac
}
