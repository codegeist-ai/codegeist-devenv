# Project Memory

## Current Goal

- Establish `codegeist-devenv` as the future home of an extensible wrapper CLI
  around `devenv`.
- Keep the bootstrap documentation-only until the wrapper contract is specified.

## Current Repository State

- The repository is initialized on `main` as a documentation-only bootstrap.
- `.devcontainer` and `.opencode` track the shared Codegeist kits on `release`.
- Gitea is the private primary host and GitHub is the public Git-ref mirror.
- No wrapper, Devenv or Nix configuration, command, extension, test, package,
  release workflow, consumer path, or project license exists.
- `docs/architecture.md` records the empty architecture and deferred decisions.

## Durable Boundaries

- Treat every committed ref as public.
- Do not add placeholder runtime files before a task specifies their contract.
- Keep repository-development kits separate from future consumer integration.
- Public visibility does not grant reuse or redistribution rights while the
  project license remains unresolved.

## Open Next Steps

- Define the first concrete wrapper use cases and observable commands.
- Decide what extensible functions mean and how extensions are discovered.
- Select an implementation language and compatibility policy for upstream
  `devenv`.
- Specify tests, installation, packaging, versioning, consumer integration, and
  licensing before implementation.
