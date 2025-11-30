# Starship prompt configuration
#
# Pastel-powerline theme based on:
# - https://starship.rs/presets/pastel-powerline.html
{ config, lib, pkgs, ... }:

{
  programs.starship = {
    enable = true;
    enableFishIntegration = true;

    settings = {
      "$schema" = "https://starship.rs/config-schema.json";

      format = lib.concatStrings [
        "$directory"
        "[](fg:#9A348E bg:#DA627D)"
        "$git_branch"
        "$git_status"
        "[](fg:#DA627D bg:#C47656)"
        "$git_commit"
        "[](fg:#C47656 bg:#86BBD8)"
        "$c"
        "$elixir"
        "$elm"
        "$golang"
        "$gradle"
        "$haskell"
        "$java"
        "$julia"
        "$nodejs"
        "$nim"
        "$rust"
        "$scala"
        "[](fg:#86BBD8 bg:#06969A)"
        "$docker_context"
        "[](fg:#06969A bg:#33658A)"
        "$time"
        "[ ](fg:#33658A)"
      ];

      add_newline = false;
      command_timeout = 3600;

      directory = {
        style = "bg:#9A348E";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
        substitutions = {
          "Documents" = "󰈙 ";
          "Downloads" = " ";
          "Music" = " ";
          "Pictures" = " ";
        };
      };

      c = {
        symbol = " ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      docker_context = {
        symbol = " ";
        style = "bg:#06969A";
        format = "[ $symbol $context ]($style)";
      };

      elixir = {
        symbol = " ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      elm = {
        symbol = " ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      git_branch = {
        symbol = "";
        style = "bg:#DA627D";
        format = "[ $symbol $branch ]($style)";
      };

      git_status = {
        style = "bg:#DA627D";
        format = "[$all_status$ahead_behind ]($style)";
      };

      git_commit = {
        style = "bg:#C47656";
        format = "[  $hash$tag ]($style)";
        only_detached = false;
      };

      golang = {
        symbol = " ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      gradle = {
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      haskell = {
        symbol = " ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      java = {
        symbol = " ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      julia = {
        symbol = " ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      nodejs = {
        symbol = "";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      nim = {
        symbol = "󰆥 ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      rust = {
        symbol = "";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      scala = {
        symbol = " ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      time = {
        disabled = true;
        time_format = "%R";
        style = "bg:#33658A";
        format = "[ ♥ $time ]($style)";
      };
    };
  };
}
