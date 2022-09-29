{ pkgs }:

let
  inherit (pkgs) writeScriptBin;

  # Use cargo from Rust toolchain
  cargo = "${pkgs.rustToolchain}/bin/cargo";

  # Helper function for running executables
  run = pkg: "${pkgs.${pkg}}/bin/${pkg}";
in
[
  (writeScriptBin "ci-check-rust-formatting" ''
    ${cargo} fmt \
      --check \
      --all
  '')

  (writeScriptBin "ci-cargo-build" ''
    ${cargo} build --release --all-features
  '')

  (writeScriptBin "ci-cargo-test" ''
    ${cargo} test --no-fail-fast
  '')

  (writeScriptBin "ci-check-editorconfig" ''
    ${run "eclint"} -exclude "Cargo.lock"
  '')

  # A helper script for running the CI suite locally
  (writeScriptBin "local-checks" ''
    ci-check-rust-formatting
    ci-cargo-build
    ci-cargo-test
  '')
]
