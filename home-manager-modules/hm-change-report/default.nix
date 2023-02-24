{ config, pkgs, lib, ... }:

{
  home.activation.hm-change-report =
    lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
      ${pkgs.nvd}/bin/nvd diff $genProfilePath $newGenPath
    '';
}
