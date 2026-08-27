# Repository Index

Navigation map for the installable Codegeist Devenv VS Code Remote - SSH
launcher.

## When To Read This

- Read this before changing the launcher contract, editor integration,
  packaging, or consumer integration.
- Read `docs/architecture.md` before adding another runtime layer.

## Directory Map

- `scripts/cgenv` - validates an SSH target and directory, then hands off to the
  local VS Code CLI.
- `install.sh` - downloads and verifies the Linux release scripts, installs them
  without root, and configures the user's shell PATH.
- `tools/build-release.sh` - builds the separate installer, script ZIP, and
  checksum release assets.
- `.github/workflows/release.yml` - publishes tested assets for mirrored SemVer
  tags.
- `Taskfile.yml` - exposes launcher, smoke-test, and release entrypoints.
- `tests/release.sh` - verifies the ZIP boundary, streamed installer, shell PATH,
  and invocation of the installed `cgenv` command.
- `tests/smoke/` - runs the launcher through graphical VS Code and an isolated
  SSH server using disposable Docker resources.
- `LICENSE` - applies the 0BSD license to repository-owned material.
- `README.md` - launcher usage, current scope, hosting, and workspace setup.
- `docs/architecture.md` - current runtime flow and product boundary.
- `docs/tasks/` - tracked specifications and implementation handoff.
- `.devcontainer/` - shared development environment on its `release` branch.
- `.opencode/` - shared OpenCode agent kit on its `release` branch.
- `.gitmodules` - shared-kit submodule sources and branch tracking.

## Known Directory Indexes

- `INDEX.md` - this repository-root index.

## Key Workflows

- Open a remote directory with `task cgenv -- <ssh-target> <directory>` or
  `./scripts/cgenv <ssh-target> <directory>`.
- Install the latest public Linux release with
  `curl -fsSL https://github.com/codegeist-ai/codegeist-devenv/releases/latest/download/install.sh | sh`.
- Build and verify release assets with `task release-build -- <version> <ref>`
  and `task release-test -- <version> <ref>`.
- Run the graphical Remote - SSH boundary test with `task smoke`; review
  ignored artifacts under `.test-results/cgenv-smoke/`.
- Initialize shared kits with `git submodule update --init .devcontainer
  .opencode` from this repository.
- Track the launcher through
  `docs/tasks/T001_launch_vscode_remote_workspace.md`.
- Track the graphical boundary test through
  `docs/tasks/T002_graphical_remote_ssh_smoke_test.md`.
- Track the installable release through
  `docs/tasks/T003_publish_installable_script_release.md`.
- Track user-local installation and shell PATH integration through
  `docs/tasks/T004_make_installed_launcher_shell_resolvable.md`.

## Search Hints

- `code --remote` and `ssh-remote+` - the complete runtime handoff.
- `CLI_ARGS` - Taskfile forwarding for launcher arguments.
- `cgenv` - executable and Taskfile entrypoint.
- `RELEASE_VERSION`, `SHA256SUMS`, `install_path`, and `git archive` - installer
  integrity and shell integration contract.
- `contents: write` and `gh release create` - GitHub release publication.
- `CGENV_SMOKE`, `ssh-server`, and `Xvfb` - graphical smoke-test assertions and
  topology.
- `public` - constraints created by the public GitHub mirror.

## Update Triggers

- Update this index when top-level files, directories, entrypoints, or launcher
  responsibilities change.

## Agent Notes

- Keep `scripts/cgenv` small and delegate SSH behavior to VS Code.
- Keep every file under `scripts/` installable runtime payload; release helpers
  stay outside that directory.
- Treat every committed ref as public.
- Keep `install.sh` separate from the ZIP, which contains only `scripts/`.
