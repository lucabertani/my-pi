# my-pi

This repository tracks the latest released version of [pi](https://github.com/earendil-works/pi) and automatically builds it for Windows.

Every day (08:00 UTC) the GitHub Actions workflow in `.github/workflows/build-pi.yml` checks the latest pi release: when a new version is out, it clones the source at that tag, compiles the CLI with `bun build --compile --bytecode` (standalone executable, bytecode for fastest startup), smoke-tests the exe on a Windows runner, and publishes a GitHub Release containing a zip with `pi.exe` + the assets it needs at runtime.

The file `last_version.txt` stores the pi version currently released in this repository.

## Install / update (Windows)

Use `install.ps1`:

```powershell
.\install.ps1
```

The script checks the latest release of this repository and, if it is newer than the locally installed one, downloads the zip and installs pi. The install path is configured in the variables at the top of the script (`$InstallDir`).

Useful upstream links:

- https://api.github.com/repos/earendil-works/pi/releases/latest — latest pi release metadata (JSON)
- https://github.com/earendil-works/pi/releases — official pi releases
- https://github.com/lucabertani/my-pi/releases — the Windows builds published by this repository
