# Flakey

[![CI](https://github.com/zarthross/flakey/actions/workflows/ci.yaml/badge.svg)](https://github.com/zarthross/flakey/actions/workflows/ci.yaml)
[![Update Sources](https://github.com/zarthross/flakey/actions/workflows/update-sources.yaml/badge.svg)](https://github.com/zarthross/flakey/actions/workflows/update-sources.yaml)

## Provides

`nix flake show --all-systems`

```
├───actions-nix: unknown
├───checks
│   ├───aarch64-darwin
│   │   ├───check-flake-file: derivation 'check-flake-file'
│   │   ├───package-bitwarden: derivation 'Bitwarden-2026.8.0'
│   │   ├───package-drift-detector: derivation 'drift-detector-v0.0.7'
│   │   ├───package-eca-bin: derivation 'eca-bin-0.158.1'
│   │   ├───package-hot: derivation 'Hot-1.9.4'
│   │   ├───package-keepingYouAwake: derivation 'KeepingYouAwake-1.6.8'
│   │   ├───package-rectangle: derivation 'Rectangle-1.100'
│   │   ├───package-render-workflows: derivation 'render-workflows'
│   │   ├───package-write-flake: derivation 'write-flake'
│   │   ├───package-write-inputs: derivation 'write-inputs'
│   │   ├───package-write-lock: derivation 'write-lock'
│   │   ├───pre-commit: derivation 'pre-commit-run'
│   │   └───treefmt: derivation 'treefmt-check'
│   ├───aarch64-linux
│   │   ├───check-flake-file: derivation 'check-flake-file'
│   │   ├───package-drift-detector: derivation 'drift-detector-v0.0.7'
│   │   ├───package-eca-bin: derivation 'eca-bin-0.158.1'
│   │   ├───package-render-workflows: derivation 'render-workflows'
│   │   ├───package-write-flake: derivation 'write-flake'
│   │   ├───package-write-inputs: derivation 'write-inputs'
│   │   ├───package-write-lock: derivation 'write-lock'
│   │   ├───pre-commit: derivation 'pre-commit-run'
│   │   └───treefmt: derivation 'treefmt-check'
│   ├───x86_64-darwin
│   │   ├───check-flake-file: derivation 'check-flake-file'
│   │   ├───package-bitwarden: derivation 'Bitwarden-2026.8.0'
│   │   ├───package-drift-detector: derivation 'drift-detector-v0.0.7'
│   │   ├───package-eca-bin: derivation 'eca-bin-0.158.1'
│   │   ├───package-hot: derivation 'Hot-1.9.4'
│   │   ├───package-keepingYouAwake: derivation 'KeepingYouAwake-1.6.8'
│   │   ├───package-rectangle: derivation 'Rectangle-1.100'
│   │   ├───package-render-workflows: derivation 'render-workflows'
│   │   ├───package-write-flake: derivation 'write-flake'
│   │   ├───package-write-inputs: derivation 'write-inputs'
│   │   ├───package-write-lock: derivation 'write-lock'
│   │   ├───pre-commit: derivation 'pre-commit-run'
│   │   └───treefmt: derivation 'treefmt-check'
│   └───x86_64-linux
│       ├───check-flake-file: derivation 'check-flake-file'
│       ├───package-drift-detector: derivation 'drift-detector-v0.0.7'
│       ├───package-eca-bin: derivation 'eca-bin-0.158.1'
│       ├───package-render-workflows: derivation 'render-workflows'
│       ├───package-write-flake: derivation 'write-flake'
│       ├───package-write-inputs: derivation 'write-inputs'
│       ├───package-write-lock: derivation 'write-lock'
│       ├───pre-commit: derivation 'pre-commit-run'
│       └───treefmt: derivation 'treefmt-check'
├───darwinModules: unknown
├───devShells
│   ├───aarch64-darwin
│   │   └───default: development environment 'devshell'
│   ├───aarch64-linux
│   │   └───default: development environment 'devshell'
│   ├───x86_64-darwin
│   │   └───default: development environment 'devshell'
│   └───x86_64-linux
│       └───default: development environment 'devshell'
├───formatter
│   ├───aarch64-darwin: package 'treefmt'
│   ├───aarch64-linux: package 'treefmt'
│   ├───x86_64-darwin: package 'treefmt'
│   └───x86_64-linux: package 'treefmt'
├───homeModules: unknown
├───modules: unknown
├───nixosModules
│   ├───allow-unfree-predicates: NixOS module
│   ├───default: NixOS module
│   ├───nix-change-report: NixOS module
│   └───nixos-change-report: NixOS module
├───overlays
│   └───default: Nixpkgs overlay
└───packages
    ├───aarch64-darwin
    │   ├───bitwarden: package 'Bitwarden-2026.8.0'
    │   ├───drift-detector: package 'drift-detector-v0.0.7'
    │   ├───eca-bin: package 'eca-bin-0.158.1'
    │   ├───hot: package 'Hot-1.9.4'
    │   ├───keepingYouAwake: package 'KeepingYouAwake-1.6.8'
    │   ├───rectangle: package 'Rectangle-1.100'
    │   ├───render-workflows: package 'render-workflows'
    │   ├───write-flake: package 'write-flake'
    │   ├───write-inputs: package 'write-inputs'
    │   └───write-lock: package 'write-lock'
    ├───aarch64-linux
    │   ├───drift-detector: package 'drift-detector-v0.0.7'
    │   ├───eca-bin: package 'eca-bin-0.158.1'
    │   ├───render-workflows: package 'render-workflows'
    │   ├───write-flake: package 'write-flake'
    │   ├───write-inputs: package 'write-inputs'
    │   └───write-lock: package 'write-lock'
    ├───x86_64-darwin
    │   ├───bitwarden: package 'Bitwarden-2026.8.0'
    │   ├───drift-detector: package 'drift-detector-v0.0.7'
    │   ├───eca-bin: package 'eca-bin-0.158.1'
    │   ├───hot: package 'Hot-1.9.4'
    │   ├───keepingYouAwake: package 'KeepingYouAwake-1.6.8'
    │   ├───rectangle: package 'Rectangle-1.100'
    │   ├───render-workflows: package 'render-workflows'
    │   ├───write-flake: package 'write-flake'
    │   ├───write-inputs: package 'write-inputs'
    │   └───write-lock: package 'write-lock'
    └───x86_64-linux
        ├───drift-detector: package 'drift-detector-v0.0.7'
        ├───eca-bin: package 'eca-bin-0.158.1'
        ├───render-workflows: package 'render-workflows'
        ├───write-flake: package 'write-flake'
        ├───write-inputs: package 'write-inputs'
        └───write-lock: package 'write-lock'
```

`homeModules`, `darwinModules`, and `modules` show as `unknown` because they're
plain attrsets of module functions rather than a type `nix flake show`
recognizes — see the sections below for what's actually in them.

### Option Namespacing

Every custom option this flake defines for home-manager (or nix-darwin/NixOS)
lives under a `flakey.` prefix (e.g. `flakey.programs.eca`), never a bare
`programs.*`/`services.*`/`system.*` path. Those top-level namespaces belong
to real home-manager/nix-darwin/NixOS, and declaring an option directly under
one risks a hard conflict if upstream later ships an option with the exact
same name — see [Removed: omniwm](#removed-omniwm) below for a case where
that actually happened.

A couple of modules predate this convention and used a bare `programs.*`
path (`ghorg`, `drift-detector`) or a different custom prefix
(`dgibs.programs.eca`). Those old paths still work today via
`lib.mkRenamedOptionModuleWith` deprecation aliases (you'll get a warning
pointing at the new `flakey.programs.*` path), but new configs should use
the `flakey.programs.*` form directly.

## nixosModules
### allow-unfree-predicates

With this modules, instead of:

```
nixpkgs.config.allowUnfree = true;  # EVERYTHING IS ALLOWED;
```

or

```
# You CANNOT set this in multiple places since its a function...
nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "roon-server"
    "vscode"
  ];
```

now you can write:

```
# Its just a list of package regexes you want to allow.
# you can set this in multiple modules and it just adds more regexes!!!
nixpkgs.allowUnfreeRegexes = ["slack" "discord"];
```

### nix-change-report

Automatically adds a change report using `nvd` to each nixos activation.

## homeModules
### allow-unfree-predicates
[See](#allow-unfree-predicates)

### nix-change-report

Automatically adds a change report using `nvd` to each home-manager activation.

```
❯ home-manager switch
Starting Home Manager activation
Activating checkFilesChanged
Activating checkLinkTargets
Activating writeBoundary
Activating createGpgHomedir
Activating nix-change-report
<<< /home/my-home/.local/state/nix/profiles/home-manager
>>> /nix/store/w4vgy6jalyh1vc1ghgas13hpxb7qsgz0-home-manager-generation
Removed packages:
[R.]  #1  ponysay-unstable  2021-03-27
Closure size: 1392 -> 1391 (4 paths added, 5 paths removed, delta -1, disk usage -10.8MiB).
Activating installPackages
replacing old 'home-manager-path'
installing 'home-manager-path'
Activating migrateGhAccounts
Activating linkGeneration
Cleaning up orphan links from /home/my-home
Creating profile generation 567
Creating home file links in /home/my-home
Activating onFilesChange
Activating reloadSystemd
```

### ghorg

Structured home-manager config for [ghorg](https://github.com/gabrie30/ghorg)
(bulk-clones GitHub/GitLab/Bitbucket/Gitea/sourcehut orgs and users). Options
live under `flakey.programs.ghorg` (see [Option Namespacing](#option-namespacing)):

```nix
flakey.programs.ghorg = {
  enable = true;
  reclone = {
    nix-community = {
      target = "nix-community";
      description = "Clone all nix-community repos";
    };
  };
};
```

Generates `ghorg/conf.yaml` and `ghorg/reclone.yaml` under `$XDG_CONFIG_HOME`.

### eca

Manages [ECA (Editor Code Assistant)](https://eca.dev) configuration.
Options live under `flakey.programs.eca` (see
[Option Namespacing](#option-namespacing)). Supports providers, agents, MCP
servers, tool-call approval rules, and inline or path-based rules/skills;
writes `~/.config/eca/config.json`.

```nix
flakey.programs.eca = {
  enable = true;
  settings = {
    defaultModel = "openai/gpt-5.2";
    providers.openai = {
      api = "openai-responses";
      key = "\${env:OPENAI_API_KEY}";
    };
  };
};
```

### drift-detector

Manages [Drift Detector](https://github.com/yellowstonesoftware/drift-detector)
config.yaml. Options live under `flakey.programs.drift-detector` (see
[Option Namespacing](#option-namespacing)).

```nix
flakey.programs.drift-detector = {
  enable = true;
  settings.github.organization = "myorg";
};
```

### Removed: omniwm

`flakey` used to ship its own `programs.omniwm` home-manager module for
[OmniWM](https://github.com/BarutSRB/OmniWM). Upstream home-manager has since
added its own `programs.omniwm` module at the exact same option path, so
flakey's copy was removed entirely rather than kept alongside it — two
independent modules declaring the same option path cannot safely coexist
(nixpkgs would reject the duplicate declaration), and there was no way to
"deprecate" the old module without keeping something declared at that path.
If you were using flakey's `omniwm` module, switch to home-manager's own
`programs.omniwm` instead.

## darwinModules
### nix-change-report

Automatically adds a change report using `nvd` to each darwin-nix activation.

## Darwin packages

A few OSX Apps that I use that aren't in nixpkgs, so I've add them to this repo.

These are auto-updated nightly using GitHub Actions.

### Package Management

Packages use the `sources.json` pattern:
- Each package has `sources.json` with `version`, `url`, and `hash`
- `default.nix` uses `lib.importJSON ./sources.json` (pure, flake-friendly)
- Multi-platform packages (like `eca-bin`) key by system: `sources.${stdenv.hostPlatform.system}`

### Adding a New Package

1. Create `modules/NAME/NAME.pkg.nix` (plain `callPackage` derivation, excluded from
   import-tree auto-import):
   ```nix
   { pkgs, stdenv, lib }:
   let sources = lib.importJSON ./sources.json;
   in stdenv.mkDerivation {
     inherit (sources) version;
     pname = "NAME";
     src = pkgs.fetchurl { inherit (sources) url sha256; };
     # ... build instructions
   }
   ```

2. Create `modules/NAME/NAME.nix` registering the package into
   `flake.modules.<class>.<name>` (see `modules/bitwarden/bitwarden.nix` for a
   minimal example).

3. Create `modules/NAME/update.sh`:
   ```bash
   #!/usr/bin/env nix-shell
   #!nix-shell -i bash -p jq curl gh
   source "$(dirname "$0")/../repository/ci/lib/github-release-update.sh"
   update_github_release OWNER REPO 'ASSET_PATTERN' | jq . > "$(dirname "$0")/sources.json"
   ```

4. Run `./modules/repository/ci/run-update-all-sources.sh` to generate initial `sources.json`

### Updating Packages

Run `./modules/repository/ci/run-update-all-sources.sh` to update all packages. This:
- Fetches latest releases from GitHub
- Downloads and hashes artifacts
- Updates `sources.json` files

### Bitwarden

Darwin package for [Bitwarden](bitwarden.com/)

### keepingYouAwake

[Keeping You Awake](https://keepingyouawake.app/)  Prevents your Mac from going to sleep

### Rectangle

[Rectangle](https://rectangleapp.com/): Move and resize windows in macOS using keyboard shortcuts or snap areas.

### Hot

[Hot](https://xs-labs.com/en/apps/hot/overview/)  is macOS menu bar application that displays the CPU speed limit due to thermal issues.

### Drift Detector

[Drift Detector](https://github.com/yellowstonesoftware/drift-detector) is a Swift CLI that inspects Kubernetes deployments and compares them against the latest GitHub release tags to identify version drift. Available for `x86_64-linux` and `aarch64-darwin` (only platforms published upstream).

## FAQ

### Collect Garbage `chmod ... operation not permitted`

#### Problem:
When running `nix-collect-garbage --delete-older-than 16`

You get something like
`error: chmod '/nix/store/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX-some-app-1.2.3/Applications/SomeApp.app': Operation not permitted`

#### Solution:

Grant `nix` full disk access.

1. Goto `Apple -> System Settings -> Privacy & Security -> Ful Disk Access`
2. Find `nix`
    * if you find multiple `nix` try removing all by highlighting them and clicking the `-` at the bottom, and try collecting garbage again.  You'll then see only a single `nix` entry show up.
3. Check the box for `nix`
