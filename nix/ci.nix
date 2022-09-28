{ pkgs }:

let
  inherit (pkgs) writeScriptBin;

  # Use cargo from Rust toolchain
  cargo = "${pkgs.rustToolchain}/bin/cargo";
in
[
  (writeScriptBin "ci-check-rust-formatting" ''
    ${cargo} fmt --check
  '')

  (writeScriptBin "local-checks" ''
    ci-check-rust-formatting
  '')

  (writeScriptBin "ci-checks" ''
    ci-check-rust-formatting
  '')
]
