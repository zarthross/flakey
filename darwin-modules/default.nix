rec {
  nix-change-report = ./nix-change-report;
  nix-darwin-change-report =
    builtins.trace
      "[1;31mwarning: nix-darwin-change-report is Deprecated, please use nix-change-report.["
      nix-change-report;
  default = {
    imports = [ nix-change-report ];
  };
}
