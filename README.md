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
  AGENTS.md      # Global instructions for AI coding agents
  OPINIONS.md    # Technical viewpoints agents should follow
  VOICE.md       # Writing voice for posts/messages on your behalf
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

- Secrets and machine-specific files are intentionally **not** tracked: shell histories, `~/.claude.json`, `~/.config/github-copilot` (auth tokens),
  `.zcompdump`, and `.viminfo`.
- After installing, restart your terminal (and WezTerm with `Cmd+Q`) to pick up
  the new configs.

## Agent instructions

`AGENTS.md`, `OPINIONS.md`, and `VOICE.md` are symlinked into `~` and read by AI
coding agents (Claude Code, Codex, Copilot, Gemini CLI, Cursor, and others that
support the [AGENTS.md](https://agents.md) format).

- `~/AGENTS.md` - general guidelines applied to every task. It points agents to
  the two files below when relevant.
- `~/OPINIONS.md` - your technical and product viewpoints, consulted for
  judgment calls and tradeoffs.
- `~/VOICE.md` - how you write, used when an agent drafts or posts as you.

Treat all three as living documents. The more concrete examples you add
(especially real samples of your own writing in `VOICE.md`), the better agents
match you.
