{ ... }:
let
  allowUnfreePredicates =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib)
        mkOption
        mkEnableOption
        mkIf
        types
        ;
      cfg = config.nixpkgs.allowUnfreeRegexes;
      enableCfg = config.flakey.allow-unfree-predicates;
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
        flakey.allow-unfree-predicates.enable =
          mkEnableOption "the flakey allow-unfree-predicates module"
          // {
            default = true;
            description = ''
              Whether to install the `nixpkgs.allowUnfreeRegexes`-driven
              `nixpkgs.config.allowUnfreePredicate`. Since
              `allowUnfreePredicate` is a single function slot, only one
              module should ever set it — disable this if you (or another
              module) set `nixpkgs.config.allowUnfreePredicate` yourself,
              to avoid the two silently clobbering each other.
            '';
          };

        nixpkgs.allowUnfreeRegexes = mkOption {
          default = [ ];
          type = types.listOf types.str;
          description = "List of unfree packages allowed to be installed";
          example = lib.literalExpression ''[ "steam" ]'';
        };
      };

      config = mkIf enableCfg.enable {
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
  # nix-darwin has the same nixpkgs.config.allowUnfreePredicate option as
  # NixOS/home-manager, so this module works unmodified for all three
  # classes and is bundled into each class's `default` in
  # modules/default-modules.nix.
  flake.modules.nixos.allow-unfree-predicates = allowUnfreePredicates;
  flake.modules.homeManager.allow-unfree-predicates = allowUnfreePredicates;
  flake.modules.darwin.allow-unfree-predicates = allowUnfreePredicates;
}
