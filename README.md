# Setup your mac, my way
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
schedule a refresh through `launchd`, run:

```bash
./agent.sh
```

The helper script accepts optional flags such as `--profile play` and
`--schedule "30 7 * * 5"` if you prefer a different cadence. Use `--uninstall`
when you want to remove every setup-and-keepup LaunchAgent and helper script. It writes a
`~/Library/Scripts/run-setup-<profile>.sh` helper and a matching LaunchAgent plist so macOS reruns the
selected stack on the schedule you choose. Prefer to bootstrap straight from the internet?

```bash
bash <(curl -fsSL https://cmccomb.com/setup-and-keepup/agent.sh)
```

Pass any of the flags shown above to the one-liner and use the `SETUP_REPO_URL`
environment variable if you host a fork of the repository.
