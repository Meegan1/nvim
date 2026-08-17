{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixCats.url = "github:BirdeeHub/nixCats-nvim";
    flake-parts.url = "github:hercules-ci/flake-parts";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

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
    plugins-blink-cmp-git = {
      url = "github:Kaiser-Yang/blink-cmp-git";
      flake = false;
    };
    "plugins-blink-emoji.nvim" = {
      url = "github:moyiz/blink-emoji.nvim";
      flake = false;
    };
    "plugins-octo.nvim" = {
      url = "github:pwntester/octo.nvim";
      flake = false;
    };
    "plugins-copilot.lua" = {
      url = "github:zbirenbaum/copilot.lua";
      flake = false;
    };
    "plugins-codecompanion.nvim" = {
      url = "github:olimorris/codecompanion.nvim";
      flake = false;
    };
    "plugins-codecompanion-history.nvim" = {
      url = "github:ravitemer/codecompanion-history.nvim";
      flake = false;
    };
    "plugins-fzf-lua" = {
      url = "github:ibhagwan/fzf-lua";
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
            myNixCats = import ./nix { inherit inputs; };
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
