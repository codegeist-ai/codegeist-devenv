# Codegeist Devenv

Codegeist Devenv is the future home of an extensible wrapper CLI around
[`devenv`](https://devenv.sh/).

## Current Bootstrap State

This repository currently contains documentation and shared workspace setup
only. It does not contain a wrapper executable, Devenv or Nix configuration,
commands, extensions, build tooling, tests, packages, or release automation.

The wrapper contract will be designed in a later task. That work must decide the
implementation language, command model, extension mechanism, installation and
upgrade flow, compatibility policy, versioning, testing strategy, and consumer
integration before runtime files are added.

## Documentation

- `docs/architecture.md` records the current empty architecture and deferred
  technical decisions.
- `docs/memory-bank/chat.md` records compact current project state.
- `INDEX.md` provides the repository navigation map.

## Workspace Kits

`.devcontainer/` and `.opencode/` are Git submodules that track the `release`
branches of the shared Codegeist development and agent kits. Initialize them
from this repository with:

```bash
git submodule update --init .devcontainer .opencode
```

These submodules support development of this repository. They are not a design
decision for how future projects will consume the wrapper.

## Hosting

Gitea at `git.codegeist.ai` is the private primary write target. GitHub at
`github.com/codegeist-ai/codegeist-devenv` is a public push mirror of Git refs.
Issues, pull requests, secrets, permissions, Actions state, and other
platform-specific state are not automatically synchronized.

Treat every committed ref as public. Do not commit credentials, private plans,
or material that cannot be redistributed publicly.

## License Status

No project license has been selected. Public visibility does not grant
permission to use, copy, modify, or redistribute future implementation work.
A later task must select and document a license before such rights are assumed.
