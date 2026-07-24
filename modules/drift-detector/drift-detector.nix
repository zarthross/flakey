# Drift Detector Configuration Module
#
# Manages drift-detector's config.yaml via home-manager.
# https://github.com/yellowstonesoftware/drift-detector
#
# GitHub authentication is intentionally NOT handled here — export
# GITHUB_TOKEN yourself (shell env, direnv, agenix, etc), or override
# `package` with a wrapper script (e.g. one that sources a token from
# `pass` before exec-ing the real binary).
{
  flake.modules.homeManager.drift-detector =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    with lib;
    let
      cfg = config.programs.drift-detector;

      yamlFormat = pkgs.formats.yaml { };

      apiType = types.submodule {
        freeformType = yamlFormat.type;
        options = {
          base_url = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "GitHub API base URL (for GitHub Enterprise, override this)";
            example = "https://api.github.com";
          };
          organization = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "GitHub organization to look up release tags in";
          };
          concurrency = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = "Number of concurrent GitHub API requests";
          };
        };
      };

      githubType = types.submodule {
        freeformType = yamlFormat.type;
        options = {
          history_count = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = "Number of historical releases to fetch per repo";
          };
          api = mkOption {
            type = apiType;
            default = { };
            description = "GitHub API connection settings";
          };
          services = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = ''
              Kubernetes service name to GitHub repo mappings, in
              `service=repo_name` format.
            '';
            example = [ "service-1=repo_name_github" ];
          };
        };
      };

      kubernetesType = types.submodule {
        freeformType = yamlFormat.type;
        options = {
          service = mkOption {
            type = types.submodule {
              freeformType = yamlFormat.type;
              options = {
                selector = mkOption {
                  type = types.listOf (types.attrsOf (types.listOf types.str));
                  default = [ ];
                  description = ''
                    Label selectors used to match Kubernetes Deployments,
                    equivalent to `kubectl get deployments -l key=value`.
                  '';
                  example = [ { role = [ "stable" ]; } ];
                };
              };
            };
            default = { };
            description = "Kubernetes Deployment discovery settings";
          };
        };
      };

      settingsType = types.submodule {
        freeformType = yamlFormat.type;
        options = {
          github = mkOption {
            type = githubType;
            default = { };
            description = "GitHub release lookup configuration";
          };
          kubernetes = mkOption {
            type = kubernetesType;
            default = { };
            description = "Kubernetes deployment discovery configuration";
          };
        };
      };

      configFile = yamlFormat.generate "drift-detector-config.yaml" cfg.settings;
    in
    {
      options.programs.drift-detector = {
        enable = mkEnableOption "drift-detector CLI configuration";

        package = mkOption {
          type = types.nullOr types.package;
          default = pkgs.callPackage ./drift-detector.pkg.nix { };
          defaultText = literalExpression "pkgs.callPackage ./drift-detector.pkg.nix { }";
          description = ''
            drift-detector package to install. Set to `null` to manage the
            binary yourself while still letting this module write config.yaml.
            Override with a wrapper script if you need to inject
            `GITHUB_TOKEN` at invocation time (e.g. from `pass`).
          '';
        };

        settings = mkOption {
          type = settingsType;
          default = { };
          description = ''
            Configuration written to
            {file}`$XDG_CONFIG_HOME/drift-detector/config.yaml`
            (drift-detector's default `--config` lookup path).

            Known fields (`github.*`, `kubernetes.service.selector`) are
            typed for validation, but any additional upstream field is
            accepted as freeform YAML.

            See <https://github.com/yellowstonesoftware/drift-detector> for
            the full config reference.
          '';
          example = literalExpression ''
            {
              github = {
                history_count = 30;
                api.organization = "Myorg";
                services = [ "service-1=repo_name_github" ];
              };
              kubernetes.service.selector = [ { role = [ "stable" ]; } ];
            }
          '';
        };
      };

      config = mkIf cfg.enable {
        home.packages = mkIf (cfg.package != null) [ cfg.package ];

        xdg.configFile."drift-detector/config.yaml".source = configFile;
      };
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.drift-detector = pkgs.callPackage ./drift-detector.pkg.nix { };
    };
}
