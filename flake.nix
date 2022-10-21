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

        # Import CI scripts
        ci = import ./nix/ci.nix { inherit pkgs; };
      in
      {
        devShells.default = pkgs.mkShell {

          buildInputs = (with pkgs;
            [
              rustToolchain
              cargo-deny
            ]) ++ ci;

          shellHook = ''
            echo "project: <${name} v${version}>"
          '';
        };

        packages = rec {
          default = pkgs.rustPlatform.buildRustPackage {
            pname = name;
            inherit version;

            src = ./.;

            cargoSha256 = "sha256-nLnEn3jcSO4ChsXuCq0AwQCrq/0KWvw/xWK1s79+zBs=";
          };

          docker = pkgs.dockerTools.buildLayeredImage {
            inherit name;
            tag = "v${version}";

            config = {
              Entrypoint = [ "${self.packages.${system}.default}/bin/${name}" ];
              ExposedPorts."8080/tcp" = { };
            };
          };
        };
      });
}
