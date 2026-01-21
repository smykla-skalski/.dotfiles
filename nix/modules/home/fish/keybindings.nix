# Fish shell key bindings and AF abbreviation setup
{ ... }:

{
  programs.fish = {
    functions.fish_user_key_bindings = {
      body = ''
        bind \cx\ce edit_command_buffer
        bind nul accept-autosuggestion
        bind --erase --preset \cd
      '';
    };

    interactiveShellInit = ''
      # fzf bindings
      # History: Ctrl+R (default) - supports multi-select with Tab/Shift+Tab
      fzf_configure_bindings \
        --directory=\cf \
        --git_log=\co \
        --git_status=\cs \
        --processes=\cp \
        --variables=\cv

      # Set up af-based abbreviations with --function flag
      # These abbreviations call functions that execute 'af shortcuts abbreviations <name>'
      # which returns the expanded command string
      abbr --erase gcm gcmf gcmff p pF pf pn pnF pnf d dfi po poF pof pon ponF ponf pO pOF pOf pOn pOnF pOnf pu puF puf pun punF punf pU pUF pUf pUn pUnF pUnf 2>/dev/null
      abbr --add --function __abbr_af_gcm gcm
      abbr --add --function __abbr_af_gcmf gcmf
      abbr --add --function __abbr_af_gcmff gcmff
      abbr --add --function __abbr_af_gp p
      abbr --add --function __abbr_af_gd d
      abbr --add --function __abbr_af_dfi dfi
      abbr --add --function __abbr_af_po_origin_first po
      abbr --add --function __abbr_af_pof_origin_first_force poF
      abbr --add --function __abbr_af_pof_origin_first_force_lease pof
      abbr --add --function __abbr_af_pon_origin_first_noverify pon
      abbr --add --function __abbr_af_ponf_origin_first_noverify_force ponF
      abbr --add --function __abbr_af_ponf_origin_first_noverify_force_lease ponf
      abbr --add --function __abbr_af_po_origin pO
      abbr --add --function __abbr_af_pof_origin_force pOF
      abbr --add --function __abbr_af_pof_origin_force_lease pOf
      abbr --add --function __abbr_af_pon_origin_noverify pOn
      abbr --add --function __abbr_af_ponf_origin_noverify_force pOnF
      abbr --add --function __abbr_af_ponf_origin_noverify_force_lease pOnf
      abbr --add --function __abbr_af_pu_upstream_first pu
      abbr --add --function __abbr_af_puf_upstream_first_force puF
      abbr --add --function __abbr_af_puf_upstream_first_force_lease puf
      abbr --add --function __abbr_af_pun_upstream_first_noverify pun
      abbr --add --function __abbr_af_punf_upstream_first_noverify_force punF
      abbr --add --function __abbr_af_punf_upstream_first_noverify_force_lease punf
      abbr --add --function __abbr_af_pu_upstream pU
      abbr --add --function __abbr_af_puf_upstream_force pUF
      abbr --add --function __abbr_af_puf_upstream_force_lease pUf
      abbr --add --function __abbr_af_pun_upstream_noverify pUn
      abbr --add --function __abbr_af_punf_upstream_noverify_force pUnF
      abbr --add --function __abbr_af_punf_upstream_noverify_force_lease pUnf
    '';
  };
}
