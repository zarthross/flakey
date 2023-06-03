{ pkgs, inputs, ... }:

{
  prusa-slicer-latest = pkgs.callPackage ./prusa-slicer-latest { };
}
