{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixCats.url = "github:BirdeeHub/nixCats-nvim";
    flake-parts.url = "github:hercules-ci/flake-parts";

    plugins-mcphub-nvim = {
      url = "github:ravitemer/mcphub.nvim";
      flake = false;
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    # https://flake.parts/module-arguments.html
    flake-parts.lib.mkFlake { inherit inputs; } (
      top@{
        config,
        withSystem,
        moduleWithSystem,
        ...
      }:
      {
        imports = [
          # Optional: use external flake logic, e.g.
          # inputs.foo.flakeModules.default
        ];
        flake = {
          # Put your original flake attributes here.
        };
        systems = [
          # systems for which you want to build the `perSystem` attributes
          "x86_64-linux"
          "aarch64-linux"
          "x86_64-darwin"
          "aarch64-darwin"
          # ...
        ];
        perSystem =
          {
            config,
            pkgs,
            system,
            ...
          }:
          let
            myNixCats = import ./default.nix { inherit inputs; };
          in
          {
            packages = myNixCats.packages.${system};
          };
      }
    );
}
