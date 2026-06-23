# dotfiles

Personal configuration files for macOS.

## Contents

```
home/      # files that live in ~ (symlinked to $HOME)
  .wezterm.lua   # WezTerm terminal config
  .zshrc         # Zsh shell config
  .zprofile      # Zsh login shell
  .zshenv        # Zsh environment
  .profile       # POSIX shell profile
  .p10k.zsh      # Powerlevel10k prompt theme
  .gitconfig     # Git user config
  .yarnrc        # Yarn config

config/    # files that live in ~/.config (symlinked to ~/.config)
  nvim/    # Neovim config
  zed/     # Zed editor settings, themes, snippets
  jgit/    # jgit config
```

## Install

Clone the repo, then run the installer. It symlinks everything into place and
backs up any existing files to `~/.dotfiles-backup/<timestamp>/`.

```sh
git clone <your-repo-url> ~/code/dotfiles
cd ~/code/dotfiles
./install.sh          # or ./install.sh --dry to preview
```

## Notes

- Secrets and machine-specific files are intentionally **not** tracked:
  shell histories, `~/.claude.json`, `~/.config/github-copilot` (auth tokens),
  `.zcompdump`, and `.viminfo`.
- Neovim's upstream `.git` was stripped so this repo owns the config.
- After installing, restart your terminal (and WezTerm with `Cmd+Q`) to pick up
  the new configs.
