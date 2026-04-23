# Shell aliases generator
#
# Converts Fish abbreviations to bash/zsh aliases and generates a shared aliases file.
# This file is sourced by all shell configurations (bash, zsh, etc.) to ensure
# abbreviations work across all shells, including when Claude Code spawns bash.
{ config, lib, pkgs, ... }:

let
  # Fish abbreviations from fish/abbreviations.nix
  fishAbbrs = {
    # General utilities
    pgc = "git_clone_to_projects";
    e2e_clean = "make kind/stop/all; docker stop $(docker ps -aq)";
    rcp = "rsync -aP";
    bi = "brew install";
    bic = "brew install --cask";
    msync = "name=$(basename $(pwd)); mutagen sync create --name=$name $(pwd) bart@smyk.la:~/$name";
    "b." = "cd $HOME/Projects/github.com/smykla-skalski/.dotfiles/";
    binf = "brew info";
    bs = "brew search";
    cdl = "cd $__LAST_CLONED_REPO_PATH";
    forget = "ssh-keygen -R";
    k = "kubectl";
    km = "kumactl";
    mux = "tmuxinator";
    td = "tmuxp load dev";
    b = "cd $HOME/Projects/github.com/smykla-skalski/";

    # Claude Code
    c = "claude";
    ch = "claude --model Haiku";
    chh = "claude --model Haiku --effort high";
    csl = "claude --model Sonnet --effort low";
    csm = "claude --model Sonnet --effort medium";
    csh = "claude --model Sonnet --effort high";
    col = "claude --model Opus[1m] --effort low";
    com = "claude --model Opus[1m] --effort medium";
    coh = "claude --model Opus[1m] --effort high";

    # Claude Code - resume (interactive session picker)
    cr = "claude --resume";
    chr = "claude --model Haiku --resume";
    cslr = "claude --model Sonnet --effort low --resume";
    csmr = "claude --model Sonnet --effort medium --resume";
    cshr = "claude --model Sonnet --effort high --resume";
    colr = "claude --model Opus[1m] --effort low --resume";
    comr = "claude --model Opus[1m] --effort medium --resume";
    cohr = "claude --model Opus[1m] --effort high --resume";

    # Claude Code - resume last session for current project
    cl = "claude --resume $(jq -r --arg pwd \"$PWD\" 'select(.project == $pwd) | .sessionId' ~/.claude/history.jsonl | tail -1)";
    chl = "claude --model Haiku --resume $(jq -r --arg pwd \"$PWD\" 'select(.project == $pwd) | .sessionId' ~/.claude/history.jsonl | tail -1)";
    csll = "claude --model Sonnet --effort low --resume $(jq -r --arg pwd \"$PWD\" 'select(.project == $pwd) | .sessionId' ~/.claude/history.jsonl | tail -1)";
    csml = "claude --model Sonnet --effort medium --resume $(jq -r --arg pwd \"$PWD\" 'select(.project == $pwd) | .sessionId' ~/.claude/history.jsonl | tail -1)";
    cshl = "claude --model Sonnet --effort high --resume $(jq -r --arg pwd \"$PWD\" 'select(.project == $pwd) | .sessionId' ~/.claude/history.jsonl | tail -1)";
    coll = "claude --model Opus[1m] --effort low --resume $(jq -r --arg pwd \"$PWD\" 'select(.project == $pwd) | .sessionId' ~/.claude/history.jsonl | tail -1)";
    coml = "claude --model Opus[1m] --effort medium --resume $(jq -r --arg pwd \"$PWD\" 'select(.project == $pwd) | .sessionId' ~/.claude/history.jsonl | tail -1)";
    cohl = "claude --model Opus[1m] --effort high --resume $(jq -r --arg pwd \"$PWD\" 'select(.project == $pwd) | .sessionId' ~/.claude/history.jsonl | tail -1)";

    # Home Manager
    hmn = "home-manager news --flake $DOTFILES_PATH/nix#home-bart";
    hms = "home-manager switch --flake $DOTFILES_PATH/nix#home-bart";
    hmg = "home-manager generations --flake $DOTFILES_PATH/nix#home-bart";
    hmp = "home-manager packages --flake $DOTFILES_PATH/nix#home-bart";

    purge_kuma = lib.concatStringsSep " " [
      "kubectl get endpointslice,replicaset,mutatingwebhookconfiguration,validatingwebhookconfiguration,configmap,secret,crd,svc,clusterrole,clusterrolebinding,role,rolebinding,deploy,serviceaccount,ingress"
      "-A -o json |"
      "jq -r '.items[]"
      "| select(.metadata.name | contains(\"kong-mesh\") or contains(\"kuma\"))"
      "| select(.kind != \"Namespace\" and .kind != \"Pod\")"
      "| select(.kind != \"Secret\" or .metadata.name != \"kong-mesh-license\")"
      "| .metadata.namespace as $ns"
      "| \"\\(.kind | ascii_downcase)/\\(.metadata.name)\" as $res"
      "| if $ns then \"-n \\($ns) \\($res)\" else \"\\($res)\" end'"
      "| xargs -d \"\\n\" -I \"{}\" /bin/bash -c 'kubectl delete {} &'; wait"
    ];

    sshno = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null";
    set-ns = "kubectl config set-context --current --namespace";
    l = "eza --all --long --icons always";
    lt = "eza --all --long --icons always --tree";
    awslogin = "saml2aws --session-duration 43200 -a kong-sandbox-mesh login && eval $(saml2aws script -a kong-sandbox-mesh)";

    # Git basics
    ga = "git add";
    gaa = "git add -A";
    gco = "git checkout";
    gcb = "git checkout -b";
    gcs = "git commit -sS";
    gst = "git status";
    ggp = "git push origin $(git branch --show-current)";
    ggpf = "git push --force-with-lease origin $(git branch --show-current)";
    gbda = "git_clean_branches";

    # Git checkout helpers (using fallback functions from git.nix)
    gcm = "git-checkout-default";
    gcmf = "git-checkout-default-fetch";
    gcmff = "git-checkout-default-fetch-fast-forward";

    # Git diff helpers
    d = "git-diff-head-pbcopy";
    dfi = "git-diff-head-files-pbcopy";

    # Git push - origin-first (set-upstream)
    p = "git-push-origin-first";
    po = "git-push-origin-first";
    poF = "git-push-origin-first-force";
    pof = "git-push-origin-first-force-with-lease";
    pon = "git-push-origin-first-no-verify";
    ponF = "git-push-origin-first-no-verify-force";
    ponf = "git-push-origin-first-no-verify-force-with-lease";

    # Git push - origin (no set-upstream)
    pO = "git-push-origin";
    pOF = "git-push-origin-force";
    pOf = "git-push-origin-force-with-lease";
    pOn = "git-push-origin-no-verify";
    pOnF = "git-push-origin-no-verify-force";
    pOnf = "git-push-origin-no-verify-force-with-lease";

    # Git push - upstream-first (set-upstream)
    pu = "git-push-upstream-first";
    puF = "git-push-upstream-first-force";
    puf = "git-push-upstream-first-force-with-lease";
    pun = "git-push-upstream-first-no-verify";
    punF = "git-push-upstream-first-no-verify-force";
    punf = "git-push-upstream-first-no-verify-force-with-lease";

    # Git push - upstream (no set-upstream)
    pU = "git-push-upstream";
    pUF = "git-push-upstream-force";
    pUf = "git-push-upstream-force-with-lease";
    pUn = "git-push-upstream-no-verify";
    pUnF = "git-push-upstream-no-verify-force";
    pUnf = "git-push-upstream-no-verify-force-with-lease";
  };

  # Generate alias lines for bash/zsh
  # Format: alias name='command'
  generateAliasLine = name: command:
    "alias ${lib.escapeShellArg name}=${lib.escapeShellArg command}";

  aliasLines = lib.mapAttrsToList generateAliasLine fishAbbrs;
  aliasContent = lib.concatStringsSep "\n" aliasLines;

  aliasFile = pkgs.writeText "shell-aliases.sh" ''
    # Generated shell aliases from Fish abbreviations
    # DO NOT EDIT - Generated by nix/modules/home/shell-aliases.nix
    # Generated at build time from Fish abbreviations

    ${aliasContent}
  '';

in
{
  # Create the aliases file in the config directory
  home.file.".config/shell/aliases.sh".source = aliasFile;
}
