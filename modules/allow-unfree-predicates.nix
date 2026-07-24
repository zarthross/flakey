{ ... }:
let
  allowUnfreePredicates =
    {
      config,
      pkgs,
      nixpkgs,
      lib,
      ...
    }:
    let
      inherit (lib) mkOption types;
      cfg = config.nixpkgs.allowUnfreeRegexes;
    in
    {
      imports = [
        (lib.mkRenamedOptionModuleWith {
          sinceRelease = 2024;
          from = [ "allowedUnfreePackagesRegexs" ];
          to = [
            "nixpkgs"
            "allowUnfreeRegexes"
          ];
        })
      ];

      options = {
        nixpkgs.allowUnfreeRegexes = mkOption {
          default = [ ];
          type = types.listOf types.str;
          description = "List of unfree packages allowed to be installed";
          example = lib.literalExpression ''[ "steam" ]'';
        };
      };

      config = {
        nixpkgs.config.allowUnfreePredicate =
          pkg:
          let
            pkgName = (lib.getName pkg);
            matchPackges = (reg: !builtins.isNull (builtins.match reg pkgName));
          in
          builtins.any matchPackges cfg;
      };
    };
in
{
  # Not exported as flake.modules.darwin.allow-unfree-predicates today, even
  # though it would work there unmodified (nix-darwin has the same
  # nixpkgs.config.allowUnfreePredicate option). Preserved as-is; adding the
  # darwin export is tracked as a deferred follow-up.
  flake.modules.nixos.allow-unfree-predicates = allowUnfreePredicates;
  flake.modules.homeManager.allow-unfree-predicates = allowUnfreePredicates;
}
