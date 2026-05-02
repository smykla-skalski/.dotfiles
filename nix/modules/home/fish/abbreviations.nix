# Fish shell abbreviations
{ ... }:

{
  programs.fish.shellAbbrs = {
    # General utilities
    pgc = "git_clone_to_projects";
    e2e_clean = "make kind/stop/all; docker stop (docker ps -aq)";
    rcp = "rsync -aP";
    bi = "brew install";
    bic = "brew install --cask";
    msync = "set name (basename (pwd)); mutagen sync create --name=$name (pwd) bart@smyk.la:~/$name";
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
    csl = "claude --model Sonnet --effort low";
    csm = "claude --model Sonnet --effort medium";
    csh = "claude --model Sonnet --effort high";
    csx = "claude --model Sonnet --effort xhigh";
    csxm = "claude --model Sonnet --effort max";
    col = "claude --model Opus --effort low";
    com = "claude --model Opus --effort medium";
    coh = "claude --model Opus --effort high";
    cox = "claude --model Opus --effort xhigh";
    coxm = "claude --model Opus --effort max";

    # Claude Code - resume (interactive session picker)
    cr = "claude --resume";
    cslr = "claude --model Sonnet --effort low --resume";
    csmr = "claude --model Sonnet --effort medium --resume";
    cshr = "claude --model Sonnet --effort high --resume";
    csxr = "claude --model Sonnet --effort xhigh --resume";
    csxmr = "claude --model Sonnet --effort max --resume";
    colr = "claude --model Opus --effort low --resume";
    comr = "claude --model Opus --effort medium --resume";
    cohr = "claude --model Opus --effort high --resume";
    coxr = "claude --model Opus --effort xhigh --resume";
    coxmr = "claude --model Opus --effort max --resume";

    # Claude Code - dangerously-skip-permissions
    dc = "claude --dangerously-skip-permissions";
    dcsl = "claude --model Sonnet --effort low --dangerously-skip-permissions";
    dcsm = "claude --model Sonnet --effort medium --dangerously-skip-permissions";
    dcsh = "claude --model Sonnet --effort high --dangerously-skip-permissions";
    dcsx = "claude --model Sonnet --effort xhigh --dangerously-skip-permissions";
    dcsxm = "claude --model Sonnet --effort max --dangerously-skip-permissions";
    dcol = "claude --model Opus --effort low --dangerously-skip-permissions";
    dcom = "claude --model Opus --effort medium --dangerously-skip-permissions";
    dcoh = "claude --model Opus --effort high --dangerously-skip-permissions";
    dcox = "claude --model Opus --effort xhigh --dangerously-skip-permissions";
    dcoxm = "claude --model Opus --effort max --dangerously-skip-permissions";

    # Codex
    x = "codex";
    xsl = "codex --model gpt-5.3-codex-spark -c model_reasoning_effort=low";
    xsm = "codex --model gpt-5.3-codex-spark -c model_reasoning_effort=medium";
    xsh = "codex --model gpt-5.3-codex-spark -c model_reasoning_effort=high";
    xsx = "codex --model gpt-5.3-codex-spark -c model_reasoning_effort=xhigh";
    xcl = "codex --model gpt-5.3-codex -c model_reasoning_effort=low";
    xcm = "codex --model gpt-5.3-codex -c model_reasoning_effort=medium";
    xch = "codex --model gpt-5.3-codex -c model_reasoning_effort=high";
    xcx = "codex --model gpt-5.3-codex -c model_reasoning_effort=xhigh";
    x4l = "codex --model gpt-5.4 -c model_reasoning_effort=low";
    x4m = "codex --model gpt-5.4 -c model_reasoning_effort=medium";
    x4h = "codex --model gpt-5.4 -c model_reasoning_effort=high";
    x4x = "codex --model gpt-5.4 -c model_reasoning_effort=xhigh";
    x5l = "codex --model gpt-5.5 -c model_reasoning_effort=low";
    x5m = "codex --model gpt-5.5 -c model_reasoning_effort=medium";
    x5h = "codex --model gpt-5.5 -c model_reasoning_effort=high";
    x5x = "codex --model gpt-5.5 -c model_reasoning_effort=xhigh";

    # Codex - resume (interactive session picker)
    xr = "codex resume";
    xslr = "codex resume --model gpt-5.3-codex-spark -c model_reasoning_effort=low";
    xsmr = "codex resume --model gpt-5.3-codex-spark -c model_reasoning_effort=medium";
    xshr = "codex resume --model gpt-5.3-codex-spark -c model_reasoning_effort=high";
    xsxr = "codex resume --model gpt-5.3-codex-spark -c model_reasoning_effort=xhigh";
    xclr = "codex resume --model gpt-5.3-codex -c model_reasoning_effort=low";
    xcmr = "codex resume --model gpt-5.3-codex -c model_reasoning_effort=medium";
    xchr = "codex resume --model gpt-5.3-codex -c model_reasoning_effort=high";
    xcxr = "codex resume --model gpt-5.3-codex -c model_reasoning_effort=xhigh";
    x4lr = "codex resume --model gpt-5.4 -c model_reasoning_effort=low";
    x4mr = "codex resume --model gpt-5.4 -c model_reasoning_effort=medium";
    x4hr = "codex resume --model gpt-5.4 -c model_reasoning_effort=high";
    x4xr = "codex resume --model gpt-5.4 -c model_reasoning_effort=xhigh";
    x5lr = "codex resume --model gpt-5.5 -c model_reasoning_effort=low";
    x5mr = "codex resume --model gpt-5.5 -c model_reasoning_effort=medium";
    x5hr = "codex resume --model gpt-5.5 -c model_reasoning_effort=high";
    x5xr = "codex resume --model gpt-5.5 -c model_reasoning_effort=xhigh";

    # Codex - dangerously-bypass-approvals-and-sandbox
    dx = "codex --dangerously-bypass-approvals-and-sandbox";
    dxsl = "codex --model gpt-5.3-codex-spark -c model_reasoning_effort=low --dangerously-bypass-approvals-and-sandbox";
    dxsm = "codex --model gpt-5.3-codex-spark -c model_reasoning_effort=medium --dangerously-bypass-approvals-and-sandbox";
    dxsh = "codex --model gpt-5.3-codex-spark -c model_reasoning_effort=high --dangerously-bypass-approvals-and-sandbox";
    dxsx = "codex --model gpt-5.3-codex-spark -c model_reasoning_effort=xhigh --dangerously-bypass-approvals-and-sandbox";
    dxcl = "codex --model gpt-5.3-codex -c model_reasoning_effort=low --dangerously-bypass-approvals-and-sandbox";
    dxcm = "codex --model gpt-5.3-codex -c model_reasoning_effort=medium --dangerously-bypass-approvals-and-sandbox";
    dxch = "codex --model gpt-5.3-codex -c model_reasoning_effort=high --dangerously-bypass-approvals-and-sandbox";
    dxcx = "codex --model gpt-5.3-codex -c model_reasoning_effort=xhigh --dangerously-bypass-approvals-and-sandbox";
    dx4l = "codex --model gpt-5.4 -c model_reasoning_effort=low --dangerously-bypass-approvals-and-sandbox";
    dx4m = "codex --model gpt-5.4 -c model_reasoning_effort=medium --dangerously-bypass-approvals-and-sandbox";
    dx4h = "codex --model gpt-5.4 -c model_reasoning_effort=high --dangerously-bypass-approvals-and-sandbox";
    dx4x = "codex --model gpt-5.4 -c model_reasoning_effort=xhigh --dangerously-bypass-approvals-and-sandbox";
    dx5l = "codex --model gpt-5.5 -c model_reasoning_effort=low --dangerously-bypass-approvals-and-sandbox";
    dx5m = "codex --model gpt-5.5 -c model_reasoning_effort=medium --dangerously-bypass-approvals-and-sandbox";
    dx5h = "codex --model gpt-5.5 -c model_reasoning_effort=high --dangerously-bypass-approvals-and-sandbox";
    dx5x = "codex --model gpt-5.5 -c model_reasoning_effort=xhigh --dangerously-bypass-approvals-and-sandbox";

    # Codex - dangerously-bypass-approvals-and-sandbox + resume (interactive session picker)
    dxr = "codex resume --dangerously-bypass-approvals-and-sandbox";
    dxslr = "codex resume --model gpt-5.3-codex-spark -c model_reasoning_effort=low --dangerously-bypass-approvals-and-sandbox";
    dxsmr = "codex resume --model gpt-5.3-codex-spark -c model_reasoning_effort=medium --dangerously-bypass-approvals-and-sandbox";
    dxshr = "codex resume --model gpt-5.3-codex-spark -c model_reasoning_effort=high --dangerously-bypass-approvals-and-sandbox";
    dxsxr = "codex resume --model gpt-5.3-codex-spark -c model_reasoning_effort=xhigh --dangerously-bypass-approvals-and-sandbox";
    dxclr = "codex resume --model gpt-5.3-codex -c model_reasoning_effort=low --dangerously-bypass-approvals-and-sandbox";
    dxcmr = "codex resume --model gpt-5.3-codex -c model_reasoning_effort=medium --dangerously-bypass-approvals-and-sandbox";
    dxchr = "codex resume --model gpt-5.3-codex -c model_reasoning_effort=high --dangerously-bypass-approvals-and-sandbox";
    dxcxr = "codex resume --model gpt-5.3-codex -c model_reasoning_effort=xhigh --dangerously-bypass-approvals-and-sandbox";
    dx4lr = "codex resume --model gpt-5.4 -c model_reasoning_effort=low --dangerously-bypass-approvals-and-sandbox";
    dx4mr = "codex resume --model gpt-5.4 -c model_reasoning_effort=medium --dangerously-bypass-approvals-and-sandbox";
    dx4hr = "codex resume --model gpt-5.4 -c model_reasoning_effort=high --dangerously-bypass-approvals-and-sandbox";
    dx4xr = "codex resume --model gpt-5.4 -c model_reasoning_effort=xhigh --dangerously-bypass-approvals-and-sandbox";
    dx5lr = "codex resume --model gpt-5.5 -c model_reasoning_effort=low --dangerously-bypass-approvals-and-sandbox";
    dx5mr = "codex resume --model gpt-5.5 -c model_reasoning_effort=medium --dangerously-bypass-approvals-and-sandbox";
    dx5hr = "codex resume --model gpt-5.5 -c model_reasoning_effort=high --dangerously-bypass-approvals-and-sandbox";
    dx5xr = "codex resume --model gpt-5.5 -c model_reasoning_effort=xhigh --dangerously-bypass-approvals-and-sandbox";

    # Claude Code - dangerously-skip-permissions + resume (interactive session picker)
    dcr = "claude --resume --dangerously-skip-permissions";
    dcslr = "claude --model Sonnet --effort low --resume --dangerously-skip-permissions";
    dcsmr = "claude --model Sonnet --effort medium --resume --dangerously-skip-permissions";
    dcshr = "claude --model Sonnet --effort high --resume --dangerously-skip-permissions";
    dcsxr = "claude --model Sonnet --effort xhigh --resume --dangerously-skip-permissions";
    dcsxmr = "claude --model Sonnet --effort max --resume --dangerously-skip-permissions";
    dcolr = "claude --model Opus --effort low --resume --dangerously-skip-permissions";
    dcomr = "claude --model Opus --effort medium --resume --dangerously-skip-permissions";
    dcohr = "claude --model Opus --effort high --resume --dangerously-skip-permissions";
    dcoxr = "claude --model Opus --effort xhigh --resume --dangerously-skip-permissions";
    dcoxmr = "claude --model Opus --effort max --resume --dangerously-skip-permissions";

    # Home Manager
    hmn = "home-manager news --flake $DOTFILES_PATH/nix#home-bart";
    hms = "home-manager switch --flake $DOTFILES_PATH/nix#home-bart";
    nixup = "nix flake update --flake $DOTFILES_PATH/nix && home-manager switch --flake $DOTFILES_PATH/nix#home-bart && sudo darwin-rebuild switch --flake $DOTFILES_PATH/nix#bartsmykla";
    hmsr = "home-manager switch --flake $DOTFILES_PATH/nix#home-bart && hs -c \"hs.reload()\"";
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
