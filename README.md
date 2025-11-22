# Setup your mac, my way
[![CI](https://github.com/cmccomb/setup-and-keepup/actions/workflows/ci.yml/badge.svg)](https://github.com/cmccomb/setup-and-keepup/actions/workflows/ci.yml)
[![work.zsh](https://github.com/cmccomb/setup-and-keepup/actions/workflows/test-work.yml/badge.svg)](https://github.com/cmccomb/setup-and-keepup/actions/workflows/test-work.yml)
[![play.zsh](https://github.com/cmccomb/setup-and-keepup/actions/workflows/test-play.yml/badge.svg)](https://github.com/cmccomb/setup-and-keepup/actions/workflows/test-play.yml)
[![deploy](https://github.com/cmccomb/setup-and-keepup/actions/workflows/static.yml/badge.svg)](https://github.com/cmccomb/setup-and-keepup/actions/workflows/static.yml)

This repo contains a heavily opinionated setup-and-keepup script for my Macs. To use this script, simply run:

For work:
```bash
zsh -i <(curl -s https://cmccomb.com/setup-and-keepup/work.zsh)
```

For play:
```bash
zsh -i <(curl -s https://cmccomb.com/setup-and-keepup/play.zsh)
```

## Keep the setup fresh automatically

To mirror this repository into `~/.setup-and-keepup`, regenerate the stack scripts, and
configure `launchd` to run the selected stack at login and on boot, run:

```bash
./agent.sh
```

The helper script accepts optional flags such as `--profile play`. Use `--uninstall`
when you want to remove every setup-and-keepup LaunchAgent and helper script. It writes a
`~/Library/Scripts/run-setup-<profile>.sh` helper and a matching LaunchAgent plist so macOS reruns the
selected stack at each login or system boot. Prefer to bootstrap straight from the internet?

```bash
bash <(curl -fsSL https://cmccomb.com/setup-and-keepup/agent.sh)
```

Pass any of the flags shown above to the one-liner and use the `SETUP_REPO_URL`
environment variable if you host a fork of the repository.

The agent and its helper script automatically reset the generated
`scripts/play.zsh` and `scripts/work.zsh` files before pulling updates so that a
dirty working tree will not block future refreshes.
