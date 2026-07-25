#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

link_config() {
  local name="$1"
  local source_dir="$script_dir/home/.config/$name"
  local target_dir="$HOME/.config/$name"
  local backup_dir="$target_dir.bk"
  local backup_created=false

  if [[ ! -e "$source_dir" ]]; then
    echo "error: $name config not found at $source_dir" >&2
    return 1
  fi

  if [[ -L "$target_dir" && "$target_dir" -ef "$source_dir" ]]; then
    echo "$name config already linked to $target_dir"
    return
  fi

  if [[ -e "$target_dir" || -L "$target_dir" ]]; then
    if [[ -e "$backup_dir" || -L "$backup_dir" ]]; then
      echo "error: backup already exists at $backup_dir" >&2
      return 1
    fi

    mv "$target_dir" "$backup_dir"
    backup_created=true
  fi

  ln -s "$source_dir" "$target_dir"
  echo "$name config linked to $target_dir"

  if [[ "$backup_created" == true ]]; then
    echo "Backup created at $backup_dir"
  fi
}

mkdir -p "$HOME/.config"

link_config nvim
link_config ghostty
link_config starship.toml
