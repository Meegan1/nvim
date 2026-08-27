{ pkgs, ... }:
pkgs.buildGoModule rec {
  pname = "laravel-ls";
  version = "latest";

  src = pkgs.fetchFromGitHub {
    owner = "laravel-ls";
    repo = "laravel-ls";
    rev = "main"; # replace with a specific tag/commit for reproducibility
    hash = "sha256-mA/URPemEFUcfiOzLhbElBDTFPsYAZS1ybRAu41mC78="; # fill in after first run
  };

  vendorHash = "sha256-3DJPumD0cKHtfJo4bY2uRzgR39AhmjKNL92zLmxgox4="; # fill in after first run

  # This is critical: don't use the vendor directory, let Nix build it
  # so that C source files from tree-sitter are included
  proxyVendor = true;

  nativeBuildInputs = [ pkgs.pkg-config ];

  buildInputs = [ ];

  env = {
    # CGo is needed for tree-sitter bindings
    CGO_ENABLED = "1";
  };

  meta = with pkgs.lib; {
    description = "Laravel Language Server written in Go";
    homepage = "https://github.com/laravel-ls/laravel-ls";
    license = licenses.gpl3;
    mainProgram = "laravel-ls";
  };
}
