#!/usr/bin/env bash
#
# agent.sh — bootstrap and auto-run the setup stacks.
#
# Usage:
#   ./agent.sh [--profile work|play] [--target-dir PATH] [--label LABEL]
#              [--uninstall]
#
# Environment:
#   SETUP_REPO_URL     Override the repository URL to sync from.
#   SETUP_REPO_BRANCH  Override the branch to sync when cloning.
#
# Exit codes:
#   0  Success.
#   1  Misconfiguration or missing prerequisites.
#
set -euo pipefail

PROFILE="work"
TARGET_DIR="${HOME}/.setup-and-keepup"
CUSTOM_LABEL=""
UNINSTALL=false

usage() {
	cat <<'USAGE'
Bootstrap the setup repository into a dot directory and install a LaunchAgent
that reruns the requested stack at login and on boot.

Options:
  --profile <work|play>   Stack to execute on each run (default: work).
  --target-dir <path>     Where to mirror this repository (default: ~/.setup-and-keepup).
  --label <label>         Custom launchd label (default: derived from profile).
  --uninstall             Remove setup-and-keepup LaunchAgents and helper scripts.
  -h, --help              Show this message.
USAGE
}

uninstall_agents() {
        local removed=false

	if [[ -d "${HOME}/Library/LaunchAgents" ]]; then
		while IFS= read -r plist_path; do
			removed=true
			if command -v launchctl >/dev/null 2>&1; then
				launchctl unload "${plist_path}" 2>/dev/null || true
			fi
			rm -f "${plist_path}"
		done < <(find "${HOME}/Library/LaunchAgents" -maxdepth 1 -type f -name 'com.cmccomb.setup.*.plist' -print)
	fi

	if [[ -d "${HOME}/Library/Scripts" ]]; then
		while IFS= read -r script_path; do
			removed=true
			rm -f "${script_path}"
		done < <(find "${HOME}/Library/Scripts" -maxdepth 1 -type f -name 'run-setup-*.sh' -print)
	fi

        if [[ "${removed}" == false ]]; then
                echo "No setup-and-keepup LaunchAgents were found."
        else
                echo "Removed setup-and-keepup LaunchAgents and helper scripts."
        fi
}

# reset_generated_scripts removes any tracked copies of the generated stack scripts
# so git pulls do not fail when those files drift from the committed state. It
# only touches the generated scripts and leaves other local changes intact.
reset_generated_scripts() {
        if [[ ! -d "${TARGET_DIR}/.git" ]]; then
                return 0
        fi

        git -C "${TARGET_DIR}" reset --mixed HEAD -- scripts/play.zsh scripts/work.zsh \
                >/dev/null 2>&1 || true
        git -C "${TARGET_DIR}" rm -f --cached --ignore-unmatch scripts/play.zsh scripts/work.zsh \
                >/dev/null 2>&1 || true
        rm -rf "${TARGET_DIR}/scripts"
        git -C "${TARGET_DIR}" clean -f -d -- scripts >/dev/null 2>&1 || true
}

while (($# > 0)); do
	case "$1" in
	--profile)
		PROFILE="$2"
		shift 2
		;;
	--target-dir)
		TARGET_DIR="$2"
		shift 2
		;;
        --label)
                CUSTOM_LABEL="$2"
                shift 2
                ;;
        --uninstall)
                UNINSTALL=true
                shift
		;;
        -h | --help)
                usage
                exit 0
                ;;
        *)
                echo "Unknown option: $1" >&2
                usage
                exit 1
                ;;
        esac
done

if [[ "${UNINSTALL}" == true ]]; then
        uninstall_agents
        exit 0
fi

case "$PROFILE" in
work | play) ;;
*)
        echo "Unsupported profile: ${PROFILE}. Expected 'work' or 'play'." >&2
        exit 1
        ;;
esac

if ! command -v git >/dev/null 2>&1; then
        echo "git is required but not installed." >&2
        exit 1
fi

DEFAULT_REMOTE_URL="https://github.com/cmccomb/setup-and-keepup.git"
SCRIPT_ROOT=""

if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
	if SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"; then
		if git -C "${SOURCE_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
			SCRIPT_ROOT="${SOURCE_DIR}"
		fi
	fi
fi

if [[ -n "${SCRIPT_ROOT}" ]]; then
	BRANCH="$(git -C "${SCRIPT_ROOT}" rev-parse --abbrev-ref HEAD)"
	if [[ "${BRANCH}" == "HEAD" ]]; then
		BRANCH=""
	fi
	REMOTE_URL="${SETUP_REPO_URL:-$(git -C "${SCRIPT_ROOT}" config --get remote.origin.url || true)}"
else
	BRANCH="${SETUP_REPO_BRANCH:-}"
	REMOTE_URL="${SETUP_REPO_URL:-${DEFAULT_REMOTE_URL}}"
fi

if [[ -z "${REMOTE_URL}" ]]; then
	echo "Unable to determine the remote URL for this repository." >&2
	echo "Specify one with SETUP_REPO_URL." >&2
	exit 1
fi

TARGET_PARENT="${TARGET_DIR%/*}"
if [[ "${TARGET_PARENT}" != "${TARGET_DIR}" && -n "${TARGET_PARENT}" ]]; then
	mkdir -p "${TARGET_PARENT}"
fi

if [[ -d "${TARGET_DIR}/.git" ]]; then
        git -C "${TARGET_DIR}" remote set-url origin "${REMOTE_URL}"
        reset_generated_scripts
        git -C "${TARGET_DIR}" fetch origin
        if [[ -n "${BRANCH}" ]]; then
                git -C "${TARGET_DIR}" checkout "${BRANCH}" || true
		git -C "${TARGET_DIR}" pull --ff-only origin "${BRANCH}" || git -C "${TARGET_DIR}" pull origin "${BRANCH}"
	else
		git -C "${TARGET_DIR}" pull --ff-only || git -C "${TARGET_DIR}" pull
	fi
else
	rm -rf "${TARGET_DIR}"
	if [[ -n "${BRANCH}" ]]; then
		git clone --branch "${BRANCH}" "${REMOTE_URL}" "${TARGET_DIR}" || git clone "${REMOTE_URL}" "${TARGET_DIR}"
	else
		git clone "${REMOTE_URL}" "${TARGET_DIR}"
	fi
fi

if [[ ! -x "${TARGET_DIR}/build.sh" ]]; then
	echo "Expected build.sh in ${TARGET_DIR}." >&2
	exit 1
fi

"${TARGET_DIR}/build.sh"

SCRIPTS_DIR="${HOME}/Library/Scripts"
RUN_SCRIPT_PATH="${SCRIPTS_DIR}/run-setup-${PROFILE}.sh"
LAUNCH_AGENTS_DIR="${HOME}/Library/LaunchAgents"
LABEL="${CUSTOM_LABEL:-com.cmccomb.setup.${PROFILE}}"
PLIST_PATH="${LAUNCH_AGENTS_DIR}/${LABEL}.plist"

mkdir -p "${SCRIPTS_DIR}" "${LAUNCH_AGENTS_DIR}"
mkdir -p "${HOME}/Library/Logs"

cat <<EOF >"${RUN_SCRIPT_PATH}"
#!/usr/bin/env zsh
set -euo pipefail

PROFILE="${PROFILE}"
REPO_ROOT="${TARGET_DIR}"

if [[ ! -d "\${REPO_ROOT}" ]]; then
  echo "Missing repository at \${REPO_ROOT}." >&2
  exit 1
fi

if command -v git >/dev/null 2>&1; then
  (
    cd "\${REPO_ROOT}" || exit 1
    git restore --worktree --staged scripts/play.zsh scripts/work.zsh >/dev/null 2>&1 || true
    git clean -f -- scripts/play.zsh scripts/work.zsh >/dev/null 2>&1 || true
    git fetch --quiet --all || true
    git pull --quiet --ff-only || git pull --quiet || true
    if [[ -x ./build.sh ]]; then
      ./build.sh >/dev/null 2>&1 || ./build.sh
    fi
  )
fi

export SETUP_REPO_ROOT="\${REPO_ROOT}"
STACK_PATH="\${REPO_ROOT}/scripts/\${PROFILE}.zsh"

if [[ ! -f "\${STACK_PATH}" ]]; then
  echo "Unable to locate stack script at \${STACK_PATH}." >&2
  exit 1
fi

exec zsh "\${STACK_PATH}"
EOF

chmod +x "${RUN_SCRIPT_PATH}"

cat <<EOF >"${PLIST_PATH}"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>${LABEL}</string>
    <key>ProgramArguments</key>
    <array>
      <string>/bin/zsh</string>
      <string>-lc</string>
      <string>${RUN_SCRIPT_PATH}</string>
    </array>
    <key>StandardOutPath</key>
    <string>${HOME}/Library/Logs/${LABEL}.log</string>
    <key>StandardErrorPath</key>
    <string>${HOME}/Library/Logs/${LABEL}.log</string>
EOF

{
        printf "    <key>RunAtLoad</key>\n"
        printf "    <true/>\n"
        printf "    <key>KeepAlive</key>\n"
        printf "    <true/>\n"
        printf "  </dict>\n"
        printf "</plist>\n"
} >>"${PLIST_PATH}"

if command -v launchctl >/dev/null 2>&1; then
        launchctl unload "${PLIST_PATH}" 2>/dev/null || true
        launchctl load "${PLIST_PATH}"
fi

echo "LaunchAgent ${LABEL} configured to run ${PROFILE} stack at login and on boot via RunAtLoad."
