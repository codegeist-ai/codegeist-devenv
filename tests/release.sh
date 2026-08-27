#!/usr/bin/env bash
# release.sh - verify release assets and the streamed Linux installer contract.
#
# Inputs:
# - Argument 1 optionally selects the release version; default: v0.1.0.
# - Argument 2 optionally selects the scripts/ Git ref; default: HEAD.
#
# Side effects:
# - Rebuilds dist/<version> through tools/build-release.sh.
# - Uses only disposable test homes and install destinations.
#
# Related files:
# - install.sh
# - tools/build-release.sh
# - .github/workflows/release.yml

set -Eeuo pipefail

if [[ $# -gt 2 ]]; then
	printf 'usage: release.sh [<version> [<git-ref>]]\n' >&2
	exit 2
fi

readonly SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
readonly REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
readonly VERSION=${1:-v0.1.0}
readonly REF=${2:-HEAD}
readonly ARCHIVE_ROOT=codegeist-devenv-${VERSION}
readonly ARCHIVE_NAME=${ARCHIVE_ROOT}.zip
readonly ASSET_DIR=$REPO_ROOT/dist/$VERSION

log() {
	local level=$1
	local event=$2
	shift 2
	printf 'level=%s event=%s %s\n' "$level" "$event" "$*" >&2
}

fail() {
	log error release_test "status=failed reason=$1"
	exit 1
}

temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/cgenv-release-test.XXXXXX")
cleanup() {
	rm -rf -- "$temp_dir"
}
trap cleanup EXIT

log info release_test "status=started version=$VERSION ref=$REF"
"$REPO_ROOT/tools/build-release.sh" "$VERSION" "$REF"

[[ -x "$ASSET_DIR/install.sh" ]] || fail installer_asset_missing
[[ -f "$ASSET_DIR/$ARCHIVE_NAME" ]] || fail archive_asset_missing
[[ -f "$ASSET_DIR/SHA256SUMS" ]] || fail checksum_asset_missing
asset_count=$(find "$ASSET_DIR" -mindepth 1 -maxdepth 1 -type f | wc -l)
[[ "$asset_count" -eq 3 ]] || fail unexpected_asset_count

(
	cd "$ASSET_DIR"
	sha256sum -c SHA256SUMS
) >/dev/null || fail published_checksum_invalid

unzip -Z1 "$ASSET_DIR/$ARCHIVE_NAME" >"$temp_dir/archive-list.txt"
grep --fixed-strings --line-regexp --quiet \
	"$ARCHIVE_ROOT/scripts/cgenv" "$temp_dir/archive-list.txt" \
	|| fail cgenv_missing_from_archive
if grep --fixed-strings --quiet 'install.sh' "$temp_dir/archive-list.txt"; then
	fail installer_present_in_archive
fi
while IFS= read -r entry; do
	[[ "$entry" == "$ARCHIVE_ROOT/" \
		|| "$entry" == "$ARCHIVE_ROOT/scripts/" \
		|| "$entry" =~ ^${ARCHIVE_ROOT}/scripts/[^/]+$ ]] \
		|| fail "unexpected_archive_entry entry=$entry"
done <"$temp_dir/archive-list.txt"

fake_bin=$temp_dir/fake-bin
mkdir -p "$fake_bin"
cat >"$fake_bin/curl" <<'EOF'
#!/bin/sh
set -eu

output=
url=
while [ "$#" -gt 0 ]; do
	case $1 in
		--output)
			output=$2
			shift 2
			;;
		--fail | --location | --silent | --show-error)
			shift
			;;
		*)
			url=$1
			shift
			;;
	esac
done

[ -n "$url" ]
asset_name=${url##*/}
if [ -n "${CGENV_TEST_CURL_URLS:-}" ]; then
	printf '%s\n' "$url" >>"$CGENV_TEST_CURL_URLS"
fi
if [ -n "$output" ]; then
	cp "$CGENV_TEST_ASSET_DIR/$asset_name" "$output"
else
	cat "$CGENV_TEST_ASSET_DIR/$asset_name"
fi
EOF
cat >"$fake_bin/code" <<'EOF'
#!/bin/sh
set -eu

: "${CGENV_TEST_CODE_ARGS:?}"
printf '<%s>\n' "$@" >"$CGENV_TEST_CODE_ARGS"
exit "${CGENV_TEST_CODE_EXIT:-0}"
EOF
chmod 0755 "$fake_bin/curl" "$fake_bin/code"

non_linux_bin=$temp_dir/non-linux-bin
mkdir -p "$non_linux_bin"
cat >"$non_linux_bin/uname" <<'EOF'
#!/bin/sh
printf 'Darwin\n'
EOF
chmod 0755 "$non_linux_bin/uname"
if HOME=$temp_dir/non-linux-home \
	PATH=$non_linux_bin:$PATH \
	sh -s <"$ASSET_DIR/install.sh" \
	>"$temp_dir/non-linux.log" 2>&1; then
	fail non_linux_platform_accepted
fi
grep --fixed-strings --quiet 'reason=unsupported_platform' \
	"$temp_dir/non-linux.log" \
	|| fail non_linux_failure_reason_missing

default_home=$temp_dir/default-home
mkdir -p "$default_home"
curl_urls=$temp_dir/curl-urls.txt
CGENV_TEST_ASSET_DIR=$ASSET_DIR \
	CGENV_TEST_CURL_URLS=$curl_urls \
	PATH=$fake_bin:$PATH \
	curl -fsSL \
		https://github.com/codegeist-ai/codegeist-devenv/releases/latest/download/install.sh \
	| CGENV_TEST_ASSET_DIR=$ASSET_DIR \
		CGENV_TEST_CURL_URLS=$curl_urls \
		HOME=$default_home \
		PATH=$fake_bin:$PATH \
		sh
default_cgenv=$default_home/.local/bin/cgenv
[[ -x "$default_cgenv" ]] || fail default_install_missing
[[ "$(stat -c '%a' "$default_cgenv")" == 755 ]] \
	|| fail default_install_mode_mismatch
mapfile -t requested_urls <"$curl_urls"
[[ ${#requested_urls[@]} -eq 3 \
	&& "${requested_urls[0]}" == 'https://github.com/codegeist-ai/codegeist-devenv/releases/latest/download/install.sh' \
	&& "${requested_urls[1]}" == "https://github.com/codegeist-ai/codegeist-devenv/releases/download/$VERSION/$ARCHIVE_NAME" \
	&& "${requested_urls[2]}" == "https://github.com/codegeist-ai/codegeist-devenv/releases/download/$VERSION/SHA256SUMS" ]] \
	|| fail installer_release_urls_mismatch

code_args=$temp_dir/code-args.txt
CGENV_TEST_CODE_ARGS=$code_args \
	PATH=$fake_bin:$PATH \
	"$default_cgenv" 'host alias' '/remote path with spaces'
mapfile -t actual_args <"$code_args"
[[ ${#actual_args[@]} -eq 3 \
	&& "${actual_args[0]}" == '<--remote>' \
	&& "${actual_args[1]}" == '<ssh-remote+host alias>' \
	&& "${actual_args[2]}" == '</remote path with spaces>' ]] \
	|| fail installed_launcher_arguments_mismatch

custom_bin=$temp_dir/custom-bin
CGENV_TEST_ASSET_DIR=$ASSET_DIR \
	HOME=$temp_dir/custom-home \
	PATH=$fake_bin:$PATH \
	sh -s -- --bin-dir "$custom_bin" <"$ASSET_DIR/install.sh"
[[ -x "$custom_bin/cgenv" ]] || fail custom_install_missing

private_bin=$temp_dir/private-bin
mkdir -m 0700 "$private_bin"
CGENV_TEST_ASSET_DIR=$ASSET_DIR \
	HOME=$temp_dir/private-home \
	PATH=$fake_bin:$PATH \
	sh -s -- --bin-dir "$private_bin" <"$ASSET_DIR/install.sh"
[[ "$(stat -c '%a' "$private_bin")" == 700 ]] \
	|| fail existing_destination_mode_changed

truncated_home=$temp_dir/truncated-home
mkdir -p "$truncated_home"
sed '$d' "$ASSET_DIR/install.sh" \
	| HOME=$truncated_home PATH=$fake_bin:$PATH sh
[[ ! -e "$truncated_home/.local/bin" ]] \
	|| fail truncated_stream_changed_destination

tampered_assets=$temp_dir/tampered-assets
mkdir -p "$tampered_assets"
cp "$ASSET_DIR/install.sh" "$ASSET_DIR/SHA256SUMS" \
	"$ASSET_DIR/$ARCHIVE_NAME" "$tampered_assets/"
printf 'tampered\n' >>"$tampered_assets/$ARCHIVE_NAME"
bad_home=$temp_dir/bad-home
mkdir -p "$bad_home"
if CGENV_TEST_ASSET_DIR=$tampered_assets \
	HOME=$bad_home \
	PATH=$fake_bin:$PATH \
	sh -s <"$ASSET_DIR/install.sh" \
	>"$temp_dir/checksum-failure.log" 2>&1; then
	fail checksum_mismatch_accepted
fi
[[ ! -e "$bad_home/.local/bin" ]] || fail checksum_failure_changed_destination
grep --fixed-strings --quiet 'reason=archive_checksum_mismatch' \
	"$temp_dir/checksum-failure.log" \
	|| fail checksum_failure_reason_missing

log info release_test \
	"status=passed version=$VERSION assets=3 installer=streamed"
