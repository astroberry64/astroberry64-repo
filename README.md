# Astroberry64 APT Repository

APT repository for Astroberry64 packages (64-bit Raspberry Pi OS Bookworm).

## Using this repository

Add to your `/etc/apt/sources.list.d/astroberry64.list`:

```bash
deb [trusted=yes] https://astroberry64.github.io/astroberry64-repo/ bookworm main
```

Then update and install:

```bash
sudo apt update
sudo apt install astroberry64-server-full
```

## Repository Structure

This repository is served via GitHub Pages at https://astroberry64.github.io/astroberry64-repo/
