# NixOS Interface

Provides the root file for actually building a NixOS/Home Manager generation from config files.

Handles the loading of all pinned sources, and the evaluation of config modules to produce a derivation.


## Current Pins

Nixpkgs Unstable

Internal:
- `common` : NixOS common modules and standard library extension
- `hosts` : Modules for hosts (NixOS configs)
- `users` : Modules for users (NixOS users + Home Manager configs)
- `secrets` : Secret data and agenix

External:
- `agenix` : Secret management (module + package)
- `flake-compat` : Flake loading for other pins (function)
- `home-manager` (FORK) : Home config generation (modules + package)
- `nixos-rpi` : NixOS Raspberry Pi utils (modules)
- `nur` : NixOS user repository (modules + packages)


## Module Arguments

In addition to the standard `config, lib, pkgs` exposed to modules, the following additional arguments are provided (to both NixOS and Home Manager modules):
- `sources` : the `npins` sources, exposed directly. Should be used minimally (if at all)
- `extlib` : an extension to the standard nix library. See common for more information
- `externalPackages` : a set of named packages, produced from pinned sources (also exposes `nur`)
- `secrets` : a set of named secret files (typically `.age` files)


## Hosts

Hosts (with their modules exposed from the `hosts` source) can be produced with the `mkNixos` function. This produces a valid attrset that can be passed to `nixos-rebuild` (with `--file` pointing to `default.nix`, and `--attr` pointing to the given host).

`mkNixos` takes an additional argument, a list of `users` (exposed from the `users` source) to include on the given host.


## Home Users

Home Manager users (with their modules expsoed from the `users` source) can be produced with the `mkUser` function. This produces a valid attrset that could be passed to `home-manager` if it accepted custom build targets. For now, either build the derivation manually and switch to it manually (NOT RECOMMENDED) or use my downstream Home Manager that exposes `--build-file` and `--build-attr`.
