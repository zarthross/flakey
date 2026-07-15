# ECA (Editor Code Assistant) Configuration Module
#
# Manages ECA configuration via home-manager
# Supports global (~/.config/eca/config.json) and local (.eca/config.json) configs
{ localFlake }:
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.dgibs.programs.eca;
  packages' = localFlake.packages.${pkgs.stdenv.hostPlatform.system};

  # JSON schema URL
  schemaUrl = "https://eca.dev/config.json";

  # JSON format for ECA config
  # Note: pkgs.formats.json uses jq for pretty-printing (no indent param needed)
  jsonFormat = pkgs.formats.json { };

  # Approval matcher type - used for allow/ask/deny tool rules
  approvalMatcherType = types.submodule {
    freeformType = jsonFormat.type;
    options = {
      argsMatchers = mkOption {
        type = types.nullOr (types.attrsOf (types.listOf types.str));
        default = null;
        description = "Map of argument name to list of Java regex patterns to match against. If null/omitted, matches all invocations of the tool.";
        example = literalExpression ''
          {
            command = ["pwd" "git\\s+diff(\\s+.*)?"];
            path = ["/home/.*" "/tmp/.*"];
          }
        '';
      };
    };
  };

  # Add schema to final config and filter out null values recursively
  finalConfig = lib.filterAttrsRecursive (_: v: v != null) (
    cfg.settings
    // {
      "$schema" = schemaUrl;
    }
  );
in
{
  options.dgibs.programs.eca = {
    enable = mkEnableOption "ECA (Editor Code Assistant) configuration";

    package = mkOption {
      type = types.nullOr types.package;
      default = packages'.eca-bin;
      defaultText = literalExpression "localFlake.packages.\${pkgs.stdenv.hostPlatform.system}.eca-bin";
      description = "ECA package to install. Set to `null` to manage the binary yourself.";
    };

    settings = mkOption {
      description = "ECA configuration settings";
      default = { };
      type = types.submodule {
        freeformType = jsonFormat.type;
        options = {
          providers = mkOption {
            type = jsonFormat.type;
            default = { };
            description = "LLM provider configurations";
            example = literalExpression ''
              {
                openai = {
                  api = "openai-responses";
                  url = "https://api.openai.com";
                  key = "\${"env:OPENAI_API_KEY"}";
                  models.gpt-5 = {};
                };
              }
            '';
          };

          agent = mkOption {
            type = jsonFormat.type;
            default = { };
            description = "Named agent configurations";
            example = literalExpression ''
              {
                code = {
                  mode = "primary";
                  disabledTools = ["preview_file_change"];
                };
              }
            '';
          };

          mcpServers = mkOption {
            type = jsonFormat.type;
            default = { };
            description = "MCP server configurations";
            example = literalExpression ''
              {
                filesystem = {
                  command = "npx";
                  args = ["-y" "@modelcontextprotocol/server-filesystem" "/home/user"];
                };
              }
            '';
          };

          defaultModel = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Default model in format 'provider/model'";
            example = "openai/gpt-5.2";
          };

          defaultAgent = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Default agent for new chats";
            example = "code";
          };

          toolCall = mkOption {
            type = types.submodule {
              freeformType = jsonFormat.type;
              options = {
                approval = mkOption {
                  type = types.submodule {
                    freeformType = jsonFormat.type;
                    options = {
                      byDefault = mkOption {
                        type = types.enum [
                          "ask"
                          "allow"
                          "deny"
                        ];
                        default = "ask";
                        description = "Default approval mode for tools not explicitly configured";
                      };
                      allow = mkOption {
                        type = types.attrsOf approvalMatcherType;
                        default = { };
                        description = "Tools that are automatically allowed. Key is tool or server name.";
                        example = literalExpression ''
                          {
                            eca__read_file = {};
                            eca__shell_command = {
                              argsMatchers.command = ["pwd" "ls(\\s+.*)?"];
                            };
                          }
                        '';
                      };
                      ask = mkOption {
                        type = types.attrsOf approvalMatcherType;
                        default = { };
                        description = "Tools that require user approval. Key is tool or server name.";
                      };
                      deny = mkOption {
                        type = types.attrsOf approvalMatcherType;
                        default = { };
                        description = "Tools that are denied. Key is tool or server name.";
                        example = literalExpression ''
                          {
                            eca__shell_command = {
                              argsMatchers.command = [".*rm\\s+-rf.*" ".*>.*"];
                            };
                          }
                        '';
                      };
                    };
                  };
                  default = { };
                  description = "Tool approval configuration";
                };
              };
            };
            default = { };
            description = "Tool call configuration including approval rules";
            example = literalExpression ''
              {
                approval = {
                  byDefault = "ask";
                  allow = {
                    eca__read_file = {};
                    eca__grep = {};
                  };
                };
              }
            '';
          };

          prompts = mkOption {
            type = jsonFormat.type;
            default = { };
            description = "Custom prompt configurations";
          };

          rules = mkOption {
            type = types.listOf jsonFormat.type;
            default = [ ];
            description = "Rule contexts for LLM prompts";
          };

          commands = mkOption {
            type = types.listOf jsonFormat.type;
            default = [ ];
            description = "Custom command prompt files";
          };

          skills = mkOption {
            type = types.listOf jsonFormat.type;
            default = [ ];
            description = "Skill files or directories";
          };

          disabledTools = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Tools to disable globally";
          };

          hooks = mkOption {
            type = jsonFormat.type;
            default = { };
            description = "Shell actions on events";
          };

          customTools = mkOption {
            type = jsonFormat.type;
            default = { };
            description = "User-defined command-line tools";
          };

          completion = mkOption {
            type = jsonFormat.type;
            default = { };
            description = "Inline completion configuration";
          };

          rewrite = mkOption {
            type = jsonFormat.type;
            default = { };
            description = "Rewrite feature configuration";
          };

          chat = mkOption {
            type = jsonFormat.type;
            default = { };
            description = "Chat feature settings";
          };

          index = mkOption {
            type = jsonFormat.type;
            default = { };
            description = "Workspace indexing configuration";
          };

          remote = mkOption {
            type = jsonFormat.type;
            default = { };
            description = "Remote web control server configuration";
          };

          network = mkOption {
            type = jsonFormat.type;
            default = { };
            description = "Network configuration for CA certs and mTLS";
          };

          plugins = mkOption {
            type = jsonFormat.type;
            default = { };
            description = "Plugin system configuration";
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # Install global config at ~/.config/eca/config.json
    home.file.".config/eca/config.json" = {
      source = jsonFormat.generate "eca-config.json" finalConfig;
    };

    # Install package if specified
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
  };
}
