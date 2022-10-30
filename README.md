# Nix + GitHub Actions

> **Note**: this repo is discussed in [Streamline your GitHub Actions
> dependencies using Nix][post] on the [Determinate Systems blog][blog].

This repo houses an example project that shows you how to use [Nix] to replace
(some) third-party Actions in your [GitHub Actions][actions] CI pipelines. The
build artifact in the repo is a simple "TODOs" web server written in [Rust]. The
CI pipeline does several things:

* Checks the Rust formatting using [rustfmt]
* Audits the Rust code using [`cargo-deny`][cargo-deny]
* Checks the repo's files for [EditorConfig] conformance
* Spellchecks the repo's files using [codespell]
* Runs the service's [tests]
* Builds an executable for the service

But different from most repos, there are two separate pipelines here that
accomplish the same thing:

* [`no-nix.yml`](./.github/workflows/no-nix.yml) configures a pipeline that uses
  third-party Actions for *all* CI logic.
* [`nix.yml`](./.github/workflows/nix.yml) configures a pipeline that replaces
  most third-party Actions with straightforward shell commands.

[actions]: https://github.com/features/actions/
[blog]: https://determinate.systems/posts/
[cargo-deny]: https://doc.rust-lang.org/cargo/
[checkout]: https://github.com/marketplace/actions/checkout/
[codespell]: https://github.com/codespell-project/codespell/
[editorconfig]: https://editorconfig.org/
[nix]: https://nixos.org/
[post]: https://determinate.systems/posts/nix-github-actions
[rust]: https://rust-lang.org/
[rustfmt]: https://rust-lang.github.io/rustfmt/
[tests]: ./src/main.rs#L47-L86
