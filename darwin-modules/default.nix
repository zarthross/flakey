rec {
  nix-darwin-change-report = ./nix-darwin-change-report ;
  default = { imports = [ nix-darwin-change-report ]; };
}
