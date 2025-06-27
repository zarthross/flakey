{
  config,
  pkgs,
  lib,
  ...
}:

{
  system.activationScripts = {
    nix-change-report = {
      deps = [
        "binsh"
        "etc"
        "users"
        "usrbinenv"
      ];
      supportsDryActivation = true;
      text = ''
        PATH=$PATH:${pkgs.nix}/bin ${pkgs.nvd}/bin/nvd diff /run/current-system $systemConfig
      '';
    };
  };
}
