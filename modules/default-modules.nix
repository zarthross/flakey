# Bridges flake.modules.<class>.<name> (flake-parts' dendritic-style merge
# point, see inputs.flake-parts.flakeModules.modules) into the
# flake.{darwin,nixos,home}Modules attrstes that nix-darwin/NixOS/home-manager
# actually consume as flake outputs. Every feature file declares itself once,
# under flake.modules.<class>.<name>, and this file is the only place that
# knows about the bridge.
#
# The composite `default` modules below are intentionally NOT added to
# flake.modules.<class> (that would make them a sibling entry of the very
# attrset being bridged into flake.<class>Modules, causing infinite
# recursion). They read the feature files directly via plain `import`
# instead, and are set only on flake.<class>Modules.default, whose keys are
# separate from the bridge assignment above.
{ inputs, config, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.modules ];

  flake.darwinModules = config.flake.modules.darwin // {
    default = {
      imports = [ config.flake.modules.darwin.nix-change-report ];
    };
  };

  flake.nixosModules = config.flake.modules.nixos // {
    default = {
      imports = [
        config.flake.modules.nixos.nix-change-report
        config.flake.modules.nixos.allow-unfree-predicates
      ];
    };
  };

  flake.homeModules = config.flake.modules.homeManager // {
    default = {
      imports = [
        config.flake.modules.homeManager.nix-change-report
        config.flake.modules.homeManager.allow-unfree-predicates
      ];
    };
  };
}
