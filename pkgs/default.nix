{ pkgs, inputs, ... }:

{
  rectangle = pkgs.callPackage ./rectangle {};
  bitwarden = pkgs.callPackage ./bitwarden {};
}
