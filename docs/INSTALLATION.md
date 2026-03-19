# Documentation installation and setup

This guide covers how to set up the documentation build environment for the Wazuh Docker documentation.

## Prerequisites

The documentation is built using [mdBook](https://rust-lang.github.io/mdBook/), a command-line tool for creating books
with Markdown, along with [mdBook Mermaid](https://github.com/badboy/mdbook-mermaid) for diagram support.

## Required versions

- **mdbook**: 0.5.2
- **mdbook-mermaid**: 0.17.0

## Installation

Install tools:

```bash
cargo install mdbook --version 0.5.2
cargo install mdbook-mermaid --version 0.17.0
```

Verify installation:

```bash
mdbook --version
mdbook-mermaid --version
```

## Building the documentation

Once you have installed mdBook and mdBook Mermaid:

```bash
# Navigate to the docs directory
cd docs

# Build the documentation (generates html in docs/book/)
mdbook build

# Serve locally with live reload (recommended for development)
mdbook serve --open
```

The documentation will be available at `http://localhost:3000` when using `mdbook serve`.

## Development workflow

When editing documentation:

1. Run `mdbook serve --open` from the `docs/` directory
2. Edit markdown files in `docs/ref/`
3. Changes are automatically reflected in the browser
4. Navigation structure is defined in `docs/SUMMARY.md`

## Troubleshooting

### Version mismatch errors

If you encounter build errors, verify you have the correct versions installed:

```bash
mdbook --version
mdbook-mermaid --version
```

If you have different versions, uninstall the current ones and reinstall by following the [Installation section](#installation):

```bash
cargo uninstall mdbook
cargo uninstall mdbook-mermaid
```

### Cargo install fails with feature 'edition2024' is required

You may see an error like:

```sh
failed to download `globset v0.4.18`
failed to parse manifest ... feature `edition2024` is required
The package requires the Cargo feature called `edition2024`, but that feature is not stabilized in this version of Cargo.
```

This can happen when installing `mdbook` version 0.5.2 because one of its transitive dependencies has been updated to
use Rust edition 2024, which is only supported on nightly Rust toolchains.

To fix it, install the required `mdbook` version (0.5.2) using nightly Rust:

```sh
rustup install nightly
rustup run nightly cargo install mdbook --version 0.5.2
```

### Mermaid diagrams not rendering

If Mermaid diagrams are not rendering in the browser:

1. Clear your browser cache
2. Run `mdbook clean` to remove the build directory
3. Run `mdbook serve --open` again

### Port already in use

If port 3000 is already in use, specify a different port:

```bash
mdbook serve --port 3001 --open
```

## Additional resources

- [mdBook documentation](https://rust-lang.github.io/mdBook/)
- [mdBook Mermaid documentation](https://github.com/badboy/mdbook-mermaid)
- [Mermaid diagram syntax](https://mermaid.js.org/)
