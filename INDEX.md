# Repository Index

Navigation map for the documentation-only Codegeist Devenv CLI bootstrap.

## When To Read This

- Read this before defining the CLI, editor or SSH integration, extension model,
  packaging, or consumer integration.
- Read `docs/architecture.md` before adding runtime, VS Code Remote - SSH, or
  Devenv-related files.

## Directory Map

- `README.md` - product direction, current boundaries, hosting, and workspace
  setup.
- `docs/architecture.md` - product boundary, current empty runtime, and deferred
  decisions.
- `.devcontainer/` - shared development environment on its `release` branch.
- `.opencode/` - shared OpenCode agent kit on its `release` branch.
- `.gitmodules` - shared-kit submodule sources and branch tracking.

## Known Directory Indexes

- `INDEX.md` - this repository-root index.

## Key Workflows

- Initialize shared kits with `git submodule update --init .devcontainer
  .opencode` from this repository.
- Specify the remote-workspace launch and extension contracts in a later tracked
  task before adding source code or configuration.

## Search Hints

- `deferred` - decisions intentionally not made during bootstrap.
- `Remote - SSH` - the first concrete editor integration and product workflow.
- `remote project` - the initial workspace-launch use case.
- `devenv` - a possible future integration with no selected contract.
- `public` - constraints created by the public GitHub mirror.

## Update Triggers

- Update this index when top-level files, directories, or entrypoints change.

## Agent Notes

- Do not infer a CLI API or add placeholders without a specified task.
- Treat every committed ref as public.
- The absence of a license is an unresolved decision, not permission to reuse
  future work.
