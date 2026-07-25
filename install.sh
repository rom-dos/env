#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source_dir="$script_dir/home/.config/nvim"
target_dir="$HOME/.config/nvim"
backup_dir="$HOME/.config/nvim.bk"
backup_created=false

if [[ ! -d "$source_dir" ]]; then
  echo "error: nvim config not found at $source_dir" >&2
  exit 1
fi

mkdir -p "$HOME/.config"

if [[ -L "$target_dir" && "$target_dir" -ef "$source_dir" ]]; then
  echo "nvim config already linked to $target_dir"
  exit 0
fi

if [[ -e "$target_dir" || -L "$target_dir" ]]; then
  if [[ -e "$backup_dir" || -L "$backup_dir" ]]; then
    echo "error: backup already exists at $backup_dir" >&2
    exit 1
  fi

  mv "$target_dir" "$backup_dir"
  backup_created=true
fi

ln -s "$source_dir" "$target_dir"
echo "nvim config linked to $target_dir"

if [[ "$backup_created" == true ]]; then
  echo "Backup created at $backup_dir"
fi
