# Repository Index

Navigation map for the documentation-only Codegeist Devenv bootstrap.

## When To Read This

- Read this before defining the wrapper CLI, extension model, packaging, or
  consumer integration.
- Read `docs/architecture.md` before adding runtime or Devenv-related files.

## Directory Map

- `README.md` - future purpose, current boundaries, hosting, and workspace setup.
- `docs/architecture.md` - current empty architecture and deferred decisions.
- `docs/memory-bank/chat.md` - compact state for future sessions.
- `.devcontainer/` - shared development environment on its `release` branch.
- `.opencode/` - shared OpenCode agent kit on its `release` branch.
- `.gitmodules` - shared-kit submodule sources and branch tracking.

## Known Directory Indexes

- `INDEX.md` - this repository-root index.

## Key Workflows

- Initialize shared kits with `git submodule update --init .devcontainer
  .opencode` from this repository.
- Specify the wrapper and extension contracts in a later tracked task before
  adding source code or configuration.

## Search Hints

- `deferred` - decisions intentionally not made during bootstrap.
- `wrapper CLI` - the future product boundary.
- `public` - constraints created by the public GitHub mirror.

## Update Triggers

- Update this index when top-level files, directories, or entrypoints change.
- Update `docs/memory-bank/chat.md` when implementation or consumption decisions
  become current project state.

## Agent Notes

- Do not infer a wrapper API or add placeholders without a specified task.
- Treat every committed ref as public.
- The absence of a license is an unresolved decision, not permission to reuse
  future work.
