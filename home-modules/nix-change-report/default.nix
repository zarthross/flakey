{ config, pkgs, lib, ... }:

{
  home.activation.nix-change-report =
    lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
      ${pkgs.nvd}/bin/nvd diff $genProfilePath $newGenPath
    '';
}
