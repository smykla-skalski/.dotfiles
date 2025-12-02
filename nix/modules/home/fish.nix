# Fish shell configuration
#
# Migrated from chezmoi to home-manager programs.fish.
{ config, lib, pkgs, ... }:

{
  programs.fish = {
    enable = true;

    # Shell abbreviations
    shellAbbrs = {
      # General utilities
      pgc = "git_clone_to_projects";
      e2e_clean = "make kind/stop/all; docker stop (docker ps -aq)";
      cp = "rsync -aP";
      bi = "brew install";
      bic = "brew install --cask";
      msync = "set name (basename (pwd)); mutagen sync create --name=$name (pwd) bart@smyk.la:~/$name";
      "b." = "cd $HOME/Projects/github.com/bartsmykla/.dotfiles/";
      binf = "brew info";
      bs = "brew search";
      cdl = "cd $__LAST_CLONED_REPO_PATH";
      forget = "ssh-keygen -R";
      k = "kubectl";
      km = "kumactl";
      mux = "tmuxinator";
      td = "tmuxp load dev";
      b = "cd $HOME/Projects/github.com/bartsmykla/";
      purge_kuma = builtins.concatStringsSep " " [
        ("kubectl get " + builtins.concatStringsSep "," [
          "endpointslice"
          "replicaset"
          "mutatingwebhookconfiguration"
          "validatingwebhookconfiguration"
          "configmap"
          "secret"
          "crd"
          "svc"
          "clusterrole"
          "clusterrolebinding"
          "role"
          "rolebinding"
          "deploy"
          "serviceaccount"
          "ingress"
        ])
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
      awslogin = "saml2aws --session-duration 43200 -a kong-sandbox-mesh login && eval (saml2aws script -a kong-sandbox-mesh)";

      # Git basics
      ga = "git add";
      gaa = "git add -A";
      gco = "git checkout";
      gcb = "git checkout -b";
      gcs = "git commit -sS";
      gst = "git status";
      ggp = "git push origin (git branch --show-current)";
      ggpf = "git push --force-with-lease origin (git branch --show-current)";
      gbda = "git_clean_branches";

      # Git checkout helpers - NOTE: removed, using af-based functions below
      # gcm, gcmf, gcmff defined with --function below

      # Git diff helpers - NOTE: using af-based function below
      # d, dfi defined with --function below

      # Git push - NOTE: using af-based function below
      # p, pF, pf, pn, pnF, pnf defined with --function below

      # Git push - origin-first (explicit)
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

      # Git push - upstream-first
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

    # Fisher plugins managed via Nix
    plugins = [
      {
        name = "fish-history-merge";
        src = pkgs.fetchFromGitHub {
          owner = "2m";
          repo = "fish-history-merge";
          rev = "7e415b8ab843a64313708273cf659efbf471ad39";
          sha256 = "1hlc2ghnc8xidwzj2v1rjrw7gbpkkkld9y2mg4dh2qmcvlizcbd3";
        };
      }
    ];

    # Interactive shell initialization (replaces config.fish)
    interactiveShellInit = ''
      # Disable initial welcome message
      set --global fish_greeting

      # Environment variables
      set --export PROJECTS_PATH $HOME/Projects/github.com
      set --export MY_PROJECTS_PATH $PROJECTS_PATH/bartsmykla
      set --export DOTFILES_PATH $PROJECTS_PATH/smykla-labs/.dotfiles
      set --export FORTRESS_PATH /Volumes/fortress-carima
      set --export SECRETS_PATH $DOTFILES_PATH/secrets
      set --export EDITOR vim
      set --export LC_ALL en_US.UTF-8
      set --export LANG en_US.UTF-8

      # fzf configuration (fzf 0.67.0+)
      # These are set here instead of _fzf_wrapper.fish for more control
      # See: https://github.com/junegunn/fzf#environment-variables
      set --export FZF_DEFAULT_OPTS "\
        --cycle \
        --layout=reverse \
        --border=rounded \
        --height=90% \
        --preview-window=wrap \
        --marker='*' \
        --highlight-line \
        --info=inline-right \
        --tmux=bottom,50% \
        --color=bg+:-1,gutter:-1 \
        --bind='ctrl-/:toggle-preview'"

      # fzf.fish history-specific options
      # Better time format showing relative day if recent
      set --global fzf_history_time_format "%Y-%m-%d %H:%M"
      # Additional history options (appended to defaults)
      set --global fzf_history_opts "--no-sort"

      # Homebrew (skip if already initialized to speed up subshells)
      if not set -q HOMEBREW_PREFIX
        /opt/homebrew/bin/brew shellenv | source
      end

      # PATH additions
      fish_add_path --global --move $FORTRESS_PATH/.dotfiles/bin
      fish_add_path --global --move "$HOME/.cargo/bin"
      fish_add_path --global --move "$HOME/.local/bin"
      fish_add_path --global --move "$HOME/bin"
      fish_add_path --global --move "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin"
      fish_add_path --global --append "$HOME/.krew/bin"
      fish_add_path --global --append "$HOME/.opencode/bin"

      # mise tool completions (auto-generated)
      if test -f "$DOTFILES_PATH/tmp/mise-completions.fish"
        source "$DOTFILES_PATH/tmp/mise-completions.fish"
      end

      # fzf bindings
      # History: Ctrl+R (default) - supports multi-select with Tab/Shift+Tab
      fzf_configure_bindings \
        --directory=\cf \
        --git_log=\co \
        --git_status=\cs \
        --processes=\cp \
        --variables=\cv

      # ansible config
      set --global --export ANSIBLE_CONFIG "$DOTFILES_PATH/ansible/ansible.cfg"

      # gcloud cli tool
      set --global --export USE_GKE_GCLOUD_AUTH_PLUGIN "True"
      if test -f "$HOMEBREW_PREFIX/share/google-cloud-sdk/path.fish.inc"
        source "$HOMEBREW_PREFIX/share/google-cloud-sdk/path.fish.inc"
      end

      # Note: Direnv hook handled by programs.direnv in direnv.nix
      # Manual hook disabled since direnv.nix handles integration
      set --global direnv_fish_mode eval_on_arrow

      # Note: starship prompt is handled by home-manager programs.starship
      # with enableFishIntegration = true (in starship.nix)

      # jump (autojump alternative)
      if command -q jump
        jump shell fish | source
      end

      # 1password SSH agent
      set --global --export SSH_AUTH_SOCK "$HOME/.1password/agent.sock"

      # teleport (doesn't work well with 1password SSH agent)
      set --global --export TELEPORT_USE_LOCAL_SSH_AGENT false

      # Set up af-based abbreviations with --function flag
      # These abbreviations call functions that execute 'af shortcuts abbreviations <name>'
      # which returns the expanded command string
      abbr --erase gcm gcmf gcmff p pF pf pn pnF pnf d 2>/dev/null
      abbr --add --function __abbr_af_gcm gcm
      abbr --add --function __abbr_af_gcmf gcmf
      abbr --add --function __abbr_af_gcmff gcmff
      abbr --add --function __abbr_af_gp p
      abbr --add --function __abbr_af_gd d

      # Source secrets from SECRETS_PATH directory
      for secret in $SECRETS_PATH/*
        if test -f $secret
          eval "set -gx (basename $secret) (cat $secret)"
        end
      end
    '';

    # Shell aliases (not used - preferring abbreviations above)
    shellAliases = { };

    # Custom functions
    functions = {
      # AF-based abbreviation expansion functions
      # These functions are called by abbreviations with --function flag
      # They return the expanded command string from 'af' tool
      __abbr_af_gcm = {
        description = "AF abbreviation expander for gcm";
        body = "af shortcuts abbreviations gcm 2>/dev/null || echo git-checkout-default";
      };

      __abbr_af_gcmf = {
        description = "AF abbreviation expander for gcmf";
        body = "af shortcuts abbreviations gcmf 2>/dev/null || echo git-checkout-default-fetch";
      };

      __abbr_af_gcmff = {
        description = "AF abbreviation expander for gcmff";
        body = "af shortcuts abbreviations gcmff 2>/dev/null || echo git-checkout-default-fetch-fast-forward";
      };

      __abbr_af_gp = {
        description = "AF abbreviation expander for gp (git push)";
        body = "af shortcuts abbreviations gp 2>/dev/null || echo git-push-origin-first";
      };

      __abbr_af_gd = {
        description = "AF abbreviation expander for gd (git diff)";
        body = "af shortcuts abbreviations gd 2>/dev/null || echo git-diff-head-pbcopy";
      };

      # Git utilities
      git-get-default-branch = {
        description = "Return the default branch name for the given remote";
        body = ''
          set --function remote $argv[1]
          if test -z "$remote"
            return 1
          end
          string replace "$remote/" "" (git rev-parse --abbrev-ref "$remote/HEAD")
        '';
      };

      git-get-first-remote = {
        description = "Return the first remote (upstream or origin)";
        body = ''
          set --function remotes (git remote)
          if contains upstream $remotes
            echo upstream
          else if contains origin $remotes
            echo origin
          else
            echo $remotes[1]
          end
        '';
      };

      git-checkout-default = {
        description = "Checkout the default branch of the first remote";
        body = ''
          set --function remote (git-get-first-remote)
          set --function default_branch (git-get-default-branch $remote)
          git checkout $default_branch
        '';
      };

      git-checkout-default-fetch = {
        description = "Checkout and fetch the default branch";
        body = ''
          git-checkout-default
          and git fetch --all --prune
        '';
      };

      git-checkout-default-fetch-fast-forward = {
        description = "Checkout, fetch, and fast-forward the default branch";
        body = ''
          git-checkout-default-fetch
          and git pull --ff-only
        '';
      };

      git-diff-head = {
        description = "Show diff against HEAD";
        body = "git diff HEAD";
      };

      git-diff-head-pbcopy = {
        description = "Copy diff against HEAD to clipboard";
        body = "git diff HEAD | pbcopy";
      };

      git-diff-head-files-pbcopy = {
        description = "Copy list of changed files to clipboard";
        body = "git diff HEAD --name-only | pbcopy";
      };

      # Git push helpers (origin)
      git-push-origin = {
        body = "git push origin (git rev-parse --abbrev-ref HEAD)";
      };

      git-push-origin-force = {
        body = "git push origin (git rev-parse --abbrev-ref HEAD) --force";
      };

      git-push-origin-force-with-lease = {
        body = "git push origin (git rev-parse --abbrev-ref HEAD) --force-with-lease";
      };

      git-push-origin-no-verify = {
        body = "git push origin (git rev-parse --abbrev-ref HEAD) --no-verify";
      };

      git-push-origin-no-verify-force = {
        body = "git push origin (git rev-parse --abbrev-ref HEAD) --no-verify --force";
      };

      git-push-origin-no-verify-force-with-lease = {
        body = "git push origin (git rev-parse --abbrev-ref HEAD) --no-verify --force-with-lease";
      };

      git-push-origin-first = {
        body = "git push --set-upstream origin (git rev-parse --abbrev-ref HEAD)";
      };

      git-push-origin-first-force = {
        body = "git push --set-upstream origin (git rev-parse --abbrev-ref HEAD) --force";
      };

      git-push-origin-first-force-with-lease = {
        body = "git push --set-upstream origin (git rev-parse --abbrev-ref HEAD) --force-with-lease";
      };

      git-push-origin-first-no-verify = {
        body = "git push --set-upstream origin (git rev-parse --abbrev-ref HEAD) --no-verify";
      };

      git-push-origin-first-no-verify-force = {
        body = "git push --set-upstream origin (git rev-parse --abbrev-ref HEAD) --no-verify --force";
      };

      git-push-origin-first-no-verify-force-with-lease = {
        body = "git push --set-upstream origin (git rev-parse --abbrev-ref HEAD) --no-verify --force-with-lease";
      };

      # Git push helpers (upstream)
      git-push-upstream = {
        body = "git push upstream (git rev-parse --abbrev-ref HEAD)";
      };

      git-push-upstream-force = {
        body = "git push upstream (git rev-parse --abbrev-ref HEAD) --force";
      };

      git-push-upstream-force-with-lease = {
        body = "git push upstream (git rev-parse --abbrev-ref HEAD) --force-with-lease";
      };

      git-push-upstream-no-verify = {
        body = "git push upstream (git rev-parse --abbrev-ref HEAD) --no-verify";
      };

      git-push-upstream-no-verify-force = {
        body = "git push upstream (git rev-parse --abbrev-ref HEAD) --no-verify --force";
      };

      git-push-upstream-no-verify-force-with-lease = {
        body = "git push upstream (git rev-parse --abbrev-ref HEAD) --no-verify --force-with-lease";
      };

      git-push-upstream-first = {
        body = "git push --set-upstream upstream (git rev-parse --abbrev-ref HEAD)";
      };

      git-push-upstream-first-force = {
        body = "git push --set-upstream upstream (git rev-parse --abbrev-ref HEAD) --force";
      };

      git-push-upstream-first-force-with-lease = {
        body = "git push --set-upstream upstream (git rev-parse --abbrev-ref HEAD) --force-with-lease";
      };

      git-push-upstream-first-no-verify = {
        body = "git push --set-upstream upstream (git rev-parse --abbrev-ref HEAD) --no-verify";
      };

      git-push-upstream-first-no-verify-force = {
        body = "git push --set-upstream upstream (git rev-parse --abbrev-ref HEAD) --no-verify --force";
      };

      git-push-upstream-first-no-verify-force-with-lease = {
        body = "git push --set-upstream upstream (git rev-parse --abbrev-ref HEAD) --no-verify --force-with-lease";
      };

      # Git clone utility
      git_clone_to_projects = {
        description = "Clone repository to $PROJECTS_PATH and create parent directory if needed";
        argumentNames = [ "repo_url" ];
        body = ''
          if ! set -q PROJECTS_PATH
            echo "Variable \$PROJECTS_PATH is not defined" >&2
            return 1
          end

          set regex 's/^git@github\\.com:(.+)?\\/(.+)?.git$/\1 \2/'
          set names (echo $repo_url | sed -E $regex | string split " ")

          if test (count $names) -ne 2
            echo "Invalid or unsupported repository path ($repo_url)" >&2
            return 121
          end

          set org_name $names[1]
          set repo_name $names[2]
          set org_path $PROJECTS_PATH/$org_name
          set full_path $org_path/$repo_name

          if test -e $full_path
            echo "Directory \"$full_path\" already exists" >&2
            return 121
          end

          mkdir -p $full_path && \
          git clone $repo_url $full_path && \
          set -xg __LAST_CLONED_REPO_PATH $full_path
        '';
      };

      git_clean_branches = {
        description = "Clean up merged branches";
        body = ''
          git branch --merged | grep -v '\*\|main\|master' | xargs -n 1 git branch -d
        '';
      };

      # Key bindings
      fish_user_key_bindings = {
        body = ''
          bind \cx\ce edit_command_buffer
          bind --key nul accept-autosuggestion
          bind --erase --preset \cd
        '';
      };

      # Utility functions
      mkd = {
        description = "Create directory and cd into it";
        body = "mkdir -p $argv && cd $argv";
      };

      up-or-search = {
        description = "Move up in history or search";
        body = ''
          if commandline --search-mode
            commandline -f history-search-backward
            return
          end

          if commandline --paging-mode
            commandline -f up-line
            return
          end

          set -l lineno (commandline -L)
          if test $lineno -gt 1
            commandline -f up-line
          else
            commandline -f history-search-backward
          end
        '';
      };

      klg = {
        description = "Kubernetes logs with fuzzy search";
        body = ''
          set -l pod (kubectl get pods --no-headers | fzf | awk '{print $1}')
          if test -n "$pod"
            kubectl logs -f $pod $argv
          end
        '';
      };

      kls = {
        description = "Kubernetes list resources with fuzzy search";
        body = ''
          set -l resource (kubectl api-resources --verbs=list --namespaced -o name | fzf)
          if test -n "$resource"
            kubectl get $resource $argv
          end
        '';
      };

      link-dotfile = {
        description = "Create symlink for dotfile";
        body = ''
          if test (count $argv) -ne 2
            echo "Usage: link-dotfile <source> <target>" >&2
            return 1
          end
          ln -sf $argv[1] $argv[2]
        '';
      };
    };
  };

  # Install related packages
  # Note: direnv is handled by its own module (direnv.nix)
  home.packages = with pkgs; [
    # fzf integration (used by fzf.fish plugin)
    fzf
  ];

  # Install fzf.fish plugin files via xdg
  xdg.configFile = {
    # fzf.fish functions
    "fish/functions/_fzf_configure_bindings_help.fish".source = ../../dotfiles/fish/functions/_fzf_configure_bindings_help.fish;
    "fish/functions/_fzf_extract_var_info.fish".source = ../../dotfiles/fish/functions/_fzf_extract_var_info.fish;
    "fish/functions/_fzf_preview_changed_file.fish".source = ../../dotfiles/fish/functions/_fzf_preview_changed_file.fish;
    "fish/functions/_fzf_preview_file.fish".source = ../../dotfiles/fish/functions/_fzf_preview_file.fish;
    "fish/functions/_fzf_report_diff_type.fish".source = ../../dotfiles/fish/functions/_fzf_report_diff_type.fish;
    "fish/functions/_fzf_report_file_type.fish".source = ../../dotfiles/fish/functions/_fzf_report_file_type.fish;
    "fish/functions/_fzf_search_directory.fish".source = ../../dotfiles/fish/functions/_fzf_search_directory.fish;
    "fish/functions/_fzf_search_git_log.fish".source = ../../dotfiles/fish/functions/_fzf_search_git_log.fish;
    "fish/functions/_fzf_search_git_status.fish".source = ../../dotfiles/fish/functions/_fzf_search_git_status.fish;
    "fish/functions/_fzf_search_history.fish".source = ../../dotfiles/fish/functions/_fzf_search_history.fish;
    "fish/functions/_fzf_search_processes.fish".source = ../../dotfiles/fish/functions/_fzf_search_processes.fish;
    "fish/functions/_fzf_search_variables.fish".source = ../../dotfiles/fish/functions/_fzf_search_variables.fish;
    "fish/functions/_fzf_wrapper.fish".source = ../../dotfiles/fish/functions/_fzf_wrapper.fish;
    "fish/functions/fzf_configure_bindings.fish".source = ../../dotfiles/fish/functions/fzf_configure_bindings.fish;
    "fish/functions/fzf_key_bindings.fish".source = ../../dotfiles/fish/functions/fzf_key_bindings.fish;

    # fzf.fish completions
    "fish/completions/fzf_configure_bindings.fish".source = ../../dotfiles/fish/completions/fzf_configure_bindings.fish;

    # fzf.fish conf.d
    "fish/conf.d/fzf.fish".source = ../../dotfiles/fish/conf.d/fzf.fish;

    # abbr_tips conf.d and functions
    "fish/conf.d/abbr_tips.fish".source = ../../dotfiles/fish/conf.d/abbr_tips.fish;
    "fish/functions/__abbr_tips_bind_newline.fish".source = ../../dotfiles/fish/functions/__abbr_tips_bind_newline.fish;
    "fish/functions/__abbr_tips_bind_space.fish".source = ../../dotfiles/fish/functions/__abbr_tips_bind_space.fish;
    "fish/functions/__abbr_tips_clean.fish".source = ../../dotfiles/fish/functions/__abbr_tips_clean.fish;
    "fish/functions/__abbr_tips_init.fish".source = ../../dotfiles/fish/functions/__abbr_tips_init.fish;

    # docker conf.d
    "fish/conf.d/docker.fish".source = ../../dotfiles/fish/conf.d/docker.fish;

    # fisher function
    "fish/functions/fisher.fish".source = ../../dotfiles/fish/functions/fisher.fish;

    # completions from tools
    "fish/completions/docker.fish".source = ../../dotfiles/fish/completions/docker.fish;
    "fish/completions/fisher.fish".source = ../../dotfiles/fish/completions/fisher.fish;
    "fish/completions/golangci-lint.fish".source = ../../dotfiles/fish/completions/golangci-lint.fish;
    "fish/completions/goreleaser.fish".source = ../../dotfiles/fish/completions/goreleaser.fish;
    "fish/completions/hcloud.fish".source = ../../dotfiles/fish/completions/hcloud.fish;
    "fish/completions/k3d.fish".source = ../../dotfiles/fish/completions/k3d.fish;
    "fish/completions/kubectl.fish".source = ../../dotfiles/fish/completions/kubectl.fish;
    "fish/completions/mise.fish".source = ../../dotfiles/fish/completions/mise.fish;

    # Note: broot integration (br.fish) is handled by programs.broot in broot.nix
    # with enableFishIntegration = true
  };
}
