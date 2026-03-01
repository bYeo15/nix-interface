let
    interface = import ./interface.nix;
    inherit (interface) hosts users;
    inherit (interface.eval) mkNixos mkNixosPi mkUser;
in {
    nixpad = mkNixos hosts.nixpad [
        (users.userModules.namedMainUser "ben")
    ];

    nixpc = mkNixos hosts.nixpc [
        users.userModules.admin
        (users.userModules.namedNodeUser "gaming")
    ];

    nixbook = mkNixos hosts.nixbook [
        users.userModules.admin
        (users.userModules.namedNodeUser "node")
    ];

    nixpi = mkNixosPi hosts.nixpi [
       users.userModules.admin
       users.userModules.staging
       (users.userModules.namedNodeUser "node")
    ];

    ben = mkUser users.ben;
}
