{ pkgs }:

let
  inherit (pkgs) writeScriptBin;

  # Use cargo from Rust toolchain
  cargo = "${pkgs.rustToolchain}/bin/cargo";
in
[
  (writeScriptBin "ci-check-rust-formatting" ''
    ${cargo} fmt \
      --check \
      --all
  '')

  (writeScriptBin "ci-clippy" ''
    ${cargo} clippy --all-targets -- --deny warnings
  '')

  (writeScriptBin "ci-cargo-build" ''
    ${cargo} build --release --all-features
  '')

  # A helper script for running the CI suite locally
  (writeScriptBin "local-checks" ''
    ci-check-rust-formatting
    ci-clippy
  '')
]
