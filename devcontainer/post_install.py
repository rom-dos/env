#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

ZSH_CONFIG = """\
# default zsh config for the devcontainer
autoload -Uz colors && colors

echo "devcontainer env"
PROMPT='%F{cyan}%~%f > '
"""

TMUX_CONFIG = """\
set -g default-terminal "tmux-256color"
set -g focus-events on
set -sg escape-time 10
set -g mouse on
set -g history-limit 200000
set -g renumber-windows on
setw -g mode-keys vi

# Keep new panes/windows in the same cwd
bind c new-window -c "#{pane_current_path}"
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %

# Reload config
bind r source-file ~/.tmux.conf \\; display-message "tmux.conf reloaded"

# Terminal features
set -as terminal-features ",xterm-ghostty:RGB"
set -as terminal-features ",xterm*:RGB"
set -ga terminal-overrides ",xterm*:colors=256"
set -ga terminal-overrides '*:Ss=\\E[%p1%d q:Se=\\E[ q'
"""


def log(message: str) -> None:
    print(f"post-install: {message}", file=sys.stderr)


def run_sudo(args: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["sudo", *args],
        check=False,
        capture_output=True,
        text=True,
    )


def ensure_claude_config() -> None:
    claude_dir = Path(os.environ.get("CLAUDE_CONFIG_DIR", str(Path.home() / ".claude")))
    claude_dir.mkdir(parents=True, exist_ok=True)
    claude_config = claude_dir / "settings.json"
    if claude_config.exists():
        log(f"skipping claude settings (already exists at {claude_config})")
        return

    data = {"permissions": {"defaultMode": "bypassPermissions"}}
    claude_config.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    log(f"wrote default claude settings to {claude_config}")


def ensure_zsh_config() -> None:
    zsh_config = Path.home() / ".zshrc"
    if zsh_config.exists():
        existing = zsh_config.read_text(encoding="utf-8")
        if not existing.strip() or existing.lstrip().startswith(
            "# default zsh config for the devcontainer"
        ):
            zsh_config.write_text(ZSH_CONFIG, encoding="utf-8")
            log(f"updated default zsh config at {zsh_config}")
            return
        log(f"skipping zsh config (already exists at {zsh_config})")
        return

    zsh_config.write_text(ZSH_CONFIG, encoding="utf-8")
    log(f"wrote default zsh config to {zsh_config}")


def ensure_dir_ownership(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)
    try:
        stat = path.stat()
    except OSError as exc:
        log(f"unable to stat {path}: {exc}")
        return

    uid = os.getuid()
    gid = os.getgid()
    if stat.st_uid == uid and stat.st_gid == gid:
        return

    result = run_sudo(["chown", "-R", f"{uid}:{gid}", str(path)])
    if result.returncode != 0:
        log(f"failed to chown {path}: {result.stderr.strip()}")
        return
    log(f"fixed ownership for {path}")


def install_tmux_config() -> None:
    tmux_dest = Path.home() / ".tmux.conf"
    if tmux_dest.exists():
        log(f"skipping tmux config (already exists at {tmux_dest})")
        return

    tmux_dest.write_text(TMUX_CONFIG, encoding="utf-8")
    log(f"installed tmux config to {tmux_dest}")


def install_tmux_plugins() -> None:
    installer = (
        Path.home() / ".tmux" / "plugins" / "tpm" / "bin" / "install_plugins"
    )
    subprocess.run([str(installer)], check=True)
    log("installed tmux plugins")


def install_nvim_plugins() -> None:
    subprocess.run(
        ["nvim", "--headless", "+Lazy! sync", "+qa"],
        check=True,
    )
    log("installed nvim plugins")


def main() -> None:
    install_tmux_config()
    install_tmux_plugins()
    install_nvim_plugins()
    ensure_dir_ownership(Path("/commandhistory"))
    ensure_dir_ownership(Path("/worktrees"))
    ensure_dir_ownership(Path.home() / ".claude")
    ensure_dir_ownership(Path.home() / ".config" / "gh")
    ensure_claude_config()
    ensure_zsh_config()
    log("configured defaults for container use")


if __name__ == "__main__":
    main()
