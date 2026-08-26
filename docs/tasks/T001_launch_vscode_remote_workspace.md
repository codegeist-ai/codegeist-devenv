# Launch VS Code Remote Workspace

- ID: `T001`
- Type: `feature`
- Status: `solved`
- Parent: `none`
- Tracking: `none`

## Goal

Provide the smallest local command that opens a caller-selected directory on a
caller-selected SSH target through Visual Studio Code Remote - SSH.

## Context

Visual Studio Code already exposes the required operation through `code
--remote`. The accepted implementation is a small shell script with an optional
Taskfile entrypoint. Earlier plans for Devenv/Nix, Docker, direct SSH execution,
Dev Container startup, browser callbacks, and OpenCode launch are no longer part
of this task.

## Scope

In scope:

- Add `scripts/cgenv` with the command shape `cgenv <ssh-target> <directory>`.
- Require exactly two positional arguments and report concise usage on error.
- Invoke `code --remote ssh-remote+<ssh-target> <directory>` without evaluating
  or rewriting the directory.
- Replace the script process with `code` so its exit status reaches the caller.
- Add `task cgenv -- <ssh-target> <directory>` as a workspace convenience.
- Document the implemented contract and its boundaries.

Out of scope:

- Installing or configuring VS Code, Remote - SSH, OpenSSH, or credentials.
- Devenv/Nix configuration, Docker images, and direct SSH commands.
- Dev Container, browser, callback-port, or OpenCode lifecycle management.
- Packaging, installation outside the checkout, or release automation.

## Acceptance Criteria

- `scripts/cgenv` is executable and contains no orchestration beyond argument
  validation and the `code --remote` handoff.
- Missing or extra arguments produce the documented usage and exit status `2`.
- SSH targets and directories, including values with spaces, reach `code` as
  distinct arguments without shell expansion.
- `task cgenv -- <ssh-target> <directory>` delegates to the same script.
- Product and architecture documentation describe the implemented behavior and
  contain no obsolete Devenv, Docker, callback, or automatic Dev Container
  contract.

## Verification

- Run `sh -n scripts/cgenv`.
- Mock `code` and verify its exact argument vector for direct and Taskfile calls.
- Verify invalid argument counts return status `2` and print usage.
- Run `task --list` and `git --no-pager diff --check`.

## File Targets

- `scripts/cgenv`
- `Taskfile.yml`
- `README.md`
- `docs/architecture.md`
- `INDEX.md`
- `docs/tasks/T001_launch_vscode_remote_workspace.md`

## Dependencies

- Local Visual Studio Code CLI with the Remote - SSH extension.
- A caller-managed SSH target and authentication setup.
- Task for the optional `task cgenv` entrypoint.

## Implementation Notes

- Keep the script POSIX-compatible and use `exec` for process handoff.
- Let VS Code own SSH connection behavior and diagnostics.
- Use Task's `CLI_ARGS` value because it preserves shell quoting for arguments
  supplied after `--`.

## Open Questions

- `none`

## Cancellation Reason

- `none`
