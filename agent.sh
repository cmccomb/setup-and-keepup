#!/usr/bin/env bash
#
# agent.sh — bootstrap and schedule the setup stacks.
#
# Usage:
#   ./agent.sh [--profile work|play] [--target-dir PATH] [--label LABEL]
#              [--weekday N] [--hour H] [--minute M]
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
WEEKDAY=1
HOUR=9
MINUTE=0

usage() {
  cat << 'USAGE'
Bootstrap the setup repository into a dot directory and install a LaunchAgent
that reruns the requested stack on a schedule.

Options:
  --profile <work|play>   Stack to execute on each run (default: work).
  --target-dir <path>     Where to mirror this repository (default: ~/.setup-and-keepup).
  --label <label>         Custom launchd label (default: derived from profile).
  --weekday <1-7>         Weekday number for StartCalendarInterval (default: 1 / Monday).
  --hour <0-23>           Hour for StartCalendarInterval (default: 9).
  --minute <0-59>         Minute for StartCalendarInterval (default: 0).
  -h, --help              Show this message.
USAGE
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
    --weekday)
      WEEKDAY="$2"
      shift 2
      ;;
    --hour)
      HOUR="$2"
      shift 2
      ;;
    --minute)
      MINUTE="$2"
      shift 2
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

case "$PROFILE" in
  work | play) ;;
  *)
    echo "Unsupported profile: ${PROFILE}. Expected 'work' or 'play'." >&2
    exit 1
    ;;
esac

if ! command -v git > /dev/null 2>&1; then
  echo "git is required but not installed." >&2
  exit 1
fi

DEFAULT_REMOTE_URL="https://github.com/cmccomb/setup.git"
SCRIPT_ROOT=""

if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
  if SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2> /dev/null && pwd)"; then
    if git -C "${SOURCE_DIR}" rev-parse --is-inside-work-tree > /dev/null 2>&1; then
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

cat << EOF > "${RUN_SCRIPT_PATH}"
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

cat << EOF > "${PLIST_PATH}"
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
    <key>StartCalendarInterval</key>
    <dict>
      <key>Weekday</key>
      <integer>${WEEKDAY}</integer>
      <key>Hour</key>
      <integer>${HOUR}</integer>
      <key>Minute</key>
      <integer>${MINUTE}</integer>
    </dict>
    <key>RunAtLoad</key>
    <true/>
  </dict>
</plist>
EOF

if command -v launchctl > /dev/null 2>&1; then
  launchctl unload "${PLIST_PATH}" 2> /dev/null || true
  launchctl load "${PLIST_PATH}"
fi

echo "LaunchAgent ${LABEL} configured to run ${PROFILE} stack weekly."
