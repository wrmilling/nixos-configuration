{ pkgs, ... }:
let
  nix-inspect = pkgs.writeShellScriptBin "nix-inspect" ''
    read -ra EXCLUDED <<< "$@"
    EXCLUDED+=(''${NIX_INSPECT_EXCLUDE[@]:-})

    IFS=":" read -ra PATHS <<< "$PATH"

    read -ra PROGRAMS <<< \
      "$(printf "%s\n" "''${PATHS[@]}" | ${pkgs.gnugrep}/bin/grep "\/nix\/store" | ${pkgs.gnugrep}/bin/grep -v "\-man" | ${pkgs.perl}/bin/perl -pe 's/^\/nix\/store\/\w{32}-([^\/]*)\/bin$/\1/' | ${pkgs.findutils}/bin/xargs)"

    for to_remove in "''${EXCLUDED[@]}"; do
        to_remove_full="$(printf "%s\n" "''${PROGRAMS[@]}" | grep "$to_remove" )"
        PROGRAMS=("''${PROGRAMS[@]/$to_remove_full}")
    done

    read -ra PROGRAMS <<< "''${PROGRAMS[@]}"
    echo "''${PROGRAMS[@]}"
  '';
in
{
  programs.starship = {
    enable = true;
    settings = {
      status.disabled = false;
      username = {
        format = "[$user]($style)";
        show_always = true;
      };
      hostname = {
        ssh_only = false;
        disabled = false;
        ssh_symbol = "@";
      };
      kubernetes.disabled = false;
      ocaml.disabled = true;
      perl.disabled = true;
      cmd_duration = {
        format = "took [$duration]($style) ";
      };

      directory = {
        format = "[$path]($style)( [$read_only]($read_only_style)) ";
      };
      nix_shell = {
        format = "[($name \\(develop\\) <- )$symbol]($style) ";
        impure_msg = "";
        symbol = " ";
        style = "bold red";
      };
      custom = {
        nix_inspect = {
          disabled = false;
          when = "test -z $IN_NIX_SHELL";
          command = "${nix-inspect}/bin/nix-inspect kitty imagemagick ncurses user-environment";
          format = "[($output <- )$symbol]($style) ";
          symbol = " ";
          style = "bold blue";
        };
      };

      # Cloud
      gcloud = {
        format = "on [$symbol$active(/$project)(\\($region\\))]($style)";
      };
      aws = {
        format = "on [$symbol$profile(\\($region\\))]($style)";
      };

      # Icon changes only \/
      aws.symbol = "  ";
      conda.symbol = " ";
      dart.symbol = " ";
      directory.read_only = " ";
      docker_context.symbol = " ";
      elixir.symbol = " ";
      elm.symbol = " ";
      gcloud.symbol = " ";
      git_branch.symbol = " ";
      golang.symbol = " ";
      hg_branch.symbol = " ";
      java.symbol = " ";
      julia.symbol = " ";
      memory_usage.symbol = " ";
      nim.symbol = " ";
      nodejs.symbol = " ";
      package.symbol = " ";
      perl.symbol = " ";
      php.symbol = " ";
      python.symbol = " ";
      ruby.symbol = " ";
      rust.symbol = " ";
      scala.symbol = " ";
      shlvl.symbol = "";
      swift.symbol = "ﯣ ";
      terraform.symbol = "行";
    };
  };
}