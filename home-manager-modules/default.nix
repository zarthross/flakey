rec {
  hm-change-report = ./hm-change-report;
  allow-unfree-predicates = ../nixos-modules/allow-unfree-predicates;
  default = {
    imports = [ hm-change-report allow-unfree-predicates ];
  };
}
