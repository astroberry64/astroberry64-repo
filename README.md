# Astroberry64 APT Repository

APT repository for Astroberry64 packages (64-bit Raspberry Pi OS Bookworm).

## Using this repository

### For Production Users (Stable)

Add to your `/etc/apt/sources.list.d/astroberry64.list`:

```bash
deb [trusted=yes] https://astroberry64.github.io/astroberry64-repo/ bookworm-stable main
```

Then update and install:

```bash
sudo apt update
sudo apt install astroberry64-server-full
```

### For Developers/Testers (Testing)

Add to your `/etc/apt/sources.list.d/astroberry64.list`:

```bash
deb [trusted=yes] https://astroberry64.github.io/astroberry64-repo/ bookworm-testing main
```

The `bookworm-testing` suite contains packages built automatically from CI/CD and should be considered unstable.

## Repository Structure

This repository is served via GitHub Pages at https://astroberry64.github.io/astroberry64-repo/

### Suites

- **bookworm-stable**: Production-ready packages, manually tested
- **bookworm-testing**: Automated builds from GitHub Actions, for testing only
