{ pkgs, inputs, ... }:

{
  rectangle = pkgs.callPackage ./rectangle {};
  bitwarden = pkgs.callPackage ./bitwarden {};
  hot = pkgs.callPackage ./hot {};
  keepingYouAwake = pkgs.callPackage ./KeepingYouAwake {};
}
