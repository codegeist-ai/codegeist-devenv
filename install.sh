#!/bin/sh
# install.sh - install the scripts from one Codegeist Devenv GitHub release.
#
# Inputs:
# - --bin-dir optionally replaces the default $HOME/.local/bin destination.
# - The v0.1.0 GitHub release provides the ZIP and SHA256SUMS assets.
#
# Side effects:
# - Downloads release assets into a temporary directory.
# - Installs every validated scripts/ payload file with mode 0755.
#
# Related files:
# - tools/build-release.sh
# - docs/tasks/T003_publish_installable_script_release.md

set -eu

readonly RELEASE_VERSION=v0.1.0
readonly REPOSITORY=codegeist-ai/codegeist-devenv
readonly ARCHIVE_ROOT=codegeist-devenv-${RELEASE_VERSION}
readonly ARCHIVE_NAME=${ARCHIVE_ROOT}.zip
readonly RELEASE_URL=https://github.com/${REPOSITORY}/releases/download/${RELEASE_VERSION}

bin_dir=
temp_dir=

log() {
	level=$1
	event=$2
	shift 2
	printf 'level=%s event=%s %s\n' "$level" "$event" "$*" >&2
}

fail() {
	log error install "status=failed reason=$1"
	exit 1
}

usage() {
	printf 'usage: install.sh [--bin-dir <path>]\n'
}

cleanup() {
	if [ -n "$temp_dir" ] && [ -d "$temp_dir" ]; then
		rm -rf -- "$temp_dir" || true
	fi
}

trap cleanup 0
trap 'exit 1' HUP INT TERM

main() {
	while [ "$#" -gt 0 ]; do
		case $1 in
			--bin-dir)
				[ "$#" -ge 2 ] || fail missing_bin_dir_value
				bin_dir=$2
				shift 2
				;;
			--help)
				usage
				exit 0
				;;
			*)
				usage >&2
				fail unknown_argument
				;;
		esac
	done

	for command in curl install mktemp rm sha256sum uname unzip; do
		command -v "$command" >/dev/null 2>&1 \
			|| fail "missing_command command=$command"
	done

	[ "$(uname -s)" = Linux ] || fail unsupported_platform

	if [ -z "$bin_dir" ]; then
		[ -n "${HOME:-}" ] || fail missing_home
		bin_dir=$HOME/.local/bin
	fi
	[ -n "$bin_dir" ] || fail empty_bin_dir

	log info install \
		"status=started version=$RELEASE_VERSION destination=$bin_dir"

	temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/cgenv-install.XXXXXX")

	curl --fail --location --silent --show-error \
		--output "$temp_dir/$ARCHIVE_NAME" \
		"$RELEASE_URL/$ARCHIVE_NAME" \
		|| fail archive_download_failed
	curl --fail --location --silent --show-error \
		--output "$temp_dir/SHA256SUMS" \
		"$RELEASE_URL/SHA256SUMS" \
		|| fail checksum_download_failed
	log info install_download \
		"status=completed version=$RELEASE_VERSION archive=$ARCHIVE_NAME"

	(
		cd "$temp_dir"
		sha256sum -c SHA256SUMS >/dev/null 2>&1
	) || fail archive_checksum_mismatch
	log info install_checksum "status=passed archive=$ARCHIVE_NAME"

	unzip -Z1 "$temp_dir/$ARCHIVE_NAME" >"$temp_dir/archive-list.txt" \
		|| fail archive_inventory_failed
	archive_payload_count=0
	while IFS= read -r entry; do
		case $entry in
			"$ARCHIVE_ROOT/" | "$ARCHIVE_ROOT/scripts/")
				;;
			"$ARCHIVE_ROOT/scripts/"*)
				payload_name=${entry#"$ARCHIVE_ROOT/scripts/"}
				case $payload_name in
					'' | .* | */*) fail invalid_archive_layout ;;
				esac
				archive_payload_count=$((archive_payload_count + 1))
				;;
			*)
				fail invalid_archive_layout
				;;
		esac
	done <"$temp_dir/archive-list.txt"
	[ "$archive_payload_count" -gt 0 ] || fail scripts_payload_empty

	unzip -q "$temp_dir/$ARCHIVE_NAME" -d "$temp_dir/extracted" \
		|| fail archive_extract_failed
	payload_dir=$temp_dir/extracted/$ARCHIVE_ROOT/scripts
	[ -d "$payload_dir" ] || fail scripts_directory_missing

	set -- "$payload_dir"/*
	[ -e "$1" ] || fail scripts_payload_empty
	for payload in "$@"; do
		[ -f "$payload" ] && [ ! -L "$payload" ] \
			|| fail invalid_scripts_payload
	done

	if [ ! -d "$bin_dir" ]; then
		install -d -m 0755 -- "$bin_dir"
	fi
	installed_count=0
	for payload in "$@"; do
		install -m 0755 -- "$payload" "$bin_dir/${payload##*/}"
		installed_count=$((installed_count + 1))
	done

	log info install \
		"status=completed version=$RELEASE_VERSION destination=$bin_dir scripts=$installed_count"
}

# Keep this call last so a truncated curl | sh stream cannot install anything.
main "$@"
