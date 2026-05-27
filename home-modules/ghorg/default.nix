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

  # Helper to build ghorg clone commands from structured options
  mkGhorgCmd =
    {
      target,
      cloneType ? "org",
      scmType ? null,
      token ? null,
      matchRegex ? null,
      excludeMatchRegex ? null,
      matchPrefix ? null,
      excludeMatchPrefix ? null,
      outputDir ? null,
      topics ? null,
      language ? null,
      skipArchived ? null,
      skipForks ? null,
      preserveDir ? null,
      baseUrl ? null,
      protocol ? null,
      branch ? null,
      extraArgs ? "",
    }:
    let
      cloneTypeArg = optionalString (cloneType != "org") "--clone-type=${cloneType}";
      scmTypeArg = optionalString (scmType != null) "--scm=${scmType}";
      tokenArg = optionalString (token != null) "--token=${token}";
      matchRegexArg = optionalString (matchRegex != null) "--match-regex='${matchRegex}'";
      excludeMatchRegexArg = optionalString (
        excludeMatchRegex != null
      ) "--exclude-match-regex='${excludeMatchRegex}'";
      matchPrefixArg = optionalString (matchPrefix != null) "--match-prefix='${matchPrefix}'";
      excludeMatchPrefixArg = optionalString (
        excludeMatchPrefix != null
      ) "--exclude-match-prefix='${excludeMatchPrefix}'";
      outputDirArg = optionalString (outputDir != null) "--output-dir=${outputDir}";
      topicsArg = optionalString (topics != null) "--topics=${topics}";
      languageArg = optionalString (language != null) "--github-filter-language=${language}";
      skipArchivedArg = optionalString (skipArchived == true) "--skip-archived";
      skipForksArg = optionalString (skipForks == true) "--skip-forks";
      preserveDirArg = optionalString (preserveDir == true) "--preserve-dir";
      baseUrlArg = optionalString (baseUrl != null) "--base-url=${baseUrl}";
      protocolArg = optionalString (protocol != null) "--protocol=${protocol}";
      branchArg = optionalString (branch != null) "--branch=${branch}";

      allArgs = concatStringsSep " " (
        filter (s: s != "") [
          cloneTypeArg
          scmTypeArg
          tokenArg
          matchRegexArg
          excludeMatchRegexArg
          matchPrefixArg
          excludeMatchPrefixArg
          topicsArg
          languageArg
          skipArchivedArg
          skipForksArg
          preserveDirArg
          baseUrlArg
          protocolArg
          branchArg
          outputDirArg
          extraArgs
        ]
      );
    in
    if allArgs == "" then "ghorg clone ${target}" else "ghorg clone ${target} ${allArgs}";

  # Reclone entry type
  recloneEntryType = types.submodule {
    options = {
      target = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "GitHub org or user to clone";
      };

      cloneType = mkOption {
        type = types.enum [
          "org"
          "user"
        ];
        default = "org";
        description = "Clone type: org or user";
      };

      scmType = mkOption {
        type = types.nullOr (
          types.enum [
            "github"
            "gitlab"
            "bitbucket"
            "gitea"
            "sourcehut"
          ]
        );
        default = null;
        description = "SCM provider type (defaults to github)";
      };

      token = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "API token or path to token file";
      };

      matchRegex = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Regex to match repository names";
      };

      excludeMatchRegex = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Regex to exclude repository names";
      };

      matchPrefix = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Prefix to match repository names";
      };

      excludeMatchPrefix = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Prefix to exclude repository names";
      };

      outputDir = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Output directory name";
      };

      topics = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Filter by topics";
      };

      language = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Filter by programming language";
      };

      skipArchived = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Skip archived repositories";
      };

      skipForks = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Skip forked repositories";
      };

      preserveDir = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Preserve directory structure";
      };

      baseUrl = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Base URL for self-hosted instances";
      };

      protocol = mkOption {
        type = types.nullOr (
          types.enum [
            "https"
            "ssh"
          ]
        );
        default = null;
        description = "Clone protocol";
      };

      branch = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Branch to clone";
      };

      extraArgs = mkOption {
        type = types.str;
        default = "";
        description = "Additional arguments to pass to ghorg";
      };

      cmd = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Raw ghorg clone command. If set, this overrides all structured options above.
          Use this for advanced cases not covered by structured options.
        '';
      };

      description = mkOption {
        type = types.str;
        default = "";
        description = "Description shown in reclone --list output";
      };

      postExecScript = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = ''
          Path to script executed after clone completes.
          Receives two arguments: status (success/fail) and entry name.
        '';
      };
    };
  };

  # Convert reclone entries to YAML format
  recloneToYaml = mapAttrs (
    name: entry:
    let
      cmdString =
        if entry.cmd != null then
          entry.cmd
        else if entry.target != null then
          mkGhorgCmd {
            inherit (entry)
              target
              cloneType
              scmType
              token
              matchRegex
              excludeMatchRegex
              matchPrefix
              excludeMatchPrefix
              outputDir
              topics
              language
              skipArchived
              skipForks
              preserveDir
              baseUrl
              protocol
              branch
              extraArgs
              ;
          }
        else
          throw "Reclone entry '${name}' must have either 'target' or 'cmd' set";

      baseEntry = {
        cmd = cmdString;
      };
      withDescription =
        if entry.description != "" then baseEntry // { description = entry.description; } else baseEntry;
      withPostExec =
        if entry.postExecScript != null then
          withDescription // { post_exec_script = toString entry.postExecScript; }
        else
          withDescription;
    in
    withPostExec
  );

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
      (pkgs.formats.yaml { }).generate "ghorg_reclone.yaml" (recloneToYaml cfg.reclone);
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
        type = types.attrsOf recloneEntryType;
        default = { };
        defaultText = literalExpression "{ }";
        example = literalExpression ''
          {
            nix-community = {
              target = "nix-community";
              description = "Clone all nix-community repos";
            };
            
            juhaku-utoipa = {
              target = "juhaku";
              cloneType = "user";
              matchRegex = "utoipa";
              description = "Clone utoipa repos from juhaku user";
            };
            
            custom-command = {
              cmd = "ghorg clone myorg --custom-flag";
              description = "Use raw command for advanced cases";
            };
          }
        '';
        description = lib.mdDoc ''
          Structured configuration for ghorg/reclone.yaml.

          Each entry can either use structured options (target, cloneType, etc.)
          which will auto-generate the ghorg command, or provide a raw `cmd`
          for advanced use cases.
        '';
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
