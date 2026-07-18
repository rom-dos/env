# autonomous coding sandbox

a devcontainer for running agents in a sandbox.

based on anthropic's claude code devcontainer.

## requirements

- docker (or [orbstack](https://orbstack.dev/))
- devcontainer cli (`npm install -g @devcontainers/cli`)

## quickstart

install `./devcontainer/install.sh self-install`

run `devc <repo>` or `devc .` inside project folder.

you're now in tmux with claude and opencode ready to go, with permissions preconfigured.

## notes

- **deletes and fully replaces `.devcontainer/`** on every run
- default shell is zsh
- auth and history use shared, global docker volumes; they persist across rebuilds and are shared by every project using this template
- `wt-new` worktrees live in a project-specific `/worktrees` volume; their commits remain in `/workspace/.git`, so `wt-merge` and `wt-done` work normally
