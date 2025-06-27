{
  config,
  pkgs,
  lib,
  ...
}:

{
  system.activationScripts = {
    postActivation = {
      text = ''
        ${pkgs.nvd}/bin/nvd diff /run/current-system $systemConfig
      '';
    };
  };
}
