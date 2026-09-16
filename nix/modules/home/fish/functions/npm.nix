# npm authentication for the private @kong scope on registry.npmjs.org
#
# The token is never written anywhere: ~/.npmrc carries a ${NPM_TOKEN}
# reference that npm expands as it reads the file, and NPM_TOKEN is resolved
# from 1Password the first time an npm-family command runs in a shell. A token
# kept out of the dotfile survives rotation on its own and cannot be leaked by
# a stray `cat ~/.npmrc` or a dotfiles backup.
#
# Resolving it in interactiveShellInit was the obvious alternative and is the
# wrong trade: `op read` costs about a second warm and several cold, which every
# terminal would pay for a token most of them never use.
{ lib, ... }:

let
  # 1Password, Shared vault, item "NPM konginc (SHARED)", field
  # "Read Token (exp. 11/18/2026)". Addressed by UUID because an op:// reference
  # rejects the parentheses in the item title.
  tokenReference = "op://q7r4hh4465zentymwtoonxxp3m/bfojwj2lryfxdo5mn7v6uwavii/njgkb53rqjhnfc3meuoyrddmkq";

  account = "team-kong.1password.com";

  # Every front end that reads ~/.npmrc and is actually installed here.
  frontEnds = [ "npm" "npx" "pnpm" "yarn" ];
in
{
  # pnpm no longer expands environment variables in registry credentials that
  # come from a project .npmrc, since that file is committed and could leak the
  # secret to an attacker-controlled registry. The user-level file is the only
  # place this still works.
  home.file.".npmrc".text = ''
    //registry.npmjs.org/:_authToken=''${NPM_TOKEN}
  '';

  programs.fish.functions = {
    __npm_token = {
      description = "Resolve NPM_TOKEN from 1Password, once per shell";
      body = ''
        if set -q NPM_TOKEN; and test -n "$NPM_TOKEN"
          return 0
        end

        set -l token (op read '${tokenReference}' --account ${account} 2>/dev/null)

        if test -z "$token"
          echo "NPM_TOKEN: 1Password did not answer. Unlock it, or run: op signin --account ${account}" >&2
          return 1
        end

        # Exported, so anything started from this shell - a mise task, a bash
        # subshell, a CI-shaped script - inherits it without asking again.
        set -gx NPM_TOKEN $token
      '';
    };
  } // lib.genAttrs frontEnds (cmd: {
    description = "Resolve the registry token before running ${cmd}";
    wraps = cmd;
    body = ''
      __npm_token; or return 1
      command ${cmd} $argv
    '';
  });
}
