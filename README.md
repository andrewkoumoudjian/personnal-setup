# personnal-setup
My personal OpenCode/coding agents setup.

## Usage

```bash
git clone https://github.com/andrewkoumoudjian/personnal-setup.git
cd personnal-setup
chmod +x install.sh
./install.sh
```

## What it does

- Installs Homebrew packages and casks (macOS only)
- Sets up `~/.opencode` as a symlink to this repo
- Installs oh-my-zsh, atuin, nvm, uv, and Rust
- Generates an SSH key if needed (set `SSH_EMAIL` or you’ll be prompted)

Re-running the script is safe; it checks for existing installs first.
