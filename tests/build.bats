#!/usr/bin/env bats

setup() {
        REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
        cd "${REPO_ROOT}" || exit 1
}

@test "play stack excludes work-only packages" {
        run ./build.sh
        [ "$status" -eq 0 ]
        [ -f "scripts/play.zsh" ]

        run grep -F "jetbrains-toolbox" scripts/play.zsh
        [ "$status" -ne 0 ]

        run grep -F "microsoft-teams" scripts/play.zsh
        [ "$status" -ne 0 ]
}
