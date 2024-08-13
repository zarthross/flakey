rec {
  ghorg = ./ghorg;
  nix-change-report = ./nix-change-report;
  hm-change-report =
    builtins.trace
     "[1;31mwarning: hm-change-report is Deprecated, please use nix-change-report.["
    nix-change-report;
  allow-unfree-predicates = ../nixos-modules/allow-unfree-predicates;
  default = {
    imports = [ nix-change-report allow-unfree-predicates ];
  };
}
