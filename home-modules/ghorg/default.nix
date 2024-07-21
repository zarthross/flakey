{
  options,
  config,
  pkgs,
  lib,
  stdenv,
  ...
}:

with lib;
let
  cfg = config.programs.ghorg;
  configFile =
    if cfg.configFile != null then
      assert cfg.config == { };
      cfg.configFile
    else
      (pkgs.formats.yaml { }).generate "ghorg_config.yaml" cfg.config;
  recloneFile =
    if cfg.recloneFile != null then
      assert cfg.reclone == { };
      cfg.recloneFile
    else
      (pkgs.formats.yaml { }).generate "ghorg_reclone.yaml" cfg.reclone;
in
{
  options = {
    programs.ghorg = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable ghorg";
      };
      package = mkOption {
        type = types.package;
        default = pkgs.ghorg;
        defaultText = literalExpression "pkgs.ghorg";
        description = lib.mdDoc "The package with ghorg to be installed";
      };
      configFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = lib.mdDoc ''
          As alternative to ``config``, you can provide whole configuration
          directly in the YAML format of ghorg.
          You might want to utilize ``writeTextFile`` for this.
        '';
      };
      config = mkOption {
        type = types.attrs;
        default = { };
        defaultText = literalExpression "{ }";
        description = lib.mdDoc "Configuration for ghorg/conf.yaml";
      };
      recloneFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = lib.mdDoc ''
          As alternative to ``reclone``, you can provide whole reclone.yaml
          directly in the YAML format of ghorg.
          You might want to utilize ``writeTextFile`` for this.
        '';
      };
      reclone = mkOption {
        type = types.attrs;
        default = { };
        defaultText = literalExpression "{ }";
        description = lib.mdDoc "Configuration for ghorg/reclone.yaml";
      };
    };
  };
  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    xdg.configFile = {
      "ghorg/reclone.yaml".source = recloneFile;
      "ghorg/conf.yaml".source = configFile;
    };
  };
}
