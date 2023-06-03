{ pkgs, inputs, ... }:

{
  bitwarden = pkgs.callPackage ./bitwarden { };
  hot = pkgs.callPackage ./hot { };
  keepingYouAwake = pkgs.callPackage ./KeepingYouAwake { };
  rectangle = pkgs.callPackage ./rectangle { };
}
