# dev-setup

One-shot bootstrap for a fresh Apple Silicon Mac. It installs the tools and apps below and links their configs from [shaunwen/dotfiles](https://github.com/shaunwen/dotfiles) and [shaunwen/nvim](https://github.com/shaunwen/nvim).

## Requirements

- Apple Silicon Mac, logged in as a user with **administrator** rights
- Internet connection
- About **5 GB** of free disk space (Xcode Command Line Tools, Homebrew, packages, apps, Neovim plugins, node/bun and the dsh profile)

## Usage

Clone this repo to `~/workspace/dev-setup` on the new Mac:

```bash
mkdir -p ~/workspace
git clone https://github.com/shaunwen/dev-setup.git ~/workspace/dev-setup
```

Put your Raycast export (`*.rayconfig`) in `~/workspace/dev-setup/configs/raycast/`, then run:

```bash
~/workspace/dev-setup/install.sh
```

- If macOS asks to install the Xcode Command Line Tools, finish that and run the script again.
- Enter your macOS password when asked. Do not run the script with `sudo`, because Homebrew refuses to install as root.
- The script is safe to re-run: it skips what is already installed and continues where it stopped. Only the Raycast import prompt opens again on each run; close it if you have already imported.

## What gets installed

| Area | Installed | Config |
| --- | --- | --- |
| Editor | neovim, Neovide | `shaunwen/nvim` cloned to `~/.config/nvim`, plugins pinned by `lazy-lock.json`; Neovide via dotfiles |
| Terminal | Rio, tmux (+ tpm plugins), herdr (+ herdr-plus, command-palette plugins) | dotfiles |
| Shell | zsh config, starship, atuin, zoxide, fzf, direnv, forgit, zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions, glow, coreutils, jq, qrencode | dotfiles |
| Runtimes | mise, node 24 and bun (via mise), pnpm, uv | - |
| DeepSeek | dsh (`@deepseek-ai/dsh`) and the `cctui` profile with dsh-tui | profile copied from `dotfiles/dsh/profiles/cctui` to `~/.dsh/profiles/cctui` |
| Apps | Raycast, Karabiner-Elements, Brave Browser | Raycast from `configs/raycast/*.rayconfig`; Karabiner via dotfiles |
| Other | Bitwarden CLI, JetBrains Mono Nerd Font, ripgrep, fd, git, stow | - |

Existing non-symlinked config files (`.zshrc`, `.zshenv`, `.tmux.conf`, starship, atuin, karabiner) are renamed to `*.bak.<timestamp>` before linking.

## After the script finishes

1. Open a new terminal so zsh picks up the new config.
2. Open Karabiner-Elements once and grant Input Monitoring and the driver extension.
3. Enter the Raycast export password when the import opens, and grant Raycast Accessibility access for window management.
4. Run `bw login` to sign in to the Bitwarden CLI. Add the Bitwarden extension to Brave from the Chrome Web Store.
5. Put `export DEEPSEEK_API_KEY=...` in `~/.zshrc.local` (never in dotfiles, the repo is public), then run `dsh --profile cctui`.

## Folder contents

```
dev-setup/
├── install.sh
├── README.md
└── configs/
    └── raycast/*.rayconfig   # not in git - add your own Raycast export
```

The Raycast export holds your Raycast settings and data, so it is kept out of this public repo by `.gitignore`. Without it, the script still installs Raycast and skips the import.
