# Repository Index

Navigation map for the minimal Codegeist Devenv VS Code Remote - SSH launcher.

## When To Read This

- Read this before changing the launcher contract, editor integration,
  packaging, or consumer integration.
- Read `docs/architecture.md` before adding another runtime layer.

## Directory Map

- `scripts/cgenv` - validates an SSH target and directory, then hands off to the
  local VS Code CLI.
- `Taskfile.yml` - exposes `task cgenv -- <ssh-target> <directory>`.
- `tests/smoke/` - runs the launcher through graphical VS Code and an isolated
  SSH server using disposable Docker resources.
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
- Run the graphical Remote - SSH boundary test with `task smoke`; review
  ignored artifacts under `.test-results/cgenv-smoke/`.
- Initialize shared kits with `git submodule update --init .devcontainer
  .opencode` from this repository.
- Track the launcher through
  `docs/tasks/T001_launch_vscode_remote_workspace.md`.
- Track the graphical boundary test through
  `docs/tasks/T002_graphical_remote_ssh_smoke_test.md`.

## Search Hints

- `code --remote` and `ssh-remote+` - the complete runtime handoff.
- `CLI_ARGS` - Taskfile forwarding for launcher arguments.
- `cgenv` - executable and Taskfile entrypoint.
- `CGENV_SMOKE`, `ssh-server`, and `Xvfb` - graphical smoke-test assertions and
  topology.
- `public` - constraints created by the public GitHub mirror.

## Update Triggers

- Update this index when top-level files, directories, entrypoints, or launcher
  responsibilities change.

## Agent Notes

- Keep `scripts/cgenv` small and delegate SSH behavior to VS Code.
- Treat every committed ref as public.
- The absence of a license is an unresolved decision, not permission to reuse
  future work.
