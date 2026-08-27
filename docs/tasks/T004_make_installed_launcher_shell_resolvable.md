# Make Installed Launcher Shell-Resolvable

- ID: `T004`
- Type: `fix`
- Status: `solved`
- Parent: `none`
- Tracking: `none`

## Goal

Make a default `install.sh` run install `cgenv` without root privileges and
configure the user's shell so loading the selected configuration resolves and
executes the `cgenv` command by name.

## Context

Release `v0.1.0` installed the executable into `$HOME/.local/bin`, but a shell
started before that directory existed could omit it from `PATH`. The installer
reported success while an immediate `cgenv` invocation in that parent shell
failed with `command not found`.

A streamed installer cannot mutate the environment of its already-running
parent shell. It can install into a stable user-local application directory,
persist that directory in the appropriate shell configuration, and print the
activation command the user must run instead.

## Scope

In scope:

- Install the default payload into `$HOME/.cgenv/bin` with mode `0755`.
- Detect Bash, Zsh, Fish, Ash, and POSIX `sh` through `$SHELL`.
- Add the selected binary directory to the first existing shell configuration
  file without duplicating entries.
- Preserve `--bin-dir` and add `--no-modify-path` for explicit opt-out.
- Require custom binary directories to be absolute, valid PATH entries.
- Keep installation fully user-local without invoking `sudo`.
- Prove command-name resolution and invocation in the release test.
- Publish and verify release `v0.1.1`.

Out of scope:

- Changing the environment of the running parent shell.
- Creating missing shell configuration files or modifying system-wide profiles.
- Automatically deleting the previous `$HOME/.local/bin/cgenv` installation.
- Adding root, sudo, system package, or package-manager installation paths.

## Acceptance Criteria

- A default install creates `$HOME/.cgenv/bin/cgenv` with mode `0755` without
  invoking `sudo` or requiring root.
- Bash and Zsh installations add
  `export PATH="$HOME/.cgenv/bin:$PATH"` to the selected user configuration.
- Fish uses `fish_add_path`, while Ash and POSIX `sh` receive an `export PATH`
  entry.
- Repeated installations do not duplicate the PATH command.
- `--no-modify-path` leaves shell configuration unchanged and prints a manual
  PATH command when the selected directory is not already active.
- The installer prints the selected configuration file that the current shell
  must source; future shells activate the entry when they read that file.
- The release test starts without `cgenv` in `PATH`, streams `install.sh`, loads
  its generated Bash configuration, resolves `cgenv`, invokes it by command
  name, and verifies the exact `code --remote` handoff.
- Release `v0.1.1` exposes the tested installer, ZIP, and checksum assets.

## Verification

- Run `sh -n install.sh`.
- Run `bash -n tests/release.sh`.
- Run `task release-test -- v0.1.1 <implementation-ref>`.
- Confirm the test log contains
  `event=install_command_smoke status=passed command=cgenv`.
- Run the published installer in a disposable home, activate its generated
  shell configuration, and invoke `cgenv` by name with a fake `code` command.

Verification completed on 2026-08-27:

- `sh -n install.sh`, `bash -n tools/build-release.sh tests/release.sh
  tests/smoke/*.sh`, Compose configuration, and `git diff --check` passed.
- `task release-test -- v0.1.1 f80c3e4ba40d` passed against implementation
  commit `f80c3e4ba40d0b833b4bff3382bd638f21ff1c05`.
- The release test began with an isolated PATH, streamed the generated
  installer, sourced its Bash configuration, resolved the installed command,
  invoked `cgenv` by name, and emitted
  `event=install_command_smoke status=passed command=cgenv` after verifying the
  exact launcher handoff.
- Installer coverage also passed for mode `0755`, Bash and Zsh configuration,
  idempotence, an already-active PATH, custom destinations, `--no-modify-path`,
  no-HOME custom installation, invalid PATH entries, checksum rejection, and
  truncated streams with either the final call or completion marker missing.
- Annotated tag `v0.1.1` resolves to the implementation commit on Gitea and
  GitHub. GitHub Actions run
  `https://github.com/codegeist-ai/codegeist-devenv/actions/runs/33101053639`
  completed successfully and published all three assets.
- Anonymous downloads of `install.sh`, `codegeist-devenv-v0.1.1.zip`, and
  `SHA256SUMS` passed the published checksum and exact archive inventory checks.
- The public latest-release installer ran in a disposable Bash home without
  sudo, added `$HOME/.cgenv/bin` to `.bashrc`, installed mode-`0755` `cgenv`,
  and executed `cgenv smoke-host /workspace` by command name with a fake `code`
  command and exit status `0`.

## File Targets

- `install.sh`
- `tests/release.sh`
- `README.md`
- `docs/architecture.md`
- `docs/tasks/T004_make_installed_launcher_shell_resolvable.md`
- `INDEX.md`
- `Taskfile.yml`
- `tools/build-release.sh`

## Dependencies

- The existing `v0.1.0` release and GitHub Actions publication workflow.

## Implementation Notes

- Perform shell configuration only after the archive checksum, layout, and
  payload validation have passed and installation has completed.
- Keep the installer POSIX `sh` compatible even when it configures Bash, Zsh,
  Fish, or another supported shell.
- Keep the old installed copy untouched; the newly prepended application path
  takes command precedence after shell activation.

## Open Questions

- `none`

## Cancellation Reason

- `none`
