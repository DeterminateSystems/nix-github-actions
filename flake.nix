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
          # This supplies cargo, rustc, rustfmt, etc.
          rustToolchain = super.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
        })
      ];
    in
    # System-specific logic
    flake-utils.lib.eachDefaultSystem
      (system:
      let
        pkgs = import nixpkgs { inherit overlays system; };

        runCiLocally = pkgs.writeScriptBin "ci-local" ''
          echo "Checking Rust formatting..."
          cargo fmt --check

          echo "Auditing Rust dependencies..."
          cargo-deny check

          echo "Auditing editorconfig conformance..."
          eclint -exclude "Cargo.lock"

          echo "Checking spelling..."
          codespell \
            --skip target,.git \
            --ignore-words-list crate

          echo "Testing Rust code..."
          cargo test

          echo "Building TODOs service..."
          nix build .#todos
        '';
      in
      {
        devShells = {
          # Unified shell environment
          default = pkgs.mkShell
            {
              buildInputs = [ runCiLocally ] ++ (with pkgs; [
                # Rust stuff (CI + dev)
                rustToolchain
                cargo-deny

                # Rust stuff (dev only)
                cargo-edit
                cargo-watch

                # Spelling and linting
                codespell
                eclint
              ]);
            };
        };

        packages = rec {
          default = todos;

          todos = pkgs.rustPlatform.buildRustPackage {
            pname = name;
            inherit version;
            src = ./.;
            cargoSha256 = "sha256-nLnEn3jcSO4ChsXuCq0AwQCrq/0KWvw/xWK1s79+zBs=";
            release = true;
          };

          docker =
            let
              bin = "${self.packages.${system}.todos}/bin/${name}";
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
