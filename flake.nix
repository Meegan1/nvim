{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixCats.url = "github:BirdeeHub/nixCats-nvim";
    flake-parts.url = "github:hercules-ci/flake-parts";

    "plugins-dropbar.nvim" = {
      url = "github:Bekaboo/dropbar.nvim";
      flake = false;
    };
    "plugins-mcphub.nvim" = {
      url = "github:bahaaza/mcphub.nvim";
      flake = false;
    };
    "plugins-mdx.nvim" = {
      url = "github:davidmh/mdx.nvim";
      flake = false;
    };
    "plugins-nx.nvim" = {
      url = "github:Sewb21/nx.nvim";
      flake = false;
    };
    "plugins-screenkey.nvim" = {
      url = "github:NStefan002/screenkey.nvim";
      flake = false;
    };
    plugins-lze = {
      url = "github:BirdeeHub/lze";
      flake = false;
    };
    "plugins-snacks.nvim" = {
      url = "github:folke/snacks.nvim";
      flake = false;
    };
    plugins-nvim-nio = {
      url = "github:nvim-neotest/nvim-nio";
      flake = false;
    };
    plugins-neotest = {
      url = "github:nvim-neotest/neotest";
      flake = false;
    };
    plugins-neotest-vitest = {
      url = "github:marilari88/neotest-vitest";
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
        flake =
          let
            myNixCats = import ./default.nix { inherit inputs; };
          in
          {

          }
          // myNixCats;
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
          {
          };
      }
    );
}
