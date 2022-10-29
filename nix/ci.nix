{ pkgs }:

let
  inherit (pkgs) writeScriptBin;
in
[
  (writeScriptBin "ci-check-rust-formatting" ''
    cargo fmt \
      --check \
      --all
  '')

  (writeScriptBin "ci-cargo-audit" ''
    cargo-deny check
  '')

  (writeScriptBin "ci-check-editorconfig" ''
    eclint -exclude "Cargo.lock"
  '')

  (writeScriptBin "ci-check-spelling" ''
    codespell \
      --skip target \
      --ignore-words-list crate \
      .
  '')

  (writeScriptBin "ci-cargo-test" ''
    cargo test
  '')

  # A helper script for running the CI suite locally
  (writeScriptBin "ci-local" ''
    ci-check-rust-formatting
    ci-cargo-audit
    ci-check-editorconfig
    ci-check-spelling

    ci-cargo-test
  '')
]
