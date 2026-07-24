{ inputs, ... }:
{
  imports = [ inputs.git-hooks-nix.flakeModule ];

  flake-file.inputs.git-hooks-nix = {
    url = "github:cachix/git-hooks.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  perSystem =
    { pkgs, ... }:
    let
      # NIX_BUILD_TOP is set inside every Nix build sandbox (including the
      # `checks.pre-commit-run` derivation that backs `nix flake check`),
      # but not when the installed git hook runs a real `git commit`. These
      # hooks need network/nix-store access the sandbox doesn't allow, so
      # they no-op inside the sandbox and only do real work on real commits.
      skipInSandbox = ''
        if [ -n "''${NIX_BUILD_TOP:-}" ]; then
          echo "Skipping in Nix build sandbox (needs network/store access); this hook still runs on real commits." >&2
          exit 0
        fi
      '';
      writeFlakeHook = pkgs.writeShellScript "write-flake-hook" ''
        ${skipInSandbox}
        exec nix run .#write-flake
      '';
      flakeCheckHook = pkgs.writeShellScript "flake-check-hook" ''
        ${skipInSandbox}
        exec nix flake check
      '';
    in
    {
      pre-commit = {
        check.enable = true;
        settings = {
          package = pkgs.prek;
          hooks = {
            treefmt.enable = true;
            write-flake = {
              enable = true;
              name = "write-flake";
              description = "Regenerate flake.nix from modules/**/flake-file.inputs. Skipped inside the nix flake check sandbox (needs network access).";
              entry = toString writeFlakeHook;
              language = "system";
              pass_filenames = false;
              files = "\\.nix$";
            };
            flake-check = {
              enable = true;
              name = "flake-check";
              description = "Run `nix flake check` before commit. Skipped inside the nix flake check sandbox itself (would recurse / needs network access).";
              entry = toString flakeCheckHook;
              language = "system";
              pass_filenames = false;
              files = "\\.nix$";
            };
          };
        };
      };
    };
}
