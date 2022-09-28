{
  description = "Nix + GitHub Actions";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-22.05";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , rust-overlay
    }:
    # System-non-specific logic
    let
      # Borrow project metadata from the Rust config
      meta = (builtins.fromTOML (builtins.readFile ./Cargo.toml)).package;
      inherit (meta) name version;

      overlays = [
        # Rust helpers
        (import rust-overlay)
        # Build Rust toolchain using helpers from rust-overlay
        (self: super: {
          rustToolchain = super.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
        })
      ];
    in
    # System-specific logic
    flake-utils.lib.eachDefaultSystem
      (system:
      let
        pkgs = import nixpkgs { inherit overlays system; };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            rustToolchain
          ];

          shellHook = ''
            echo "${name} ${version}"
          '';
        };
      });
}
