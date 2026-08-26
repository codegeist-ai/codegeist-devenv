# Add Graphical Remote SSH Smoke Test

- ID: `T002`
- Type: `test`
- Status: `solved`
- Parent: `none`
- Tracking: `none`

## Goal

Provide one automated smoke test that proves the repository launcher can open a
real remote folder in the graphical Visual Studio Code client through Remote -
SSH.

## Context

T001 established the minimal `scripts/cgenv` handoff and verified its argument
contract with a mocked `code` command. This task adds a separate end-to-end
boundary test using disposable Docker infrastructure. Docker remains test-only
and does not become part of the launcher runtime or consumer contract.

Visual Studio Code `1.134.0` and Remote - SSH `0.126.0` are pinned for the first
implementation. The build and first connection require outbound access to the
Debian, Visual Studio Marketplace, and VS Code download endpoints.

## Scope

In scope:

- Build separate Debian-based VS Code client and OpenSSH server targets.
- Start the real Electron client on Xvfb with a lightweight window manager.
- Invoke the checkout's `scripts/cgenv ssh-server /workspace` entrypoint.
- Generate an ephemeral SSH keypair and remove it with the Compose volume.
- Assert a visible window, the `/workspace` path, the SSH remote authority, and
  a running VS Code Server process.
- Preserve screenshots and diagnostics under ignored `.test-results/` output.
- Close VS Code and remove containers, the network, and volumes automatically.
- Expose the workflow as `task smoke` and document its test-only boundary.

Out of scope:

- Adding Docker, VS Code, SSH, or credential management to `scripts/cgenv`.
- Publishing either test image or redistributing downloaded Microsoft binaries.
- Supporting offline builds, a host X11 display, VNC, or interactive debugging.
- Treating full VS Code in a Linux container as a supported production setup.

## Acceptance Criteria

- `task smoke` builds and starts isolated client and SSH server containers.
- The client runs VS Code as an unprivileged graphical process on Xvfb.
- The client invokes the repository launcher from a read-only checkout mount.
- The test detects a visible window for `/workspace`, evidence of the
  `ssh-remote+ssh-server` authority, and a running remote VS Code Server.
- Client diagnostics, Compose logs, available server logs, and a screenshot when
  the X11 display started are written below `.test-results/cgenv-smoke/` on
  success and failure.
- Private key material is not copied into the result directory or repository.
- Containers, the Compose network, and the ephemeral key volume are removed
  after success, failure, or a handled interruption.
- Product documentation continues to describe Docker as test-only.

## Verification

- Review the implementation before executing it.
- Run `bash -n tests/smoke/*.sh`.
- Run `shellcheck scripts/cgenv tests/smoke/*.sh` when ShellCheck is available.
- Run `docker compose -f tests/smoke/compose.yml config`.
- Run `task --list` and confirm the `smoke` task is present.
- Run `task smoke` with outbound network access.
- Confirm `.test-results/cgenv-smoke/client/vscode.png` and diagnostic logs are
  non-empty.
- Confirm no containers, networks, or volumes for project `cgenv-smoke` remain.
- Re-run the existing mocked launcher argument checks.
- Run `git --no-pager diff --check`.

Verification completed on 2026-08-26:

- Shell syntax, Compose configuration, executable permissions, `task --list`,
  and `git --no-pager diff --check` passed.
- ShellCheck was not run because it is not installed in the test environment.
- `task smoke` passed with VS Code `1.134.0` and Remote - SSH `0.126.0`.
- The result records a visible `/workspace` window on `ssh-server`, the logged
  remote authority, and live `server-main.js --start-server` processes.
- The screenshot and client, Compose, authority, process, and server logs are
  non-empty; collected output contains no private key material.
- No `cgenv-smoke` containers, network, or key volume remained after cleanup.
- Direct and Taskfile launcher mocks preserved arguments containing spaces;
  invalid argument counts returned `2`, and the launcher propagated the mocked
  `code` exit status.

## File Targets

- `.gitignore`
- `Taskfile.yml`
- `tests/smoke/`
- `README.md`
- `docs/architecture.md`
- `INDEX.md`
- `docs/tasks/T002_graphical_remote_ssh_smoke_test.md`

## Dependencies

- Docker Engine with Docker Compose v2.
- Outbound HTTPS access during image build and first Remote - SSH connection.
- Enough local resources for the graphical client and remote VS Code Server.

## Implementation Notes

- Keep `scripts/cgenv` unchanged and mount the checkout read-only in the client.
- Use a non-root client without extra Docker capabilities. Disable Chromium's
  namespace sandbox through a test-local `code` wrapper because it cannot
  initialize inside default Docker isolation.
- Copy diagnostics from stopped containers before Compose removes them.
- Keep the client key only in the disposable volume and client home directory;
  neither location is included in artifact collection.
- Full VS Code in Linux containers is outside Microsoft's supported production
  environments. This topology is intentionally limited to the smoke test.

## Open Questions

- `none`

## Cancellation Reason

- `none`
