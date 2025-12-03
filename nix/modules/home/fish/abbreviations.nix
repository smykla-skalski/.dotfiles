# Fish shell abbreviations
{ ... }:

{
  programs.fish.shellAbbrs = {
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

    # Home Manager
    hmn = "home-manager news --flake $DOTFILES_PATH/nix#home-bart";
    hms = "home-manager switch --flake $DOTFILES_PATH/nix#home-bart";
    hmg = "home-manager generations --flake $DOTFILES_PATH/nix#home-bart";
    hmp = "home-manager packages --flake $DOTFILES_PATH/nix#home-bart";
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

    # Git checkout helpers - using af-based functions below
    # gcm, gcmf, gcmff defined with --function in keybindings.nix

    # Git diff helpers - using af-based function below
    # d, dfi defined with --function in keybindings.nix

    # Git push - using af-based function below
    # p, pF, pf, pn, pnF, pnf defined with --function in keybindings.nix
    # po, poF, pof, pon, ponF, ponf defined with --function in keybindings.nix
    # pO, pOF, pOf, pOn, pOnF, pOnf defined with --function in keybindings.nix
    # pu, puF, puf, pun, punF, punf defined with --function in keybindings.nix
    # pU, pUF, pUf, pUn, pUnF, pUnf defined with --function in keybindings.nix
  };
}
