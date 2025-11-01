#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  TMP_HOME="$(mktemp -d)"
}

teardown() {
  if [[ -n "${TMP_HOME:-}" && -d "${TMP_HOME}" ]]; then
    rm -rf "${TMP_HOME}"
  fi
}

@test "help flag explains usage" {
  run bash "${REPO_ROOT}/agent.sh" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Options:"* ]]
}

@test "agent clones repository with overridden remote" {
  target_dir="${TMP_HOME}/mirror"

  run env HOME="${TMP_HOME}" SETUP_REPO_URL="${REPO_ROOT}" bash "${REPO_ROOT}/agent.sh" --target-dir "${target_dir}" --profile work --weekday 2 --hour 6 --minute 15

  [ "$status" -eq 0 ]
  [ -d "${target_dir}/.git" ]
  [ -f "${target_dir}/build.sh" ]
  [ -f "${TMP_HOME}/Library/Scripts/run-setup-work.sh" ]
  [ -f "${TMP_HOME}/Library/LaunchAgents/com.cmccomb.setup.work.plist" ]
  [ -f "${TMP_HOME}/Library/Logs/run-setup-work.log" ] || true
}
