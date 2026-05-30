/*
    Handles loading all pins
*/
let
    sources = import ./npins;

    # --- Standard ---
    pkgs = import sources.nixpkgs { };
    lib = pkgs.lib;


    # --- Internal ---
    # common exposes a custom nix library + out of tree packages  + lists of common modules
    # common modules are classified as;
    # - data : only used as a wrapper for representing some data (compatible with nixos and home manager)
    # - nixos : generates nixos config, compatible only with nixos
    # - home : generates home manager config, compatible only with home manager
    common = import sources.common;
    extlib = common.extlib { inherit sources pkgs lib; };
    commonExtpkgs = common.extpkgs { inherit pkgs lib; };
    commonOverlays = common.inject_overlays;
    commonDataModules = common.data;
    commonNixosModules = common.nixos;
    commonHomeModules = common.home;

    # hosts and users provide an attrset of <name> -> list of dedicated modules
    # (hosts being nixos configs, users being home-manager configs)
    # users also provides a `userModules` attribute that exposes generic users
    hosts = import sources.hosts;
    users = import sources.users;

    # secrets is an interface providing;
    # - data : secret realisations of data modules
    # - ageSecretFiles : an attrset of <name> -> <age secret files>
    #                    forwarded to modules as `secrets` argument
    secrets = import sources.secrets;


    # --- External ---
    flake-compat = import sources.flake-compat;

    # my fork of home-manager (changes `home-manager` script to support pre-eval)
    home-manager = import sources.home-manager { inherit pkgs; };

    nur = import sources.nur {
        nurpkgs = pkgs;
        pkgs = import sources.nixpkgs {
            overrides = [ (final: prev: if prev ? nur then prev else { nur = import sources.nur { pkgs = final; }; }) ];
        };
    };

    rpi = import sources.nixos-rpi;
    # modules exposed by nixos-rpi required for a pi build
    rpiModules = [
        rpi.lib.inject-overlays
        rpi.nixosModules.trusted-nix-caches
        rpi.nixosModules.nixpkgs-rpi
    ];

    agenix = (flake-compat { src = sources.agenix.outPath; }).defaultNix;


    # --- Bundle Components ---
    externalNixosModules = [
        agenix.nixosModules.age
    ];

    externalHomeModules = [
    ];

    # Combine common/secret internal and external modules
    dataModules = commonDataModules ++ secrets.data;
    nixosModules = commonNixosModules ++ externalNixosModules;
    homeModules = commonHomeModules ++ externalHomeModules;

    # Merge extpkgs from common w/ external packages
    extpkgs = {
        # agenix/default.nix results in { agenix = <pkg drv>; ... }
        agenix = (import sources.agenix { inherit pkgs; }).agenix;
        inherit (home-manager) home-manager;
        # Not a package, but it makes the most sense
        # to put it here
        inherit nur;
    } // commonExtpkgs;


    # --- Args ---
    args = {
        inherit sources;
        inherit extlib;
        inherit extpkgs;
        secrets = secrets.ageSecretFiles;
    };

    # FUTURE : Currently, there is no difference in arguments
    nixosArgs = args;
    homeArgs = args;


    # --- Eval Wrapper Functions ---
    mkNixos = hostModule: hostUsers: extlib.makeHost (
        [ hostModule ] ++
        hostUsers      ++
        dataModules    ++
        nixosModules   ++
        commonOverlays
    ) nixosArgs;

    mkNixosPi = hostModule: hostUsers: extlib.makeHost (
        [ hostModule ] ++
        hostUsers      ++
        dataModules    ++
        nixosModules   ++
        rpiModules     ++
        commonOverlays
    ) (nixosArgs // { nixos-raspberrypi = rpi; });

    mkUser = userModule: extlib.makeHome (
        [ userModule ] ++
        dataModules    ++
        homeModules    ++
        commonOverlays
    ) homeArgs;
in {
    # --- Interface ---
    # Expose actual hosts and users
    inherit hosts users;

    # Expose config eval functions
    eval = {
        inherit mkNixos mkNixosPi;
        inherit mkUser;
    };

    # Expose common overlays for repl use
    overlays = common.overlays;

    # --- Debug ---
    # Expose pin sources
    inherit sources;

    # Expose instantiated pins
    pins = {
        inherit pkgs lib;
        inherit common hosts users secrets;
        inherit flake-compat home-manager nur rpi agenix;
        # Technically not true pins, but nice to expose regardless
        inherit extlib extpkgs;
    };
}
