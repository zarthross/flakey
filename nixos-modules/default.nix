rec {
  nixos-change-report = ./nixos-change-report;
  allow-unfree-predicates = ./allow-unfree-predicates;
  default = { imports = [ nixos-change-report allow-unfree-predicates ]; };
}
