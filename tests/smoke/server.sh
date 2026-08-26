#!/usr/bin/env bash
# server.sh - prepare the disposable Remote - SSH target and run sshd.
#
# Inputs:
# - /run/cgenv-smoke-keys is a Compose volume shared read-only with the client.
#
# Side effects:
# - Generates fresh client and host SSH keys for this Compose run.
# - Authorizes the generated client key for the unprivileged smoke user.
# - Starts sshd in the foreground; VS Code later installs its server in the
#   smoke user's home directory.
#
# Related files:
# - tests/smoke/compose.yml
# - tests/smoke/client.sh

set -Eeuo pipefail

readonly KEY_DIR=/run/cgenv-smoke-keys
readonly SMOKE_USER=smoke
readonly SMOKE_HOME=/home/smoke

log() {
	local event=$1
	shift
	printf 'level=info event=%s %s\n' "$event" "$*" >&2
}

log server_setup 'status=started user=smoke'

install -d -m 0700 -o "$SMOKE_USER" -g "$SMOKE_USER" "$KEY_DIR"
rm -f "$KEY_DIR/id_ed25519" "$KEY_DIR/id_ed25519.pub"
ssh-keygen -q -t ed25519 -N '' -C cgenv-smoke \
	-f "$KEY_DIR/id_ed25519"
chown "$SMOKE_USER:$SMOKE_USER" \
	"$KEY_DIR/id_ed25519" "$KEY_DIR/id_ed25519.pub"
chmod 0600 "$KEY_DIR/id_ed25519"
chmod 0644 "$KEY_DIR/id_ed25519.pub"

install -d -m 0700 -o "$SMOKE_USER" -g "$SMOKE_USER" \
	"$SMOKE_HOME/.ssh"
install -m 0600 -o "$SMOKE_USER" -g "$SMOKE_USER" \
	"$KEY_DIR/id_ed25519.pub" "$SMOKE_HOME/.ssh/authorized_keys"

ssh-keygen -A

log server_setup 'status=ready port=22 workspace=/workspace'
exec /usr/sbin/sshd -D -e \
	-o AllowUsers="$SMOKE_USER" \
	-o AuthenticationMethods=publickey \
	-o KbdInteractiveAuthentication=no \
	-o PasswordAuthentication=no \
	-o PermitRootLogin=no \
	-o PubkeyAuthentication=yes \
	-o UsePAM=no
