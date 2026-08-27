#!/usr/bin/env bash
# build-release.sh - build the three assets for one script-only release.
#
# Inputs:
# - Argument 1 is a normal SemVer tag such as v0.1.1.
# - Argument 2 optionally selects the Git ref for the scripts/ archive.
#
# Side effects:
# - Replaces dist/<version> after all assets have built successfully.
#
# Related files:
# - install.sh
# - .github/workflows/release.yml
# - docs/tasks/T004_make_installed_launcher_shell_resolvable.md

set -Eeuo pipefail

readonly SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
readonly REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

log() {
	local level=$1
	local event=$2
	shift 2
	printf 'level=%s event=%s %s\n' "$level" "$event" "$*" >&2
}

fail() {
	log error release_build "status=failed reason=$1"
	exit 1
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
	printf 'usage: build-release.sh <version> [<git-ref>]\n' >&2
	exit 2
fi

readonly VERSION=$1
readonly REF=${2:-HEAD}
readonly VERSION_PATTERN='^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'

[[ "$VERSION" =~ $VERSION_PATTERN ]] || fail invalid_version
git -C "$REPO_ROOT" rev-parse --verify --quiet "${REF}^{commit}" >/dev/null \
	|| fail invalid_git_ref

readonly ARCHIVE_ROOT=codegeist-devenv-${VERSION}
readonly ARCHIVE_NAME=${ARCHIVE_ROOT}.zip
readonly OUTPUT_ROOT=$REPO_ROOT/dist
readonly OUTPUT_DIR=$OUTPUT_ROOT/$VERSION

payload_count=0
while IFS=$'\t' read -r metadata path; do
	[[ -n "$path" ]] || continue
	read -r mode type object <<<"$metadata"
	[[ "$mode" == 100755 && "$type" == blob \
		&& "$path" =~ ^scripts/[^./][^/]*$ ]] \
		|| fail "invalid_scripts_entry path=$path mode=$mode type=$type"
	payload_count=$((payload_count + 1))
done < <(git -C "$REPO_ROOT" ls-tree -r "$REF" -- scripts)
((payload_count > 0)) || fail scripts_payload_empty

mkdir -p "$OUTPUT_ROOT"
temp_dir=$(mktemp -d "$OUTPUT_ROOT/.build-${VERSION}.XXXXXX")
cleanup() {
	rm -rf -- "$temp_dir"
}
trap cleanup EXIT

log info release_build \
	"status=started version=$VERSION ref=$REF scripts=$payload_count"

git -C "$REPO_ROOT" show "$REF:install.sh" >"$temp_dir/install.sh" \
	|| fail installer_missing_from_ref
grep --fixed-strings --line-regexp --quiet \
	"readonly RELEASE_VERSION=$VERSION" "$temp_dir/install.sh" \
	|| fail installer_version_mismatch
git -C "$REPO_ROOT" archive \
	--format=zip \
	--prefix="$ARCHIVE_ROOT/" \
	--output="$temp_dir/$ARCHIVE_NAME" \
	"$REF" scripts
(
	cd "$temp_dir"
	sha256sum "$ARCHIVE_NAME" >SHA256SUMS
)

rm -rf -- "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"
install -m 0755 "$temp_dir/install.sh" "$OUTPUT_DIR/install.sh"
install -m 0644 "$temp_dir/$ARCHIVE_NAME" "$OUTPUT_DIR/$ARCHIVE_NAME"
install -m 0644 "$temp_dir/SHA256SUMS" "$OUTPUT_DIR/SHA256SUMS"

log info release_build \
	"status=completed version=$VERSION output=$OUTPUT_DIR assets=3"
