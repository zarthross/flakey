{ inputs, ... }:

{
  default = final: prev:
      (import ../pkgs-darwin {
        inherit inputs;
        pkgs = final;
      }) //
      (import ../pkgs-linux {
        inherit inputs;
        pkgs = final;
      });
}
