# Tool completions and additional configurations
#
# Fish completions use a caching strategy to balance speed and freshness:
# - Cobra-based tools (kubectl, docker, etc.) generate dynamic completions
# - We wrap them with caching to avoid calling the binary on every tab press
# - Cache is stored per-session and invalidated when binary changes
# - First tab press: ~300ms (generates cache)
# - Subsequent: <10ms (uses cache)
{ pkgs, ... }:

let
  # Creates a cached completion wrapper for Cobra-based dynamic completions
  # This eliminates the ~300ms delay on every tab press after the first use
  mkCachedCompletion = tool: binary: pkgs.writeText "${tool}-completion.fish" ''
    # Cached completion wrapper for ${tool}
    # Generates completions once per session, then reuses cached version

    set -g __fish_${tool}_completion_loaded 0
    set -g __fish_${tool}_completions ""

    function __${tool}_cached_completion
        # Load completions once per session
        if test $__fish_${tool}_completion_loaded -eq 0
            set -g __fish_${tool}_completions (${binary} __complete (commandline -opc)[2..] (commandline -ct) 2>/dev/null)
            set -g __fish_${tool}_completion_loaded 1
        end

        # Print cached completions
        for completion in $__fish_${tool}_completions
            echo $completion
        end
    end

    # Register the completion
    complete -c ${tool} -f -a "(__${tool}_cached_completion)"
  '';
in
{
  xdg.configFile = {
    # Note: kubectl and docker completions are provided by OrbStack

    "fish/completions/k3d.fish".source =
      mkCachedCompletion "k3d" "${pkgs.k3d}/bin/k3d";

    "fish/completions/golangci-lint.fish".source =
      mkCachedCompletion "golangci-lint" "${pkgs.golangci-lint}/bin/golangci-lint";

    "fish/completions/goreleaser.fish".source =
      mkCachedCompletion "goreleaser" "${pkgs.goreleaser}/bin/goreleaser";

    "fish/completions/hcloud.fish".source =
      mkCachedCompletion "hcloud" "${pkgs.hcloud}/bin/hcloud";

    # klab - Python tool installed in venv
    "fish/completions/klab.fish".text = ''
      complete --command klab --no-files --arguments "(env _KLAB_COMPLETE=complete_fish _TYPER_COMPLETE_FISH_ACTION=get-args _TYPER_COMPLETE_ARGS=(commandline -cp) klab)" --condition "env _KLAB_COMPLETE=complete_fish _TYPER_COMPLETE_FISH_ACTION=is-args _TYPER_COMPLETE_ARGS=(commandline -cp) klab"
    '';

    "fish/completions/codex.fish".text = ''
      if command -sq codex
        codex completion fish | source
      end
    '';

    # opencode - dynamic runtime completion with fish-first fallback strategy
    # - prefers native fish completion if opencode adds it
    # - falls back to yargs completion API today
    # - augments yargs candidates with descriptions parsed from --help output
    # - uses in-memory + disk cache, invalidated when the binary changes
    "fish/completions/opencode.fish".text = ''
      if command -sq opencode
        function __opencode_bin --description "Resolve opencode binary path"
          if test -x "$HOME/.opencode/bin/opencode"
            printf '%s\n' "$HOME/.opencode/bin/opencode"
            return 0
          end

          command -sq opencode; or return 1
          command -s opencode
        end

        function __opencode_binary_signature --description "Get executable signature for cache invalidation"
          set -l bin (__opencode_bin); or return 1

          set -l sig (command stat -f '%m:%z:%i' "$bin" 2>/dev/null)
          if test $status -ne 0
            set sig (command stat -c '%Y:%s:%i' "$bin" 2>/dev/null)
          end

          test -n "$sig"; or return 1
          printf '%s:%s\n' "$bin" "$sig"
        end

        function __opencode_cache_id --description "Build stable cache id from binary signature"
          set -l sig (__opencode_binary_signature); or return 1
          string replace -ar -- '[^[:alnum:]_]' '_' "$sig"
        end

        function __opencode_cache_root --description "Return opencode fish cache root"
          printf '%s\n' "$HOME/.cache/opencode/fish-completions"
        end

        function __opencode_context_id --description "Build context id for cache"
          if test (count $argv) -eq 0
            printf '%s\n' root
            return 0
          end

          set -l joined (string join "__" -- $argv)
          string replace -ar -- '[^[:alnum:]_]' '_' "$joined"
        end

        function __opencode_strip_ansi --argument-names text --description "Strip ANSI escape sequences"
          string replace -ar -- '\x1b\[[0-9;]*[[:alpha:]]' "" "$text"
        end

        function __opencode_clean_desc --argument-names text --description "Normalize completion descriptions"
          set -l desc (string trim -- "$text")
          set desc (string replace -r -- '\s*\[[^]]+\].*$' "" "$desc")
          string trim -- "$desc"
        end

        function __opencode_add_context_desc --argument-names context_id token desc --description "Add context token description"
          test -n "$token"; or return 1

          set -l token_var "__opencode_ctx_"$context_id"_tokens"
          set -l desc_var "__opencode_ctx_"$context_id"_descs"

          for existing in $$token_var
            if test "$existing" = "$token"
              return 0
            end
          end

          set -a $token_var "$token"
          set -a $desc_var "$desc"
        end

        function __opencode_lookup_context_desc --argument-names context_id token --description "Lookup description for completion token"
          set -l token_var "__opencode_ctx_"$context_id"_tokens"
          set -l desc_var "__opencode_ctx_"$context_id"_descs"

          set -l tokens $$token_var
          set -l descs $$desc_var
          set -l total (count $tokens)

          if test $total -eq 0
            return 1
          end

          for idx in (seq 1 $total)
            if test "$tokens[$idx]" = "$token"
              printf '%s\n' "$descs[$idx]"
              return 0
            end
          end

          if string match -rq -- '^--[[:alnum:]]$' "$token"
            set -l short_flag "-"(string sub -s 3 -- "$token")
            for idx in (seq 1 $total)
              if test "$tokens[$idx]" = "$short_flag"
                printf '%s\n' "$descs[$idx]"
                return 0
              end
            end
          end

          return 1
        end

        function __opencode_context_has_subcommand --argument-names context_id token --description "Check known subcommand in context"
          set -l subcmd_var "__opencode_ctx_"$context_id"_subcmds"
          contains -- "$token" $$subcmd_var
        end

        function __opencode_reset_cache_if_needed --description "Invalidate cache when binary changes"
          set -l cache_id (__opencode_cache_id); or return 1

          if test "$__opencode_active_cache_id" != "$cache_id"
            for var_name in (set -n | string match -r -- '^__opencode_ctx_')
              set -e $var_name
            end

            set -g __opencode_active_cache_id "$cache_id"
            set -g __opencode_cache_key ""
            set -g __opencode_cache_results
            set -g __opencode_native_mode ""
          end

          return 0
        end

        function __opencode_context_cache_file --argument-names context_id --description "Return on-disk context cache path"
          test -n "$__opencode_active_cache_id"; or return 1
          set -l root (__opencode_cache_root)
          printf '%s/%s/context_%s.tsv\n' "$root" "$__opencode_active_cache_id" "$context_id"
        end

        function __opencode_native_mode_file --description "Return on-disk native mode cache path"
          test -n "$__opencode_active_cache_id"; or return 1
          set -l root (__opencode_cache_root)
          printf '%s/%s/native_mode\n' "$root" "$__opencode_active_cache_id"
        end

        function __opencode_native_script_file --description "Return on-disk native completion script path"
          test -n "$__opencode_active_cache_id"; or return 1
          set -l root (__opencode_cache_root)
          printf '%s/%s/native_completion.fish\n' "$root" "$__opencode_active_cache_id"
        end

        function __opencode_load_context_cache_from_disk --argument-names context_id --description "Load parsed context cache from disk"
          set -l file (__opencode_context_cache_file "$context_id"); or return 1
          test -r "$file"; or return 1

          set -l subcmd_var "__opencode_ctx_"$context_id"_subcmds"
          set -l loaded_any 0

          while read -l row
            set -l cols (string split -m 2 "\t" -- "$row")
            if test (count $cols) -lt 3
              continue
            end

            set -l kind "$cols[1]"
            set -l token "$cols[2]"
            set -l desc "$cols[3]"

            test -n "$token"; or continue
            __opencode_add_context_desc "$context_id" "$token" "$desc"

            if test "$kind" = cmd
              set -a $subcmd_var "$token"
            end

            set loaded_any 1
          end < "$file"

          test $loaded_any -eq 1
        end

        function __opencode_store_context_cache_to_disk --argument-names context_id --description "Persist parsed context cache to disk"
          set -l file (__opencode_context_cache_file "$context_id"); or return 1
          set -l dir (string replace -r -- '/[^/]+$' "" "$file")
          command mkdir -p "$dir" 2>/dev/null; or return 1

          set -l token_var "__opencode_ctx_"$context_id"_tokens"
          set -l desc_var "__opencode_ctx_"$context_id"_descs"
          set -l subcmd_var "__opencode_ctx_"$context_id"_subcmds"

          set -l tokens $$token_var
          set -l descs $$desc_var
          set -l subcmds $$subcmd_var
          set -l lines

          set -l total (count $tokens)
          for idx in (seq 1 $total)
            set -l token "$tokens[$idx]"
            test -n "$token"; or continue

            set -l kind opt
            if contains -- "$token" $subcmds
              set kind cmd
            end

            set -l desc "$descs[$idx]"
            set -a lines "$kind\t$token\t$desc"
          end

          if test (count $lines) -eq 0
            return 0
          end

          printf '%s\n' $lines > "$file" 2>/dev/null
        end

        function __opencode_load_native_mode_cache --description "Load native mode decision from disk cache"
          set -l mode_file (__opencode_native_mode_file); or return 1
          test -r "$mode_file"; or return 1

          set -l mode
          read -l mode < "$mode_file"; or return 1

          if test "$mode" = yargs
            set -g __opencode_native_mode yargs
            return 1
          end

          if test "$mode" != native
            return 1
          end

          set -l script_file (__opencode_native_script_file); or return 1
          test -r "$script_file"; or return 1

          complete -c opencode -e
          source "$script_file" 2>/dev/null; or return 1
          set -g __opencode_native_mode native
          return 0
        end

        function __opencode_store_native_mode_cache --argument-names mode script --description "Persist native mode decision to disk"
          set -l mode_file (__opencode_native_mode_file); or return 1
          set -l dir (string replace -r -- '/[^/]+$' "" "$mode_file")
          command mkdir -p "$dir" 2>/dev/null; or return 1

          printf '%s\n' "$mode" > "$mode_file" 2>/dev/null

          if test "$mode" = native
            set -l script_file (__opencode_native_script_file); or return 1
            printf '%s\n' "$script" > "$script_file" 2>/dev/null
          end

          return 0
        end

        function __opencode_ensure_context_cache --description "Load and parse help for context"
          set -l context $argv
          set -l context_id (__opencode_context_id $context)
          set -l loaded_var "__opencode_ctx_"$context_id"_loaded"

          set -q $loaded_var; and return 0

          set -l token_var "__opencode_ctx_"$context_id"_tokens"
          set -l desc_var "__opencode_ctx_"$context_id"_descs"
          set -l subcmd_var "__opencode_ctx_"$context_id"_subcmds"

          set -g $token_var
          set -g $desc_var
          set -g $subcmd_var

          if __opencode_load_context_cache_from_disk "$context_id"
            set -g $loaded_var 1
            return 0
          end

          set -l bin (__opencode_bin); or begin
            set -g $loaded_var 1
            return 1
          end

          set -l help_lines (env NO_COLOR=1 $bin $context --help 2>/dev/null)
          if test (count $help_lines) -eq 0
            set -g $loaded_var 1
            return 0
          end

          set -l section ""
          set -l prefix_tokens opencode $context
          set -l prefix_count (count $prefix_tokens)

          for raw_line in $help_lines
            set -l line (__opencode_strip_ansi "$raw_line")
            set -l trimmed (string trim -- "$line")

            if test "$trimmed" = "Commands:"
              set section commands
              continue
            end

            if test "$trimmed" = "Options:"
              set section options
              continue
            end

            if string match -rq -- '^[[:upper:]][[:alpha:] ]*:$' "$trimmed"
              set section ""
              continue
            end

            if test "$section" = commands
              if not string match -rq -- '^opencode(\s|$)' "$trimmed"
                continue
              end

              if not string match -rq -- '^.+\s{2,}.+$' "$trimmed"
                continue
              end

              set -l usage (string replace -r -- '^(.+?)\s{2,}.+$' '$1' "$trimmed")
              set -l raw_desc (string replace -r -- '^.+?\s{2,}(.+)$' '$1' "$trimmed")
              set -l usage_tokens (string split " " -- "$usage")

              if test (count $usage_tokens) -lt (math $prefix_count + 1)
                continue
              end

              set -l prefix_matches 1
              for idx in (seq 1 $prefix_count)
                if test "$usage_tokens[$idx]" != "$prefix_tokens[$idx]"
                  set prefix_matches 0
                  break
                end
              end

              test $prefix_matches -eq 1; or continue

              set -l candidate_index (math $prefix_count + 1)
              set -l candidate "$usage_tokens[$candidate_index]"

              if string match -rq -- '^[\[<]' "$candidate"
                continue
              end

              set -l desc (__opencode_clean_desc "$raw_desc")
              __opencode_add_context_desc "$context_id" "$candidate" "$desc"
              set -a $subcmd_var "$candidate"

              if string match -rq -- '\[aliases?: [^]]+\]' "$trimmed"
                set -l alias_csv (string replace -r -- '.*\[aliases?: ([^]]+)\].*' '$1' "$trimmed")
                for alias in (string split "," -- "$alias_csv")
                  set alias (string trim -- "$alias")
                  test -n "$alias"; or continue
                  __opencode_add_context_desc "$context_id" "$alias" "$desc"
                  set -a $subcmd_var "$alias"
                end
              end

              continue
            end

            if test "$section" = options
              if not string match -rq -- '^-' "$trimmed"
                continue
              end

              if not string match -rq -- '^.+\s{2,}.+$' "$trimmed"
                continue
              end

              set -l flag_spec (string replace -r -- '^(.+?)\s{2,}.+$' '$1' "$trimmed")
              set -l raw_desc (string replace -r -- '^.+?\s{2,}(.+)$' '$1' "$trimmed")
              set -l desc (__opencode_clean_desc "$raw_desc")
              set -l flags (string match -ra -- '--?[[:alnum:]][[:alnum:]-]*' "$flag_spec")

              for flag in $flags
                __opencode_add_context_desc "$context_id" "$flag" "$desc"
              end
            end
          end

          set -g $loaded_var 1
          __opencode_store_context_cache_to_disk "$context_id" >/dev/null 2>&1
          return 0
        end

        function __opencode_current_context --description "Resolve current command context"
          set -l args (commandline -opc)
          set -l context

          if test (count $args) -lt 2
            return 0
          end

          for token in $args[2..-1]
            if string match -q -- '-*' "$token"
              break
            end

            set -l context_id (__opencode_context_id $context)
            __opencode_ensure_context_cache $context

            if __opencode_context_has_subcommand "$context_id" "$token"
              set -a context "$token"
              continue
            end

            break
          end

          printf '%s\n' $context
        end

        function __opencode_is_fish_completion_script --argument-names script --description "Detect fish completion script"
          test -n "$script"; or return 1

          if string match -rq -- 'COMP_WORDS|COMPREPLY|mapfile|bashrc|complete -o ' "$script"
            return 1
          end

          string match -rq -- 'complete[[:space:]]+-c[[:space:]]+opencode' "$script"
        end

        function __opencode_emit_unique --argument-names context_id --description "Escape, annotate, and dedupe completion results"
          set -l seen
          set -l lines $argv[2..-1]

          for line in $lines
            test -n "$line"; or continue

            set -l value "$line"
            set -l desc ""

            if string match -q -- "*\t*" "$line"
              set -l fields (string split -m 1 "\t" -- "$line")
              set value "$fields[1]"
              set desc "$fields[2]"
            end

            if test "$value" = '$0'
              continue
            end

            contains -- "$value" $seen; and continue
            set -a seen "$value"

            if test -z "$desc"
              set -l looked_up (__opencode_lookup_context_desc "$context_id" "$value")
              if test $status -eq 0
                set desc "$looked_up"
              end
            end

            set -l escaped_value (string escape -- "$value")
            if test -n "$desc"
              printf '%s\t%s\n' "$escaped_value" "$desc"
            else
              printf '%s\n' "$escaped_value"
            end
          end
        end

        function __opencode_emit_context_matches --argument-names context_id cur --description "Emit cached command or option names for the current context"
          set -l token_var "__opencode_ctx_"$context_id"_tokens"
          set -l desc_var "__opencode_ctx_"$context_id"_descs"
          set -l subcmd_var "__opencode_ctx_"$context_id"_subcmds"

          set -l tokens $$token_var
          set -l descs $$desc_var
          set -l subcmds $$subcmd_var

          set -l total (count $tokens)
          if test $total -eq 0
            return 1
          end

          set -l cur_regex (string escape --style=regex -- "$cur")
          set -l wants_options 0
          if test -n "$cur"
            if string match -q -- '-*' "$cur"
              set wants_options 1
            end
          end

          set -l seen
          set -l emitted 0

          for idx in (seq 1 $total)
            set -l token "$tokens[$idx]"
            set -l desc "$descs[$idx]"

            if test "$token" = '$0'
              continue
            end

            if test $wants_options -eq 1
              if not string match -q -- '-*' "$token"
                continue
              end
            else
              if string match -q -- '-*' "$token"
                continue
              end

              if not contains -- "$token" $subcmds
                continue
              end
            end

            if test -n "$cur"
              if not string match -riq -- "^$cur_regex" "$token"
                continue
              end
            end

            contains -- "$token" $seen; and continue
            set -a seen "$token"

            set -l escaped_token (string escape -- "$token")
            if test -n "$desc"
              printf '%s\t%s\n' "$escaped_token" "$desc"
            else
              printf '%s\n' "$escaped_token"
            end

            set emitted 1
          end

          test $emitted -eq 1
        end

        function __opencode_emit_with_fallback --argument-names context_id cur --description "Emit matching candidates or file fallback"
          set -l raw $argv[3..-1]

          if test (count $raw) -eq 0
            __fish_complete_path "$cur"
            return 0
          end

          if test -z "$cur"
            __opencode_emit_unique "$context_id" $raw
            return 0
          end

          set -l cur_regex (string escape --style=regex -- "$cur")
          set -l matched

          for line in $raw
            set -l value "$line"

            if string match -q -- "*\t*" "$line"
              set -l fields (string split -m 1 "\t" -- "$line")
              set value "$fields[1]"
            end

            if test "$value" = '$0'
              continue
            end

            if string match -riq -- "^$cur_regex" "$value"
              set -a matched "$line"
            end
          end

          if test (count $matched) -eq 0
            __fish_complete_path "$cur"
            return 0
          end

          __opencode_emit_unique "$context_id" $matched
        end

        function __opencode_yargs_completion --description "Dynamic yargs completion fallback"
          __opencode_reset_cache_if_needed; or return 1

          set -l bin (__opencode_bin); or return 1
          set -l args (commandline -opc)
          set -l cur (commandline -ct)
          set -l context (__opencode_current_context)
          set -l context_id (__opencode_context_id $context)

          __opencode_ensure_context_cache $context

          if __opencode_emit_context_matches "$context_id" "$cur"
            return 0
          end

          set -l args_key (string join "|" -- (string escape --style=var -- $args))
          set -l cur_key (string escape --style=var -- "$cur")
          set -l cache_key "$__opencode_active_cache_id|$args_key|$cur_key"

          if test "$__opencode_cache_key" = "$cache_key"
            __opencode_emit_with_fallback "$context_id" "$cur" $__opencode_cache_results
            return 0
          end

          set -l raw ($bin --get-yargs-completions $args $cur 2>/dev/null)
          set -g __opencode_cache_key "$cache_key"
          set -g __opencode_cache_results $raw

          __opencode_emit_with_fallback "$context_id" "$cur" $raw
        end

        function __opencode_try_native_fish_completion --description "Source native fish completion when available"
          __opencode_reset_cache_if_needed; or return 1

          if test "$__opencode_native_mode" = native
            return 0
          end

          if test "$__opencode_native_mode" = yargs
            return 1
          end

          if __opencode_load_native_mode_cache
            return 0
          end

          if test "$__opencode_native_mode" = yargs
            return 1
          end

          set -l bin (__opencode_bin); or return 1

          set -l script ($bin completion fish 2>/dev/null | string collect --allow-empty)
          set -l probe_status $status
          if __opencode_is_fish_completion_script "$script"
            complete -c opencode -e
            printf '%s\n' "$script" | source
            set -g __opencode_native_mode native
            __opencode_store_native_mode_cache native "$script" >/dev/null 2>&1
            return 0
          end

          if test $probe_status -ne 0 -o -z "$script"
            set script ($bin completion --shell fish 2>/dev/null | string collect --allow-empty)
            set probe_status $status
            if __opencode_is_fish_completion_script "$script"
              complete -c opencode -e
              printf '%s\n' "$script" | source
              set -g __opencode_native_mode native
              __opencode_store_native_mode_cache native "$script" >/dev/null 2>&1
              return 0
            end

            if test $probe_status -ne 0 -o -z "$script"
              set script ($bin completion --fish 2>/dev/null | string collect --allow-empty)
              if __opencode_is_fish_completion_script "$script"
                complete -c opencode -e
                printf '%s\n' "$script" | source
                set -g __opencode_native_mode native
                __opencode_store_native_mode_cache native "$script" >/dev/null 2>&1
                return 0
              end
            end
          end

          set -g __opencode_native_mode yargs
          __opencode_store_native_mode_cache yargs "" >/dev/null 2>&1
          return 1
        end

        if not __opencode_try_native_fish_completion
          complete -c opencode -e
          complete -c opencode -f -a "(__opencode_yargs_completion)"
        end
      end
    '';

    # Note: mise completions are handled by programs.mise.enableFishIntegration
    # Note: broot integration (br.fish) is handled by programs.broot in broot.nix
    # with enableFishIntegration = true
  };
}
