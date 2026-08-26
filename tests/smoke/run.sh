#!/usr/bin/env bash
# run.sh - orchestrate and collect the graphical Remote - SSH smoke test.
#
# Inputs:
# - CGENV_SMOKE_TIMEOUT_SECONDS optionally overrides the client startup timeout.
#
# Side effects:
# - Builds two local Docker targets and starts a disposable Compose project.
# - Replaces the previous smoke-test result directory.
# - Copies diagnostics before removing containers, the network, and key volume.
#
# Related files:
# - tests/smoke/compose.yml
# - tests/smoke/client.sh
# - Taskfile.yml

set -Eeuo pipefail

readonly SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
readonly REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
readonly RESULTS_DIR=$REPO_ROOT/.test-results/cgenv-smoke
readonly PROJECT_NAME=cgenv-smoke
readonly -a COMPOSE=(
	docker compose
	--project-name "$PROJECT_NAME"
	--file "$SCRIPT_DIR/compose.yml"
)

export COMPOSE_MENU=0

log() {
	local level=$1
	local event=$2
	shift 2
	printf 'level=%s event=%s %s\n' "$level" "$event" "$*" >&2
}

cleanup() {
	local status=$?

	trap - EXIT
	log info smoke_cleanup "status=started project=$PROJECT_NAME"
	"${COMPOSE[@]}" down --volumes --remove-orphans >/dev/null 2>&1 \
		|| log warning smoke_cleanup 'status=failed'
	log info smoke_cleanup "status=completed project=$PROJECT_NAME"
	exit "$status"
}

copy_artifacts() {
	local source=$1
	local target=$2

	mkdir -p "$target"
	if ! "${COMPOSE[@]}" cp "$source" "$target" >/dev/null 2>&1; then
		log warning artifact_copy "status=skipped source=$source"
	fi
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

rm -rf "$RESULTS_DIR"
mkdir -p "$RESULTS_DIR"

# Remove stale resources from an interrupted run before creating fresh keys.
"${COMPOSE[@]}" down --volumes --remove-orphans >/dev/null 2>&1 || true

log info smoke_run \
	"status=started project=$PROJECT_NAME results=$RESULTS_DIR"

set +e
"${COMPOSE[@]}" up --build --abort-on-container-exit \
	--exit-code-from client --remove-orphans 2>&1 \
	| tee "$RESULTS_DIR/compose-up.log"
smoke_status=${PIPESTATUS[0]}
set -e

"${COMPOSE[@]}" logs --no-color \
	>"$RESULTS_DIR/compose.log" 2>&1 || true
copy_artifacts \
	client:/tmp/cgenv-smoke-results/. "$RESULTS_DIR/client"
copy_artifacts \
	client:/home/vscode/.config/Code/logs/. "$RESULTS_DIR/client/vscode-logs"
copy_artifacts \
	ssh-server:/home/smoke/.vscode-server/data/logs/. \
	"$RESULTS_DIR/server/vscode-server-logs"

if [[ $smoke_status -eq 0 ]] \
	&& ! grep --fixed-strings --line-regexp --quiet \
		'status=passed' "$RESULTS_DIR/client/result.env"; then
	log error smoke_run 'status=failed reason=missing_client_success_result'
	smoke_status=1
fi
if [[ $smoke_status -eq 0 && ! -s "$RESULTS_DIR/client/vscode.png" ]]; then
	log error smoke_run 'status=failed reason=missing_screenshot'
	smoke_status=1
fi

if [[ $smoke_status -eq 0 ]]; then
	log info smoke_run "status=passed results=$RESULTS_DIR"
else
	log error smoke_run \
		"status=failed exit_code=$smoke_status results=$RESULTS_DIR"
fi

exit "$smoke_status"
