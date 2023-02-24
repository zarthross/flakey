{ config, pkgs, lib, ... }:

{
  system.activationScripts = {
    nix-change-report = {
      deps = [ "wrappers" "var" "binsh" "nix" "etc" "usrbinenv" "users" ];
      supportsDryActivation = true;
      text = ''
        PATH=$PATH:${pkgs.nix}/bin ${pkgs.nvd}/bin/nvd diff /run/current-system $systemConfig
      '';
    };
  };
}
