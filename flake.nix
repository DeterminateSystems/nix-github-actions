{
  description = "Nix + GitHub Actions";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
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
    # Non-system-specific logic
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

        # Import scripts to run in CI
        ciScripts = import ./nix/ci.nix { inherit pkgs; };
      in
      {
        devShells = {
          # Local development
          default = pkgs.mkShell {
            buildInputs = (with pkgs; [
              rustToolchain
              cargo-deny
              cargo-edit
              cargo-watch
            ]) ++ ciScripts;
          };

          # CI
          ci = pkgs.mkShell {
            buildInputs = (with pkgs;
              [
                rustToolchain
                cargo-deny
              ]) ++ ciScripts;
          };
        };

        packages = rec {
          default = pkgs.rustPlatform.buildRustPackage {
            pname = name;
            inherit version;
            src = ./.;
            cargoSha256 = "sha256-nLnEn3jcSO4ChsXuCq0AwQCrq/0KWvw/xWK1s79+zBs=";
            release = true;
          };

          docker =
            let
              bin = "${self.packages.${system}.default}/bin/${name}";
            in
            pkgs.dockerTools.buildLayeredImage {
              inherit name;
              tag = "v${version}";

              config = {
                Entrypoint = [ bin ];
                ExposedPorts."8080/tcp" = { };
              };
            };
        };
      });
}
