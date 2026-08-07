{ inputs, ... }:
{
  imports = [
    inputs.flake-file.flakeModules.dendritic
  ];

  flake-file.inputs.flake-file.url = "github:denful/flake-file";

  flake-file.inputs.import-tree = {
    url = "github:denful/import-tree";
    flake = false;
  };

  flake-file.inputs.nixpkgs.url = "github:NixOS/nixpkgs/master";

  # `.filterNot` excludes `*.pkg.nix` files from auto-import: plain
  # callPackage derivation files colocated with their owning module.
  flake-file.outputs = ''
    inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; }
      (((import inputs.import-tree).filterNot (inputs.nixpkgs.lib.hasSuffix ".pkg.nix")) ./modules)
  '';
}
