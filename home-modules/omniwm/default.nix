{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.omniwm;
  tomlFormat = pkgs.formats.toml { };
in
{
  options.programs.omniwm = {

    enable = lib.mkEnableOption "OmniWM tiling window manager";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.omniwm;
      defaultText = lib.literalExpression "pkgs.omniwm";
      description = "The OmniWM package to install.";
    };

    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = lib.literalExpression ''
        {
          general = {
            defaultLayoutType = "niri";
            ipcEnabled = true;
          };
          gaps = {
            size = 12;
            outer = { left = 8; right = 8; top = 8; bottom = 8; };
          };
          borders = {
            enabled = true;
            width = 3.0;
          };
        }
      '';
      description = ''
        Configuration written to {file}`~/.config/omniwm/settings.toml`.

        Any valid OmniWM setting can be specified here as a freeform attribute
        set matching the TOML structure. By default, automatic update checks
        are disabled for Nix-managed installs.

        See <https://github.com/BarutSRB/OmniWM> for the full list of options.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Disable automatic update checks by default — Nix manages the package.
    programs.omniwm.settings = {
      general = {
        updateChecksEnabled = lib.mkDefault false;
      };
    };

    home.packages = [ cfg.package ];

    home.file.".config/omniwm/settings.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "omniwm-settings.toml" cfg.settings;
    };
  };
}
