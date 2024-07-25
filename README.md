# Flakey

## Provides

`nix flake show`

```
├───darwinModules: unknown
├───homeModules: unknown
├───nixosModules
│   ├───default: NixOS module
│   ├───allow-unfree-predicates: NixOS module
│   └───nix-change-report: NixOS module
├───overlays
│   └───default: Nixpkgs overlay
└───packages
    ├───aarch64-darwin
    │   ├───bitwarden: package 'Bitwarden-2024.4.1'
    │   ├───hot: package 'Hot-1.9.1'
    │   ├───keepingYouAwake: package 'KeepingYouAwake-1.6.5'
    │   └───rectangle: package 'Rectangle-0.77'
    └───x86_64-darwin
        ├───bitwarden: package 'Bitwarden-2024.4.1'
        ├───hot: package 'Hot-1.9.1'
        ├───keepingYouAwake: package 'KeepingYouAwake-1.6.5'
        └───rectangle: package 'Rectangle-0.77'
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

These are auto-updated nightly using a github actions.

### Bitwarden

Darwin package for [Bitwarden](bitwarden.com/)

### keepingYouAwake

[Keeping You Awake](https://keepingyouawake.app/)  Prevents your Mac from going to sleep

### Rectangle

[Rectangle](https://rectangleapp.com/): Move and resize windows in macOS using keyboard shortcuts or snap areas.

### Hot

[Hot](https://xs-labs.com/en/apps/hot/overview/)  is macOS menu bar application that displays the CPU speed limit due to thermal issues. 
