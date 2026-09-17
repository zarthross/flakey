# Plain home-manager module (no flake `inputs` needed) exposing
# `flakey.programs.doom`, for use by any consumer flake wiring up
# nix-doom-emacs-unstraightened.
#
# Exposes `flakey.programs.doom`:
#   - `init`    : `doom!` module declarations, keyed by category then module
#                 name. Value per module is one of:
#                   - `false`             -> explicitly disabled
#                   - `true` / `{}`       -> enabled, no flags
#                   - `{ flags, cond }`   -> enabled with `+flag`s and/or a
#                                            `(:if COND mod flags...)` condition
#                 Multiple sources may set the same `<cat>.<mod>` path as
#                 long as they agree (after normalizing `true`/`{}`);
#                 disagreeing definitions are a hard build-time error, same
#                 as ordinary non-mergeable NixOS/home-manager options.
#   - `config`  : recursive doomDir file tree. Every attrset is a namespace
#                 node (its keys become path segments); a reserved
#                 `includes` key at any level is a list of directory paths
#                 whose contents are walked and spliced flat at that level.
#                 A terminal (non-attrset) leaf value is one of:
#                   - a string   -> written verbatim as the file's content
#                   - a function -> called with whichever of
#                                   `{ config, lib, pkgs }` it asks for;
#                                   the result is used as the file's content
#                   - a directory path -> walked recursively, same as
#                                   `includes`
#                   - a `.nix` file path -> imported and treated like a
#                                   function leaf. NOTE: the output keeps
#                                   the exact target name already
#                                   established at that point (the
#                                   attrset key for an explicit leaf, or
#                                   the discovered relative path -- `.nix`
#                                   extension included -- for a directory
#                                   walk). There is no automatic
#                                   `.nix` -> `.el` renaming; give a
#                                   `.nix`-generated leaf an explicit key
#                                   ending in the real target extension
#                                   (e.g. `"foo.el" = ./foo.nix;`) if you
#                                   want control over its name.
#                   - any other file path -> copied verbatim
#                 Two leaves resolving to the same final relpath are only
#                 allowed if both are plain text with identical content;
#                 anything else (including two function/`.nix` leaves,
#                 even if they'd happen to produce identical output) is a
#                 hard build-time error naming the conflicting sources.
#   - `doomDir` (read-only) : `config` fully expanded into a derivation,
#                 with `init.el` generated from `init` spliced in at the
#                 root. Setting `init` and `config."init.el"` at the same
#                 time is a hard build-time error; otherwise `init.el`
#                 comes from whichever one is set.
#
# When `init` or `config` is actually used, this module also sets
# `programs.doom-emacs.doomDir` to the generated `doomDir` (via
# `lib.mkDefault`, so an explicit `programs.doom-emacs.doomDir` assignment
# elsewhere still wins). Assumes the nix-doom-emacs-unstraightened
# home-manager module is imported wherever this is used.
{
  flake.modules.homeManager.doom-init =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.flakey.programs.doom;

      # Args available to `config` function/`.nix` leaves, filtered down to
      # whatever each individual leaf actually asks for (same idiom as
      # `pkgs.callPackage`).
      leafArgs = {
        inherit config lib pkgs;
      };
      callLeaf = f: f (builtins.intersectAttrs (builtins.functionArgs f) leafArgs);

      ##############################################################################
      # `init` (doom! module declarations) - unchanged from before.
      ##############################################################################

      normalizeModuleDef =
        value:
        if builtins.isBool value then
          {
            enable = value;
            flags = [ ];
            cond = null;
          }
        else
          {
            enable = true;
            flags = value.flags or [ ];
            cond = value.cond or null;
          };

      doomModuleDefType = lib.mkOptionType {
        name = "doomModuleDef";
        description = "doom! module definition: `false` to disable, `true`/`{}` to enable, or `{ flags, cond }`";
        descriptionClass = "noun";
        check =
          v:
          builtins.isBool v
          || (
            builtins.isAttrs v
            && lib.all (
              k:
              builtins.elem k [
                "flags"
                "cond"
              ]
            ) (builtins.attrNames v)
            && (!(v ? flags) || builtins.isList v.flags)
            && (!(v ? cond) || builtins.isString v.cond)
          );
        merge =
          loc: defs:
          let
            stripFile = d: {
              inherit (d) enable flags cond;
            };
            normed = map (d: normalizeModuleDef d.value // { inherit (d) file; }) defs;
            first = builtins.head normed;
            conflicting = builtins.filter (d: stripFile d != stripFile first) normed;
          in
          if conflicting == [ ] then
            stripFile first
          else
            throw ''
              The doom module definition at `${lib.showOption loc}` has conflicting definitions:
              ${lib.concatMapStringsSep "\n" (d: "  - ${d.file}: ${builtins.toJSON (stripFile d)}") normed}
            '';
      };

      renderModule =
        name: def:
        if !def.enable then
          null
        else if def.cond != null then
          "(:if ${def.cond} ${name}${
            lib.optionalString (def.flags != [ ]) " ${lib.concatStringsSep " " def.flags}"
          })"
        else if def.flags == [ ] then
          name
        else
          "(${name} ${lib.concatStringsSep " " def.flags})";

      renderCategory =
        cat: mods:
        let
          rendered = lib.filter (x: x != null) (lib.mapAttrsToList renderModule mods);
        in
        lib.optionalString (rendered != [ ]) (
          ":${cat}\n       " + lib.concatStringsSep "\n       " rendered
        );

      # Doom's own fixed, load-bearing category order (see doom!'s
      # documentation/module index). This matters for real: e.g. `:lang org`
      # extends `+ligatures-extra-symbols`, a variable `defvar`'d by `:ui
      # ligatures` -- if `:lang` were rendered before `:ui` (which plain
      # alphabetical attrset-key order would do, since "lang" < "ui"), Doom
      # fails at startup with a `void-variable` error. Any category not in
      # this list (e.g. a consumer's own custom category) is rendered after
      # all known ones, in attrset (alphabetical) order among themselves.
      categoryOrder = [
        "input"
        "completion"
        "ui"
        "editor"
        "emacs"
        "term"
        "checkers"
        "tools"
        "os"
        "lang"
        "email"
        "app"
        "config"
      ];

      orderedCategories =
        let
          present = builtins.attrNames cfg.init;
          known = lib.filter (c: builtins.elem c categoryOrder) categoryOrder;
          unknown = lib.filter (c: !(builtins.elem c categoryOrder)) present;
        in
        lib.filter (c: builtins.elem c present) known ++ unknown;

      # Rendered `init.el` text. Internal only (not a public option): nothing
      # outside this module needs raw init.el text, only the final `doomDir`
      # derivation.
      renderedInit = ''
        ;;; init.el -*- lexical-binding: t; -*-
        ;; Generated by flakey.programs.doom.init - do not edit by hand.

        (doom!
           ${
             lib.concatStringsSep "\n\n       " (
               lib.filter (s: s != "") (map (cat: renderCategory cat cfg.init.${cat}) orderedCategories)
             )
           })
      '';

      ##############################################################################
      # `config` (recursive doomDir file tree) - leaf-dispatch engine.
      ##############################################################################

      # Recursively list a directory's relative file paths (posix-style, no
      # leading slash), as plain strings only. Deliberately never turns an
      # individual leaf file into its own interpolated Nix path value: leaf
      # filenames can contain characters (e.g. `:`, as in a literal
      # `1:1-meeting.org`) that are invalid in a Nix store path name on their
      # own, even though they're fine nested inside an existing directory's
      # store path. See resolvePathLeaf's verbatim-copy case, which is the
      # only place this matters.
      listRelFiles =
        dir:
        let
          go =
            prefix: d:
            let
              entries = builtins.readDir d;
            in
            lib.concatMap (
              name:
              let
                path = d + "/${name}";
                relName = if prefix == "" then name else "${prefix}/${name}";
              in
              if entries.${name} == "directory" then go relName path else [ relName ]
            ) (builtins.attrNames entries);
        in
        go "" dir;

      # Resolve a path-typed leaf (from an explicit `config` leaf value, an
      # `includes` entry, or a file discovered while walking a directory) into
      # a flat list of entries. `targetPath` is the relpath this value should
      # land at in the final doomDir (for a directory, its *contents* land
      # under this as a prefix).
      resolvePathLeaf =
        targetPath: p:
        if builtins.readFileType (toString p) == "directory" then
          lib.concatMap (
            rel:
            # Strip trailing `.nix` from discovered names (e.g.
            # `config.el.nix` -> `config.el`); explicit attrset-key leaves
            # already name themselves and never go through this branch.
            let
              strippedRel = lib.removeSuffix ".nix" rel;
              childTarget = if targetPath == "" then strippedRel else "${targetPath}/${strippedRel}";
            in
            resolvePathLeaf childTarget (p + "/${rel}")
          ) (listRelFiles p)
        else if lib.hasSuffix ".nix" (toString p) then
          let
            imported = import p;
          in
          if builtins.isFunction imported then
            [
              {
                name = targetPath;
                text = callLeaf imported;
              }
            ]
          else
            throw "flakey.programs.doom.config: `${toString p}` must evaluate to a function"
        else
          # Verbatim copy. Deliberately keeps the source as (containing dir,
          # filename) rather than a single combined path value: interpolating
          # `p` itself into the eventual build script would ask Nix to mint a
          # NEW store path named after `p`'s own basename, which breaks for
          # filenames containing characters like `:`. Interpolating the
          # containing directory (whose own name is always safe/ordinary) once,
          # then appending the filename as plain shell text inside the builder,
          # avoids that entirely -- see doomDirDerivation below.
          [
            {
              name = targetPath;
              copySource = builtins.dirOf p;
              copyRel = builtins.baseNameOf p;
            }
          ];

      # Dispatch on a single `config` leaf/node value.
      resolveConfigValue =
        targetPath: value:
        if builtins.isString value then
          [
            {
              name = targetPath;
              text = value;
            }
          ]
        else if builtins.isFunction value then
          [
            {
              name = targetPath;
              text = callLeaf value;
            }
          ]
        else if builtins.isPath value then
          resolvePathLeaf targetPath value
        else if builtins.isAttrs value then
          resolveConfigNode targetPath value
        else
          throw "flakey.programs.doom.config: unsupported value at `${targetPath}` (${builtins.typeOf value})";

      # A namespace node: recurse into every child key (becoming a path
      # segment), and splice any `includes` directories in flat alongside them.
      resolveConfigNode =
        targetPath: node:
        let
          includeDirs = node.includes or [ ];
          children = builtins.removeAttrs node [ "includes" ];
          childEntries = lib.concatMap (
            key: resolveConfigValue (if targetPath == "" then key else "${targetPath}/${key}") children.${key}
          ) (builtins.attrNames children);
          includeEntries = lib.concatMap (dir: resolvePathLeaf targetPath dir) includeDirs;
        in
        childEntries ++ includeEntries;

      # `cfg.config` is a list of independently-authored tree fragments (one
      # per module definition; see the `config` option's type below for why
      # it's a dumb list rather than a module-system-merged attrset). Each
      # fragment is resolved on its own, then every fragment's entries are
      # flattened together and deduped by final path.
      fragmentEntries = lib.concatMap (resolveConfigNode "") cfg.config;

      # `init` and an explicit `config."init.el"` (in any fragment) are
      # mutually exclusive.
      initConflict = cfg.init != { } && lib.any (frag: frag ? "init.el") cfg.config;

      allEntries =
        if initConflict then
          throw ''
            flakey.programs.doom: both `init` and `config."init.el"` are set. `init.el` is generated from `init`; set only one of them.
          ''
        else if cfg.init != { } then
          fragmentEntries
          ++ [
            {
              name = "init.el";
              text = renderedInit;
            }
          ]
        else
          fragmentEntries;

      groupedEntries = lib.groupBy (e: e.name) allEntries;

      describeEntry = e: if e ? text then "generated text" else "${toString e.copySource}/${e.copyRel}";

      # Two entries at the same relpath are only OK if both are plain text
      # with identical content. Anything else -- including two function/`.nix`
      # leaves that happen to be `==`-unequal or unequal by construction (as
      # functions, they're never comparable) -- is a hard error.
      dedupedEntries = lib.mapAttrsToList (
        name: entries:
        if lib.length entries == 1 then
          builtins.head entries
        else if
          lib.all (e: e ? text) entries && lib.all (e: e.text == (builtins.head entries).text) entries
        then
          builtins.head entries
        else
          throw ''
            flakey.programs.doom.config: conflicting definitions for `${name}`:
            ${lib.concatMapStringsSep "\n" (e: "  - ${describeEntry e}") entries}
          ''
      ) groupedEntries;

      doomDirDerivation = pkgs.runCommand "doom-dir" { } (
        ''
          mkdir -p "$out"
        ''
        + lib.concatMapStringsSep "\n" (
          e:
          let
            # `"$out"` (double-quoted, so the shell variable actually expands)
            # concatenated directly against a single-quoted, shell-escaped
            # relpath -- adjacent quoted shell tokens with no separator between
            # them form one word, e.g. "$out"'/foo:bar.el'. Escaping the whole
            # thing at once with `lib.escapeShellArg "$out/${e.name}"` would
            # instead single-quote `$out` itself, which stops it from
            # expanding (this was a real bug: files silently landed nowhere).
            targetShell = ''"$out"'' + lib.escapeShellArg ("/" + e.name);
          in
          if e ? text then
            ''
              mkdir -p "$(dirname ${targetShell})"
              cp ${pkgs.writeText "doom-cfg-entry" e.text} ${targetShell}
            ''
          else
            let
              # `e.copySource` interpolates once, safely (its own name is
              # always an ordinary directory name); `e.copyRel` is appended as
              # plain text, never as a second Nix path interpolation. See
              # resolvePathLeaf's comment above for why this split matters.
              sourcePath = "${e.copySource}/${e.copyRel}";
            in
            ''
              mkdir -p "$(dirname ${targetShell})"
              cp -r ${lib.escapeShellArg sourcePath} ${targetShell}
            ''
        ) dedupedEntries
      );
    in
    {
      options.flakey.programs.doom = {
        init = lib.mkOption {
          type = lib.types.attrsOf (lib.types.attrsOf doomModuleDefType);
          default = { };
          description = "Doom `init.el` module declarations, keyed by category then module name.";
        };

        config = lib.mkOption {
          # Each module that sets this option contributes one whole attrset
          # ("fragment"); `cfg.config` ends up as a *list* of those fragments,
          # one per definition, rather than a single module-system-merged
          # attrset. Deliberately not `types.attrsOf types.anything`: nixpkgs's
          # `types.anything` has its own opinionated merge behavior for
          # function-valued leaves (it tries to compose/call them itself),
          # which stomps on function/`.nix` leaves before our own
          # `resolveConfigNode`/`callLeaf` ever sees them (breaks
          # `builtins.functionArgs`-based arg injection). This custom type's
          # `merge` just collects each definition's raw value untouched;
          # `fragmentEntries` above resolves every fragment independently and
          # dedupes across all of them by final path, so cross-source
          # composition still works, it just isn't implemented via the option
          # system's own merge.
          type = lib.mkOptionType {
            name = "doomConfigFragmentList";
            description = "doomDir file tree fragment";
            check = builtins.isAttrs;
            merge = _loc: defs: map (d: d.value) defs;
          };
          default = [ ];
          description = ''
            Recursive doomDir file tree. Every attrset is a namespace node
            (its keys become path segments); a reserved `includes` key at any
            level is a list of directory paths whose contents are walked and
            spliced flat at that level. See this file's header comment for
            the full leaf-dispatch rules.

            Each definition (i.e. each module that sets this option) is kept
            as its own independent fragment rather than deep-merged with
            others: assign one whole tree per module, e.g.
            `flakey.programs.doom.config = { "packages.el" = "..."; };`.
          '';
        };

        doomDir = lib.mkOption {
          type = lib.types.path;
          readOnly = true;
          default = doomDirDerivation;
          description = "The merged doomDir derivation, built from `config` (with `init.el` generated from `init` spliced in).";
        };
      };

      config = lib.mkIf (cfg.init != { } || cfg.config != { }) {
        programs.doom-emacs.doomDir = lib.mkDefault cfg.doomDir;
      };
    };
}
