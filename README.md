# personnal-setup
My personal OpenCode/coding agents setup.

## Usage

```bash
curl -fsSL https://raw.githubusercontent.com/andrewkoumoudjian/personnal-setup/main/install.sh | bash
```

If you already cloned the repo:

```bash
cd personnal-setup
chmod +x install.sh
./install.sh
```

## What it does

- Installs Homebrew packages and casks (macOS only)
- Copies `.opencode` into `~/.opencode`
- Installs oh-my-zsh, atuin, nvm, uv, and Rust
- Generates an SSH key if needed (set `SSH_EMAIL` or you’ll be prompted)

Re-running the script is safe; it checks for existing installs first.
