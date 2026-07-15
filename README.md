# Flakey

[![CI](https://github.com/zarthross/flakey/actions/workflows/ci.yaml/badge.svg)](https://github.com/zarthross/flakey/actions/workflows/ci.yaml)
[![Update Sources](https://github.com/zarthross/flakey/actions/workflows/update-sources.yaml/badge.svg)](https://github.com/zarthross/flakey/actions/workflows/update-sources.yaml)

## Provides

`nix flake show`

```
├───darwinModules: unknown
├───homeModules: unknown
├───nixosModules
│   ├───default: NixOS module
│   ├───allow-unfree-predicates: NixOS module
│   ├───nix-change-report: NixOS module
│   └───nixos-change-report: NixOS module
├───overlays
│   └───default: Nixpkgs overlay
└───packages
    ├───aarch64-darwin
    │   ├───bitwarden: package 'Bitwarden-2026.5.0'
    │   ├───drift-detector: package 'drift-detector-v0.0.7'
    │   ├───eca-bin: package 'eca-bin-0.147.0'
    │   ├───hot: package 'Hot-1.9.4'
    │   ├───keepingYouAwake: package 'KeepingYouAwake-1.6.8'
    │   ├───omniwm: package 'OmniWM-0.4.9.6'
    │   ├───rectangle: package 'Rectangle-0.96'
    │   └───render-workflows: package 'render-workflows'
    ├───aarch64-linux
    │   ├───drift-detector: package 'drift-detector-v0.0.7'
    │   ├───eca-bin: package 'eca-bin-0.147.0'
    │   └───render-workflows: package 'render-workflows'
    ├───x86_64-darwin
    │   ├───bitwarden: package 'Bitwarden-2026.5.0'
    │   ├───drift-detector: package 'drift-detector-v0.0.7'
    │   ├───eca-bin: package 'eca-bin-0.147.0'
    │   ├───hot: package 'Hot-1.9.4'
    │   ├───keepingYouAwake: package 'KeepingYouAwake-1.6.8'
    │   ├───omniwm: package 'OmniWM-0.4.9.6'
    │   ├───rectangle: package 'Rectangle-0.96'
    │   └───render-workflows: package 'render-workflows'
    └───x86_64-linux
        ├───drift-detector: package 'drift-detector-v0.0.7'
        ├───eca-bin: package 'eca-bin-0.147.0'
        └───render-workflows: package 'render-workflows'
```

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

1. Create `packages/NAME/default.nix`:
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

2. Create `packages/NAME/update.sh`:
   ```bash
   #!/usr/bin/env nix-shell
   #!nix-shell -i bash -p jq curl gh
   source "$(dirname "$0")/../../ci/lib/github-release-update.sh"
   update_github_release OWNER REPO 'ASSET_PATTERN' | jq . > "$(dirname "$0")/sources.json"
   ```

3. Run `./ci/update.sh` to generate initial `sources.json`

### Updating Packages

Run `./ci/update.sh` to update all packages. This:
- Fetches latest releases from GitHub
- Downloads and hashes artifacts
- Updates `sources.json` files

### Bitwarden

Darwin package for [Bitwarden](bitwarden.com/)

### keepingYouAwake

[Keeping You Awake](https://keepingyouawake.app/)  Prevents your Mac from going to sleep

### Rectangle

[Rectangle](https://rectangleapp.com/): Move and resize windows in macOS using keyboard shortcuts or snap areas.

### OmniWM

[OmniWM](https://barutsrb.github.io/OmniWM/): macOS tiling window manager inspired by Niri and Hyprland, developer signed and notarized.

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
