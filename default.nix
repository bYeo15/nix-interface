let
    sources = import ./npins;

    # --- Standard ---
    pkgs = import sources.nixpkgs {};
    lib = pkgs.lib;

    # --- Internal ---
    # common exposes a custom nix library + lists of common modules
    # common modules are classified as;
    # - data : only used as a wrapper for representing some data (compatible with nixos and home manager)
    # - nixos : generates nixos config, compatible only with nixos
    # - home : generates home manager config, compatible only with home manager
    common = import sources.common;
    extlib = common.extlib { inherit sources; inherit pkgs; inherit lib; };
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
    home-manager = import sources.home-manager { inherit pkgs; };
    nur = import sources.nur {
        nurpkgs = pkgs;
        pkgs = import sources.nixpkgs {
            overrides = [ (final: prev: if prev ? nur then prev else { nur = import sources.nur { pkgs = final; }; }) ];
        };
    };
    rpi = import sources.nixos-rpi;
    agenix = (flake-compat { src = sources.agenix.outPath; }).defaultNix;

    externalNixosModules = [
        agenix.nixosModules.age
    ];

    externalHomeModules = [
    ];

    externalPackages = {
        agenix = import sources.agenix { inherit pkgs; };
        inherit (home-manager) home-manager;
        # Not a package, but it makes the most sense
        # to put it here
        inherit nur;
    };

    # Combine common/secret internal and external modules
    dataModules = commonDataModules ++ secrets.data;
    nixosModules = commonNixosModules ++ externalNixosModules;
    homeModules = commonHomeModules ++ externalHomeModules;

    # --- Args ---
    args = {
        inherit sources;
        inherit extlib;
        inherit externalPackages;
        secrets = secrets.ageSecretFiles;
    };

    # FUTURE : Currently, there is no difference in arguments
    nixosArgs = args;
    homeArgs = args;


    mkNixos = hostModules: hostUsers: extlib.makeHost (
        hostModules ++
        hostUsers   ++
        dataModules ++
        nixosModules
    ) nixosArgs;

    mkUser = userModules: extlib.makeHome (
        userModules ++
        dataModules ++
        homeModules
    ) homeArgs;
in {
    nixpad = mkNixos hosts.nixpad [
        (users.userModules.namedMainUser "ben")
    ];

    # NOTE : Comes with dedicated "gaming" user
    nixpc = mkNixos hosts.nixpc [
        users.userModules.admin
    ];

    nixbook = mkNixos hosts.nixbook [
        users.userModules.admin
        users.userModules.node
    ];

    # TODO : May have to be a special host function
    # that uses nixos-raspberrypi
    # nixpi = TODO ... [
    #    users.userModules.admin
    #    users.userModules.staging
    #    users.userModules.node
    # ];

    ben = mkUser users.ben;
}
