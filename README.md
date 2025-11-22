# Setup your mac, my way
[![CI](https://github.com/cmccomb/setup-and-keepup/actions/workflows/ci.yml/badge.svg)](https://github.com/cmccomb/setup-and-keepup/actions/workflows/ci.yml)
[![work.zsh](https://github.com/cmccomb/setup-and-keepup/actions/workflows/test-work.yml/badge.svg)](https://github.com/cmccomb/setup-and-keepup/actions/workflows/test-work.yml)
[![play.zsh](https://github.com/cmccomb/setup-and-keepup/actions/workflows/test-play.yml/badge.svg)](https://github.com/cmccomb/setup-and-keepup/actions/workflows/test-play.yml)
[![deploy](https://github.com/cmccomb/setup-and-keepup/actions/workflows/static.yml/badge.svg)](https://github.com/cmccomb/setup-and-keepup/actions/workflows/static.yml)

This repo contains a heavily opinionated setup-and-keepup script for my Macs. Start with a single bash one-liner that bootstraps everything via `curl`:

```bash
bash <(curl -fsSL https://cmccomb.com/setup-and-keepup/agent.sh) --profile work
```

Switch to the play stack by passing `--profile play` instead. If you only want to run a stack once without installing anything, you can still stream it directly:

```bash
zsh -i <(curl -s https://cmccomb.com/setup-and-keepup/play.zsh)
```

## Keep the setup fresh automatically

To mirror this repository into `~/.setup-and-keepup`, regenerate the stack scripts, and
configure `launchd` to run the selected stack at login and on boot, run:

```bash
bash <(curl -fsSL https://cmccomb.com/setup-and-keepup/agent.sh) --profile work
```

The helper script accepts optional flags such as `--profile play`. Use `--uninstall`
when you want to remove every setup-and-keepup LaunchAgent and helper script. It writes a
`~/Library/Scripts/run-setup-<profile>.sh` helper and a matching LaunchAgent plist so macOS reruns the
selected stack at each login or system boot. Prefer to bootstrap straight from the internet?

```bash
bash <(curl -fsSL https://cmccomb.com/setup-and-keepup/agent.sh) --profile play
```

Pass any of the flags shown above to either one-liner and use the `SETUP_REPO_URL`
environment variable if you host a fork of the repository.

The agent and its helper script automatically reset the generated
`scripts/play.zsh` and `scripts/work.zsh` files before pulling updates so that a
dirty working tree will not block future refreshes.

## Uninstall

To remove setup-and-keepup completely, run the agent in uninstall mode and then
delete the cloned repository:

```bash
bash <(curl -fsSL https://cmccomb.com/setup-and-keepup/agent.sh) --uninstall && rm -rf ~/.setup-and-keepup
```

The uninstall command removes every setup-and-keepup LaunchAgent plist along
with the helper scripts under `~/Library/Scripts/`. Reboot or log out and back
in to ensure macOS no longer starts the setup scripts automatically.
