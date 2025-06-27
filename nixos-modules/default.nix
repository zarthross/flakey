rec {
  nix-change-report = ./nix-change-report;
  nixos-change-report = builtins.trace "[1;31mwarning: nixos-change-report is Deprecated, please use nix-change-report.[" nix-change-report;
  allow-unfree-predicates = ./allow-unfree-predicates;
  default = {
    imports = [
      nix-change-report
      allow-unfree-predicates
    ];
  };
}
