#!/usr/bin/env bash
# release.sh - verify release assets and the streamed Linux installer contract.
#
# Inputs:
# - Argument 1 optionally selects the release version; default: v0.1.1.
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
readonly VERSION=${1:-v0.1.1}
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
cat >"$fake_bin/sudo" <<'EOF'
#!/bin/sh
printf 'installer invoked sudo\n' >&2
exit 97
EOF
chmod 0755 "$fake_bin/curl" "$fake_bin/code" "$fake_bin/sudo"
readonly TEST_PATH=$fake_bin:/usr/bin:/bin

non_linux_bin=$temp_dir/non-linux-bin
mkdir -p "$non_linux_bin"
cat >"$non_linux_bin/uname" <<'EOF'
#!/bin/sh
printf 'Darwin\n'
EOF
chmod 0755 "$non_linux_bin/uname"
if HOME=$temp_dir/non-linux-home \
	PATH=$non_linux_bin:$TEST_PATH \
	sh -s <"$ASSET_DIR/install.sh" \
	>"$temp_dir/non-linux.log" 2>&1; then
	fail non_linux_platform_accepted
fi
grep --fixed-strings --quiet 'reason=unsupported_platform' \
	"$temp_dir/non-linux.log" \
	|| fail non_linux_failure_reason_missing

default_home=$temp_dir/default-home
mkdir -p "$default_home"
: >"$default_home/.bashrc"
if HOME=$default_home PATH=$TEST_PATH sh -c \
	'command -v cgenv >/dev/null 2>&1'; then
	fail cgenv_present_before_install
fi
curl_urls=$temp_dir/curl-urls.txt
default_install_log=$temp_dir/default-install.log
CGENV_TEST_ASSET_DIR=$ASSET_DIR \
	CGENV_TEST_CURL_URLS=$curl_urls \
	PATH=$TEST_PATH \
	curl -fsSL \
		https://github.com/codegeist-ai/codegeist-devenv/releases/latest/download/install.sh \
	| CGENV_TEST_ASSET_DIR=$ASSET_DIR \
		CGENV_TEST_CURL_URLS=$curl_urls \
		HOME=$default_home \
		PATH=$TEST_PATH \
		SHELL=/bin/bash \
		sh >"$default_install_log" 2>&1
default_cgenv=$default_home/.cgenv/bin/cgenv
[[ -x "$default_cgenv" ]] || fail default_install_missing
[[ "$(stat -c '%a' "$default_cgenv")" == 755 ]] \
	|| fail default_install_mode_mismatch
readonly DEFAULT_PATH_COMMAND='export PATH="$HOME/.cgenv/bin:$PATH"'
grep --fixed-strings --line-regexp --quiet \
	"$DEFAULT_PATH_COMMAND" "$default_home/.bashrc" \
	|| fail default_path_command_missing
grep --fixed-strings --quiet \
	"event=install_path status=updated shell=bash config=$default_home/.bashrc" \
	"$default_install_log" \
	|| fail default_path_update_log_missing
mapfile -t requested_urls <"$curl_urls"
[[ ${#requested_urls[@]} -eq 3 \
	&& "${requested_urls[0]}" == 'https://github.com/codegeist-ai/codegeist-devenv/releases/latest/download/install.sh' \
	&& "${requested_urls[1]}" == "https://github.com/codegeist-ai/codegeist-devenv/releases/download/$VERSION/$ARCHIVE_NAME" \
	&& "${requested_urls[2]}" == "https://github.com/codegeist-ai/codegeist-devenv/releases/download/$VERSION/SHA256SUMS" ]] \
	|| fail installer_release_urls_mismatch

code_args=$temp_dir/code-args.txt
if HOME=$default_home PATH=$TEST_PATH sh -c \
	'command -v cgenv >/dev/null 2>&1'; then
	fail cgenv_resolved_before_shell_activation
fi
resolved_cgenv=$(
	CGENV_TEST_CODE_ARGS=$code_args \
		HOME=$default_home \
		PATH=$TEST_PATH \
		bash --noprofile --norc -c \
		'. "$HOME/.bashrc"
		command -v cgenv
		cgenv "host alias" "/remote path with spaces"'
)
[[ "$resolved_cgenv" == "$default_cgenv" ]] \
	|| fail "installed_command_resolution_mismatch actual=$resolved_cgenv"
mapfile -t actual_args <"$code_args"
[[ ${#actual_args[@]} -eq 3 \
	&& "${actual_args[0]}" == '<--remote>' \
	&& "${actual_args[1]}" == '<ssh-remote+host alias>' \
	&& "${actual_args[2]}" == '</remote path with spaces>' ]] \
	|| fail installed_launcher_arguments_mismatch
log info install_command_smoke \
	"status=passed command=cgenv resolved=$resolved_cgenv"

HOME=$default_home \
	PATH=$TEST_PATH \
	SHELL=/bin/bash \
	CGENV_TEST_ASSET_DIR=$ASSET_DIR \
	sh -s <"$ASSET_DIR/install.sh" \
	>"$temp_dir/repeated-install.log" 2>&1
path_command_count=$(grep --fixed-strings --line-regexp --count \
	"$DEFAULT_PATH_COMMAND" "$default_home/.bashrc")
[[ "$path_command_count" -eq 1 ]] || fail duplicate_path_command
grep --fixed-strings --quiet \
	"event=install_path status=present shell=bash config=$default_home/.bashrc" \
	"$temp_dir/repeated-install.log" \
	|| fail existing_path_command_not_detected

zsh_home=$temp_dir/zsh-home
mkdir -p "$zsh_home"
: >"$zsh_home/.zshrc"
HOME=$zsh_home \
	PATH=$TEST_PATH \
	SHELL=/bin/zsh \
	CGENV_TEST_ASSET_DIR=$ASSET_DIR \
	sh -s <"$ASSET_DIR/install.sh" \
	>"$temp_dir/zsh-install.log" 2>&1
grep --fixed-strings --line-regexp --quiet \
	"$DEFAULT_PATH_COMMAND" "$zsh_home/.zshrc" \
	|| fail zsh_path_command_missing
grep --fixed-strings --quiet \
	"event=install_path status=updated shell=zsh config=$zsh_home/.zshrc" \
	"$temp_dir/zsh-install.log" \
	|| fail zsh_path_update_log_missing

active_home=$temp_dir/active-home
active_bin=$active_home/.cgenv/bin
mkdir -p "$active_home"
: >"$active_home/.bashrc"
HOME=$active_home \
	PATH=$active_bin:$TEST_PATH \
	SHELL=/bin/bash \
	CGENV_TEST_ASSET_DIR=$ASSET_DIR \
	sh -s <"$ASSET_DIR/install.sh" \
	>"$temp_dir/active-path-install.log" 2>&1
grep --fixed-strings --line-regexp --quiet \
	"$DEFAULT_PATH_COMMAND" "$active_home/.bashrc" \
	|| fail active_path_not_persisted
grep --fixed-strings --quiet \
	"event=install_path status=active shell=bash destination=$active_bin" \
	"$temp_dir/active-path-install.log" \
	|| fail active_path_status_missing

custom_bin=$temp_dir/custom-bin
custom_home=$temp_dir/custom-home
mkdir -p "$custom_home"
: >"$custom_home/.bashrc"
CGENV_TEST_ASSET_DIR=$ASSET_DIR \
	HOME=$custom_home \
	PATH=$TEST_PATH \
	SHELL=/bin/bash \
	sh -s -- --bin-dir "$custom_bin" <"$ASSET_DIR/install.sh"
[[ -x "$custom_bin/cgenv" ]] || fail custom_install_missing
custom_path_command="export PATH='$custom_bin':\"\$PATH\""
grep --fixed-strings --line-regexp --quiet \
	"$custom_path_command" "$custom_home/.bashrc" \
	|| fail custom_path_command_missing
resolved_custom_cgenv=$(
	HOME=$custom_home PATH=$TEST_PATH bash --noprofile --norc -c \
		'. "$HOME/.bashrc"; command -v cgenv'
)
[[ "$resolved_custom_cgenv" == "$custom_bin/cgenv" ]] \
	|| fail custom_command_resolution_mismatch

no_modify_bin=$temp_dir/no-modify-bin
no_modify_home=$temp_dir/no-modify-home
mkdir -p "$no_modify_home"
printf '# existing config\n' >"$no_modify_home/.bashrc"
CGENV_TEST_ASSET_DIR=$ASSET_DIR \
	HOME=$no_modify_home \
	PATH=$TEST_PATH \
	SHELL=/bin/bash \
	sh -s -- --bin-dir "$no_modify_bin" --no-modify-path \
	<"$ASSET_DIR/install.sh"
[[ -x "$no_modify_bin/cgenv" ]] || fail no_modify_path_install_missing
[[ "$(<"$no_modify_home/.bashrc")" == '# existing config' ]] \
	|| fail no_modify_path_changed_config

no_home_bin=$temp_dir/no-home-bin
env -u HOME \
	CGENV_TEST_ASSET_DIR=$ASSET_DIR \
	PATH=$TEST_PATH \
	sh -s -- --bin-dir "$no_home_bin" --no-modify-path \
	<"$ASSET_DIR/install.sh"
[[ -x "$no_home_bin/cgenv" ]] || fail no_home_custom_install_missing

if HOME=$temp_dir/invalid-home \
	PATH=$TEST_PATH \
	sh -s -- --bin-dir relative/bin --no-modify-path \
	<"$ASSET_DIR/install.sh" >"$temp_dir/relative-bin.log" 2>&1; then
	fail relative_bin_dir_accepted
fi
grep --fixed-strings --quiet 'reason=bin_dir_not_absolute' \
	"$temp_dir/relative-bin.log" || fail relative_bin_dir_reason_missing

if HOME=$temp_dir/invalid-home \
	PATH=$TEST_PATH \
	sh -s -- --bin-dir '/tmp/invalid:path' --no-modify-path \
	<"$ASSET_DIR/install.sh" >"$temp_dir/colon-bin.log" 2>&1; then
	fail colon_bin_dir_accepted
fi
grep --fixed-strings --quiet 'reason=bin_dir_contains_path_separator' \
	"$temp_dir/colon-bin.log" || fail colon_bin_dir_reason_missing

private_bin=$temp_dir/private-bin
mkdir -m 0700 "$private_bin"
CGENV_TEST_ASSET_DIR=$ASSET_DIR \
	HOME=$temp_dir/private-home \
	PATH=$TEST_PATH \
	sh -s -- --bin-dir "$private_bin" <"$ASSET_DIR/install.sh"
[[ "$(stat -c '%a' "$private_bin")" == 700 ]] \
	|| fail existing_destination_mode_changed

for truncation in missing_call missing_marker; do
	truncated_home=$temp_dir/truncated-$truncation-home
	truncated_log=$temp_dir/truncated-$truncation.log
	mkdir -p "$truncated_home"
	: >"$truncated_home/.bashrc"
	case $truncation in
		missing_call)
			if sed '$d' "$ASSET_DIR/install.sh" \
				| HOME=$truncated_home PATH=$TEST_PATH SHELL=/bin/bash sh \
				>"$truncated_log" 2>&1; then
				fail "truncated_stream_accepted variant=$truncation"
			fi
			;;
		missing_marker)
			if sed '$s/ __cgenv_installer_complete__$//' \
				"$ASSET_DIR/install.sh" \
				| HOME=$truncated_home PATH=$TEST_PATH SHELL=/bin/bash sh \
				>"$truncated_log" 2>&1; then
				fail "truncated_stream_accepted variant=$truncation"
			fi
			;;
	esac
	[[ ! -e "$truncated_home/.cgenv" ]] \
		|| fail "truncated_stream_changed_destination variant=$truncation"
	[[ ! -s "$truncated_home/.bashrc" ]] \
		|| fail "truncated_stream_changed_shell_config variant=$truncation"
	grep --fixed-strings --quiet 'reason=incomplete_installer_stream' \
		"$truncated_log" \
		|| fail "truncated_stream_reason_missing variant=$truncation"
done

tampered_assets=$temp_dir/tampered-assets
mkdir -p "$tampered_assets"
cp "$ASSET_DIR/install.sh" "$ASSET_DIR/SHA256SUMS" \
	"$ASSET_DIR/$ARCHIVE_NAME" "$tampered_assets/"
printf 'tampered\n' >>"$tampered_assets/$ARCHIVE_NAME"
bad_home=$temp_dir/bad-home
mkdir -p "$bad_home"
if CGENV_TEST_ASSET_DIR=$tampered_assets \
	HOME=$bad_home \
	PATH=$TEST_PATH \
	sh -s <"$ASSET_DIR/install.sh" \
	>"$temp_dir/checksum-failure.log" 2>&1; then
	fail checksum_mismatch_accepted
fi
[[ ! -e "$bad_home/.cgenv" ]] || fail checksum_failure_changed_destination
grep --fixed-strings --quiet 'reason=archive_checksum_mismatch' \
	"$temp_dir/checksum-failure.log" \
	|| fail checksum_failure_reason_missing

log info release_test \
	"status=passed version=$VERSION assets=3 installer=streamed"
