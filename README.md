# Astroberry64 APT Repository

APT repository for Astroberry64 packages (64-bit Raspberry Pi OS Trixie).

## Using this repository

### For Production Users (Stable)

Add to your `/etc/apt/sources.list.d/astroberry64.list`:

```bash
deb [trusted=yes] https://astroberry64.github.io/astroberry64-repo/ trixie-stable main
```

Then update and install:

```bash
sudo apt update
sudo apt install astroberry64-server-full
```

### For Developers/Testers (Testing)

Add to your `/etc/apt/sources.list.d/astroberry64.list`:

```bash
deb [trusted=yes] https://astroberry64.github.io/astroberry64-repo/ trixie-testing main
```

The `trixie-testing` suite contains packages built automatically from CI/CD and should be considered unstable.

## Repository Structure

This repository is served via GitHub Pages at https://astroberry64.github.io/astroberry64-repo/

### Suites

- **trixie-stable**: Production-ready packages, manually tested
- **trixie-testing**: Automated builds from GitHub Actions, for testing only
