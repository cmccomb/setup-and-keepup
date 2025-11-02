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

	run env HOME="${TMP_HOME}" SETUP_REPO_URL="${REPO_ROOT}" bash "${REPO_ROOT}/agent.sh" --target-dir "${target_dir}" --profile work --schedule "15 6 * * 2"

	[ "$status" -eq 0 ]
	[ -d "${target_dir}/.git" ]
	[ -f "${target_dir}/build.sh" ]
	[ -f "${TMP_HOME}/Library/Scripts/run-setup-work.sh" ]
	[ -f "${TMP_HOME}/Library/LaunchAgents/com.cmccomb.setup.work.plist" ]
	[ -f "${TMP_HOME}/Library/Logs/run-setup-work.log" ] || true
	grep -q "<integer>15</integer>" "${TMP_HOME}/Library/LaunchAgents/com.cmccomb.setup.work.plist"
	grep -q "<integer>6</integer>" "${TMP_HOME}/Library/LaunchAgents/com.cmccomb.setup.work.plist"
}

@test "uninstall flag removes helper artifacts" {
        target_dir="${TMP_HOME}/mirror"

        run env HOME="${TMP_HOME}" SETUP_REPO_URL="${REPO_ROOT}" bash "${REPO_ROOT}/agent.sh" --target-dir "${target_dir}" --profile work --schedule "15 6 * * 2"
        [ "$status" -eq 0 ]

        [ -f "${TMP_HOME}/Library/Scripts/run-setup-work.sh" ]
        [ -f "${TMP_HOME}/Library/LaunchAgents/com.cmccomb.setup.work.plist" ]

        run env HOME="${TMP_HOME}" bash "${REPO_ROOT}/agent.sh" --uninstall
        [ "$status" -eq 0 ]
        [ ! -e "${TMP_HOME}/Library/Scripts/run-setup-work.sh" ]
        [ ! -e "${TMP_HOME}/Library/LaunchAgents/com.cmccomb.setup.work.plist" ]
}

@test "app store installations short-circuit in test mode" {
        stub_path="${REPO_ROOT}/stubs/installations/app_store/base"

        run zsh -c $'function heading(){ echo "HEADING:$1"; }
export IS_ICLOUD_SIGNED_IN=0
export SETUP_SKIP_APP_STORE_INSTALL=1
source "$1"' stub "${stub_path}"

        [ "$status" -eq 0 ]
        [[ "$output" == *"Test mode active; skipping App Store installations."* ]]
        [[ "$output" != *"mas install"* ]]
}

@test "work stack includes llama.cpp downloads" {
        run bash -c "cd \"${REPO_ROOT}\" && ./build.sh"
        [ "$status" -eq 0 ]

        run bash -c "cd \"${REPO_ROOT}\" && grep -F 'download_llamacpp_model \"ggml-org\" \"Qwen3-8B-GGUF\"' scripts/work.zsh"
        [ "$status" -eq 0 ]
}
