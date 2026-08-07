{ config, ... }:
{
  flake.modules.darwin.nix-change-report =
    { pkgs, ... }:
    {
      system.activationScripts = {
        postActivation = {
          text = ''
            ${pkgs.nvd}/bin/nvd diff /run/current-system $systemConfig
          '';
        };
      };
    };

  flake.modules.nixos.nix-change-report =
    { pkgs, ... }:
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
    };

  flake.modules.homeManager.nix-change-report =
    { pkgs, lib, ... }:
    {
      home.activation.nix-change-report =
        lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ]
          ''
            ${pkgs.nvd}/bin/nvd diff $genProfilePath $newGenPath
          '';
    };

  flake.modules.darwin.nix-darwin-change-report =
    builtins.trace
      "[1;31mwarning: nix-darwin-change-report is Deprecated, please use nix-change-report.["
      { imports = [ config.flake.modules.darwin.nix-change-report ]; };

  flake.modules.nixos.nixos-change-report =
    builtins.trace "[1;31mwarning: nixos-change-report is Deprecated, please use nix-change-report.["
      { imports = [ config.flake.modules.nixos.nix-change-report ]; };

  flake.modules.homeManager.hm-change-report =
    builtins.trace "[1;31mwarning: hm-change-report is Deprecated, please use nix-change-report.["
      { imports = [ config.flake.modules.homeManager.nix-change-report ]; };
}
