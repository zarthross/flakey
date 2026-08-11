# ECA (Editor Code Assistant) Configuration Module
#
# Manages ECA configuration via home-manager
# Supports global (~/.config/eca/config.json) and local (.eca/config.json) configs
{
  flake.modules.homeManager.eca =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    with lib;
    let
      cfg = config.dgibs.programs.eca;

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

      # A `{ path = ...; }` entry matching ECA's raw rules/skills schema
      # exactly (additionalProperties: false upstream). `path` accepts a nix
      # path literal (coerced to its store path string), a plain string
      # (workspace-relative, absolute, or built from a flake input, e.g.
      # "${inputs.shared}/skills/foo"), or an already-resolved string.
      rawPathEntryType = types.submodule {
        options.path = mkOption {
          type = types.coercedTo types.path toString types.str;
          description = "Path to a file or directory (relative to workspace root or absolute; ~ supported). Nix path literals are coerced to their store path.";
        };
      };

      # `types.either` can't discriminate between two submodules (its check
      # only verifies "is an attrset", so a definition always merges against
      # the first branch regardless of shape). This type dispatches on the
      # presence of a `path` key instead, merging against `pathType` when
      # present and `contentType` otherwise.
      pathOrContentType =
        pathType: contentType:
        mkOptionType {
          name = "pathOrContent";
          description = "${pathType.description} or ${contentType.description}, matched on the presence of a `path` attribute";
          check = builtins.isAttrs;
          merge =
            loc: defs:
            let
              target = if (builtins.head defs).value ? path then pathType else contentType;
            in
            target.merge loc defs;
        };

      # Inline skill content, following the Agent Skills spec
      # (https://agentskills.io/specification). Rendered to a
      # `<name>/SKILL.md` file in the nix store.
      skillContentType = types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "Skill name (1-64 chars, lowercase alphanumeric and hyphens only). Used as the generated skill directory name; must be unique.";
          };
          description = mkOption {
            type = types.str;
            description = "What the skill does and when to use it (max 1024 characters per spec).";
          };
          content = mkOption {
            type = types.lines;
            description = "Markdown body of the skill (everything after the frontmatter).";
          };
          license = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "License name or reference to a bundled license file.";
          };
          compatibility = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Environment requirements (intended product, system packages, network access, etc.).";
          };
          metadata = mkOption {
            type = types.nullOr (types.attrsOf types.str);
            default = null;
            description = "Arbitrary string key-value metadata not defined by the Agent Skills spec.";
          };
          "allowed-tools" = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Space-separated string of tools pre-approved to run for this skill (experimental).";
          };
        };
      };

      # Inline rule content. ECA rules have no frontmatter, just markdown.
      # Rendered to a `<name-or-hash>.md` file in the nix store.
      ruleContentType = types.submodule {
        options = {
          name = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Optional file name (without extension) for the rendered rule file. Derived from a content hash when omitted.";
          };
          content = mkOption {
            type = types.lines;
            description = "Markdown content of the rule.";
          };
        };
      };

      # Renders YAML frontmatter with a fixed key order, skipping keys whose
      # value is null. `fields` values are JSON-encoded, which is also valid
      # YAML for the scalar/string/list values SKILL.md frontmatter uses.
      renderFrontmatter =
        order: fields:
        let
          yamlValue =
            v:
            if builtins.isAttrs v then
              "\n" + lib.concatMapStringsSep "\n" (k: "  ${k}: ${builtins.toJSON v.${k}}") (builtins.attrNames v)
            else
              builtins.toJSON v;
          renderKey = k: "${k}: ${yamlValue fields.${k}}";
          presentKeys = builtins.filter (k: (fields.${k} or null) != null) order;
        in
        "---\n" + lib.concatMapStringsSep "\n" renderKey presentKeys + "\n---\n";

      # Renders an inline skillContentType entry to a nix store directory
      # named after the skill, containing a spec-compliant SKILL.md.
      renderSkill =
        skill:
        let
          frontmatter = renderFrontmatter [
            "name"
            "description"
            "license"
            "compatibility"
            "metadata"
            "allowed-tools"
          ] skill;
          skillMdFile = pkgs.writeText "SKILL.md" (frontmatter + "\n" + skill.content);
        in
        pkgs.runCommand "eca-skill-${skill.name}" { } ''
          mkdir -p $out/${skill.name}
          cp ${skillMdFile} $out/${skill.name}/SKILL.md
        '';

      # Renders an inline ruleContentType entry to a nix store markdown file.
      renderRule =
        rule:
        let
          fileBaseName = if rule.name != null then rule.name else builtins.hashString "sha256" rule.content;
        in
        pkgs.writeText "eca-rule-${fileBaseName}.md" rule.content;

      # Both rules and skills entries are either `{ path = ...; }` (passed
      # through unchanged) or inline content (rendered to a store path).
      isPathEntry = entry: entry ? path;

      resolveSkillEntry =
        entry:
        if isPathEntry entry then
          { path = entry.path; }
        else
          { path = "${renderSkill entry}/${entry.name}"; };

      resolveRuleEntry =
        entry: if isPathEntry entry then { path = entry.path; } else { path = "${renderRule entry}"; };

      # Add schema to final config, resolve inline rules/skills to plain
      # `{ path = ...; }` entries, and filter out null values recursively.
      finalConfig = lib.filterAttrsRecursive (_: v: v != null) (
        cfg.settings
        // {
          "$schema" = schemaUrl;
          rules = map resolveRuleEntry cfg.settings.rules;
          skills = map resolveSkillEntry cfg.settings.skills;
        }
      );
    in
    {
      options.dgibs.programs.eca = {
        enable = mkEnableOption "ECA (Editor Code Assistant) configuration";

        package = mkOption {
          type = types.nullOr types.package;
          default = pkgs.callPackage ./eca.pkg.nix { };
          defaultText = literalExpression "pkgs.callPackage ./eca.pkg.nix { }";
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
                type = types.listOf (pathOrContentType rawPathEntryType ruleContentType);
                default = [ ];
                description = "Rule contexts for LLM prompts. Each entry is either `{ path = ...; }` pointing at an existing rule file/directory, or inline `{ content = ...; }` markdown rendered to a store file.";
                example = literalExpression ''
                  [
                    { path = ./rules/my-rule.md; }
                    { path = "${inputs.shared-agent-config}/rules/team-rule.md"; }
                    { content = "Always write tests before implementation."; }
                  ]
                '';
              };

              commands = mkOption {
                type = types.listOf jsonFormat.type;
                default = [ ];
                description = "Custom command prompt files";
              };

              skills = mkOption {
                type = types.listOf (pathOrContentType rawPathEntryType skillContentType);
                default = [ ];
                description = "Skill files or directories to load. Each entry is either `{ path = ...; }` pointing at an existing skill file/directory, or an inline skill attrset (`name`, `description`, `content`, plus optional Agent Skills spec fields) rendered to a `SKILL.md` in the store.";
                example = literalExpression ''
                  [
                    { path = ./skills/my-skill; }
                    { path = "${inputs.shared-agent-config}/skills/team-skill"; }
                    {
                      name = "commit-messages";
                      description = "Writes conventional-commit style messages. Use when drafting a git commit.";
                      content = "# Commit Messages\n\nUse the conventional commits format: `type(scope): summary`.";
                    }
                  ]
                '';
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
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.eca-bin = pkgs.callPackage ./eca.pkg.nix { };
    };
}
