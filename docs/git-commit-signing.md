# Git commit signing on macOS

Home Manager configures Git to sign through the native macOS SSH agent and installs a login agent that loads the passphrase-protected signing key from `~/.ssh`, using the passphrase stored in Keychain. The private key, passphrase, public key, and local allowed-signers file stay outside this repository.

Run once on a new Mac from the repository root. Enter a non-empty passphrase for the key and do not overwrite an existing key.

```sh
home-manager switch --flake ./nix#home-bart
install -d -m 700 "$HOME/.ssh"
key="$HOME/.ssh/git_commit_signing_ed25519"
/usr/bin/ssh-keygen -t ed25519 -f "$key" -C "Git commit signing"
SSH_AUTH_SOCK="$(launchctl getenv SSH_AUTH_SOCK)" /usr/bin/ssh-add --apple-use-keychain "$key"
gh ssh-key add "$key.pub" --type signing --title "Git commit signing (macOS)"
signer="$(git config user.email) $(cut -d ' ' -f1,2 "$key.pub")"
grep -Fxq "$signer" "$HOME/.ssh/allowed_signers" 2>/dev/null || printf '%s\n' "$signer" >> "$HOME/.ssh/allowed_signers"
```

The private key stays in `~/.ssh` and only its passphrase is stored in macOS Keychain. At each GUI login, the Home Manager launch agent reads that passphrase from Keychain and loads only this key into the native agent without prompting. Git's signing wrapper selects that agent even if another SSH agent handles repository authentication.

To check the loaded key, run `SSH_AUTH_SOCK="$(launchctl getenv SSH_AUTH_SOCK)" /usr/bin/ssh-add -T "$HOME/.ssh/git_commit_signing_ed25519.pub"`. A signed commit can then be checked with `git verify-commit HEAD`.

After migrating an existing Mac, remove its previous standalone login agent and Git signing overrides from `~/.gitconfig` once Home Manager has activated. Home Manager then owns both settings.
