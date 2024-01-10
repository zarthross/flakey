# Flakey

## Provides

`nix flake show`

```
├───darwinModules: unknown
├───homeManagerModules: unknown
├───nixosModules
│   ├───allow-unfree-predicates: NixOS module
│   ├───default: NixOS module
│   └───nixos-change-report: NixOS module
├───overlays
│   └───default: Nixpkgs overlay
└───packages
    ├───aarch64-darwin
    │   ├───bitwarden: package 'Bitwarden-2023.9.1'
    │   ├───brave: package 'Brave-1.58.135'
    │   ├───hot: package 'Hot-1.9.1'
    │   ├───keepingYouAwake: package 'KeepingYouAwake-1.6.5'
    │   └───rectangle: package 'Rectangle-0.73'
    └───x86_64-darwin
        ├───bitwarden: package 'Bitwarden-2023.9.1'
        ├───brave: package 'Brave-1.58.135'
        ├───hot: package 'Hot-1.9.1'
        ├───keepingYouAwake: package 'KeepingYouAwake-1.6.5'
        └───rectangle: package 'Rectangle-0.73'
```

## nixosModules 
### allow-unfree-predicates

With this modules, instead of:

```
allowUnfree = true;  # EVERYTHING IS ALLOWED;
```

or 

```
# You CANNOT set this in multiple places since its a function...
allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "roon-server"
    "vscode"
  ];
```

now you can write:

```
# Its just a list of package regexes you want to allow.  
# you can set this in multiple modules and it just adds more regexes!!!
allowedUnfreePackagesRegexs = ["slack" "discord"];
```
### nixos-change-report

Automatically adds a change report using `nvd` to each nixos activation.

## homeManagerModules
### allow-unfree-predicates
[See](#allow-unfree-predicates)
### hm-change-report

Automatically adds a change report using `nvd` to each home-manager activation.

## darwinModules
### nix-darwin-change-report

Automatically adds a change report using `nvd` to each darwin-nix activation.

## Darwin packages

A few OSX Apps that I use that aren't in nixpkgs, so I've add them to this repo.

These are auto-updated nightly using a github actions.

### Bitwarden

Darwin package for [Bitwarden](bitwarden.com/)

### Brave

Darwin package for [Brave](https://brave.com/)

### keepingYouAwake

[Keeping You Awake](https://keepingyouawake.app/)  Prevents your Mac from going to sleep

### Rectangle

[Rectangle](https://rectangleapp.com/): Move and resize windows in macOS using keyboard shortcuts or snap areas.

### Hot

[Hot](https://xs-labs.com/en/apps/hot/overview/)  is macOS menu bar application that displays the CPU speed limit due to thermal issues. 
