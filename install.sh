#!/bin/sh
# install.sh - install the scripts from one Codegeist Devenv GitHub release.
#
# Inputs:
# - --bin-dir optionally replaces the default $HOME/.cgenv/bin destination.
# - --no-modify-path skips shell configuration changes.
# - The v0.1.1 GitHub release provides the ZIP and SHA256SUMS assets.
#
# Side effects:
# - Downloads release assets into a temporary directory.
# - Installs every validated scripts/ payload file with mode 0755.
# - Adds the default or selected binary directory to the user's shell config.
#
# Related files:
# - tools/build-release.sh
# - docs/tasks/T004_make_installed_launcher_shell_resolvable.md

set -eu

readonly RELEASE_VERSION=v0.1.1
readonly REPOSITORY=codegeist-ai/codegeist-devenv
readonly ARCHIVE_ROOT=codegeist-devenv-${RELEASE_VERSION}
readonly ARCHIVE_NAME=${ARCHIVE_ROOT}.zip
readonly RELEASE_URL=https://github.com/${REPOSITORY}/releases/download/${RELEASE_VERSION}

bin_dir=
default_bin_dir=
installer_complete=false
modify_path=true
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
	printf 'usage: install.sh [--bin-dir <path>] [--no-modify-path]\n'
}

cleanup() {
	if [ -n "$temp_dir" ] && [ -d "$temp_dir" ]; then
		rm -rf -- "$temp_dir" || true
	fi
}

finish() {
	status=$?
	trap - 0
	cleanup
	if [ "$installer_complete" != true ]; then
		log error install "status=failed reason=incomplete_installer_stream"
		exit 1
	fi
	exit "$status"
}

path_contains() {
	case ":${PATH:-}:" in
		*":$1:"*) return 0 ;;
		*) return 1 ;;
	esac
}

select_shell_config() {
	selected_config=
	case $1 in
		bash)
			set -- \
				"$HOME/.bashrc" \
				"$HOME/.bash_profile" \
				"$HOME/.profile"
			;;
		zsh)
			set -- \
				"${ZDOTDIR:-$HOME}/.zshrc" \
				"${ZDOTDIR:-$HOME}/.zshenv"
			;;
		fish)
			set -- "$xdg_config_home/fish/config.fish"
			;;
		ash)
			set -- "$HOME/.profile"
			;;
		sh)
			set -- "$HOME/.profile"
			;;
		*)
			return
			;;
	esac

	for config in "$@"; do
		if [ -f "$config" ]; then
			selected_config=$config
			return
		fi
	done
}

build_path_command() {
	if [ -n "$default_bin_dir" ] && [ "$bin_dir" = "$default_bin_dir" ]; then
		case $shell_name in
			fish) path_command='fish_add_path "$HOME/.cgenv/bin"' ;;
			*) path_command='export PATH="$HOME/.cgenv/bin:$PATH"' ;;
		esac
		return
	fi

	escaped_bin_dir=$(printf '%s' "$bin_dir" | sed "s/'/'\\\\''/g")
	case $shell_name in
		fish) path_command="fish_add_path '$escaped_bin_dir'" ;;
		*) path_command="export PATH='$escaped_bin_dir':\"\$PATH\"" ;;
	esac
}

print_manual_path() {
	log warning install_path \
		"status=manual shell=$shell_name destination=$bin_dir"
	printf 'Add cgenv to PATH manually:\n  %s\n' "$path_command" >&2
}

configure_path() {
	shell_path=${SHELL:-sh}
	shell_name=${shell_path##*/}
	[ -n "$shell_name" ] || shell_name=sh
	build_path_command

	if [ "$modify_path" = false ]; then
		if path_contains "$bin_dir"; then
			log info install_path \
				"status=active shell=$shell_name destination=$bin_dir"
		else
			print_manual_path
		fi
		return
	fi

	xdg_config_home=${XDG_CONFIG_HOME:-$HOME/.config}
	select_shell_config "$shell_name"
	if [ -z "$selected_config" ]; then
		print_manual_path
		return
	fi

	if grep -Fqx "$path_command" "$selected_config"; then
		path_status=present
	else
		grep_status=$?
		[ "$grep_status" -eq 1 ] \
			|| fail "shell_config_read_failed config=$selected_config"
		if [ -w "$selected_config" ]; then
			printf '\n# cgenv\n%s\n' "$path_command" >>"$selected_config"
			path_status=updated
		else
			print_manual_path
			return
		fi
	fi

	log info install_path \
		"status=$path_status shell=$shell_name config=$selected_config destination=$bin_dir"
	if path_contains "$bin_dir"; then
		log info install_path \
			"status=active shell=$shell_name destination=$bin_dir"
		return
	fi

	log info install_path \
		"status=activation_required shell=$shell_name config=$selected_config"
	case $shell_name in
		bash | zsh | fish)
			printf 'Activate cgenv in this shell with:\n  source "%s"\n' \
				"$selected_config" >&2
			;;
		*)
			printf 'Activate cgenv in this shell with:\n  . "%s"\n' \
				"$selected_config" >&2
			;;
	esac
}

trap finish 0
trap 'exit 1' HUP INT TERM

main() {
	last_argument=
	for argument in "$@"; do
		last_argument=$argument
	done
	[ "$last_argument" = __cgenv_installer_complete__ ] || return 1
	installer_complete=true

	while [ "$#" -gt 0 ]; do
		case $1 in
			__cgenv_installer_complete__)
				[ "$#" -eq 1 ] || fail invalid_completion_marker
				shift
			;;
			--bin-dir)
				[ "$#" -ge 2 ] || fail missing_bin_dir_value
				bin_dir=$2
				shift 2
				;;
			--no-modify-path)
				modify_path=false
				shift
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
	[ "$installer_complete" = true ] || fail incomplete_installer_stream

	for command in curl grep install mktemp rm sed sha256sum uname unzip; do
		command -v "$command" >/dev/null 2>&1 \
			|| fail "missing_command command=$command"
	done

	[ "$(uname -s)" = Linux ] || fail unsupported_platform

	if [ -z "$bin_dir" ]; then
		[ -n "${HOME:-}" ] || fail missing_home
		default_bin_dir=$HOME/.cgenv/bin
		bin_dir=$default_bin_dir
	elif [ -n "${HOME:-}" ]; then
		default_bin_dir=$HOME/.cgenv/bin
	fi
	[ -n "$bin_dir" ] || fail empty_bin_dir
	case $bin_dir in
		/*) ;;
		*) fail bin_dir_not_absolute ;;
	esac
	case $bin_dir in
		*:*) fail bin_dir_contains_path_separator ;;
	esac
	if [ "$modify_path" = true ]; then
		[ -n "${HOME:-}" ] || fail missing_home
	fi

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
	configure_path

	log info install \
		"status=completed version=$RELEASE_VERSION destination=$bin_dir scripts=$installed_count"
}

# The exit trap and final marker reject a stream that ends before this call.
main "$@" __cgenv_installer_complete__
