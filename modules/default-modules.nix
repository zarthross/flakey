# Bridges flake.modules.<class>.<name> (flake-parts' dendritic-style merge
# point, see inputs.flake-parts.flakeModules.modules) into the
# flake.{darwin,nixos,home}Modules attrstes that nix-darwin/NixOS/home-manager
# actually consume as flake outputs. Every feature file declares itself once,
# under flake.modules.<class>.<name>, and this file is the only place that
# knows about the bridge.
#
# Each entry is wrapped with an explicit, stable `key` (see withStableKey)
# before being exported. Pre-migration, these were file paths, and nixpkgs'
# module system dedups path-valued modules for free via `key = toString
# path` - so the same module could safely be imported both directly by a
# downstream flake AND transitively (e.g. bundled into another flake's own
# `default`), and only counted once. Our new flake.modules.<class>.<name>
# entries are inline function values with no `key` of their own, so without
# this wrapping each import site would get a different auto-generated,
# import-position-based key, and importing the same module twice would
# throw a duplicate option declaration error instead of silently deduping.
#
# The composite `default` modules below are intentionally NOT added to
# flake.modules.<class> (that would make them a sibling entry of the very
# attrset being bridged into flake.<class>Modules, causing infinite
# recursion). They import from the already-wrapped local bindings below
# (darwinModules/nixosModules/homeModules) rather than reading
# config.flake.modules.<class> directly, so a module reached both via
# `default` and via its own standalone export still resolves to the same
# key and dedups correctly.
{
  inputs,
  config,
  lib,
  ...
}:
let
  withStableKey = class: name: module: {
    key = "flakey:${class}:${name}";
    imports = [ module ];
  };
  bridge = class: lib.mapAttrs (withStableKey class);

  darwinModules = bridge "darwin" config.flake.modules.darwin;
  nixosModules = bridge "nixos" config.flake.modules.nixos;
  homeModules = bridge "homeManager" config.flake.modules.homeManager;
in
{
  imports = [ inputs.flake-parts.flakeModules.modules ];

  flake.darwinModules = darwinModules // {
    default = {
      imports = [ darwinModules.nix-change-report ];
    };
  };

  flake.nixosModules = nixosModules // {
    default = {
      imports = [
        nixosModules.nix-change-report
        nixosModules.allow-unfree-predicates
      ];
    };
  };

  flake.homeModules = homeModules // {
    default = {
      imports = [
        homeModules.nix-change-report
        homeModules.allow-unfree-predicates
      ];
    };
  };
}
