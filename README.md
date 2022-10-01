# Nix + GitHub Actions

Two separate pipelines:

* [`no-nix.yml`](./.github/workflows/no-nix.yml) configures a pipeline that uses third-party Actions
  for everything:
  * [`actions/checkout`][checkout]
* [`nix.yml`](./.github/workflows/nix.yml) configures a pipeline that

[checkout]: https://github.com/marketplace/actions/checkout
