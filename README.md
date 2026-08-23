# Codegeist Devenv

Codegeist Devenv is the future home of an extensible CLI for launching and
managing development environments by orchestrating existing development tools.

## Product Direction

The first concrete workflow is opening a project hosted on an SSH server
directly in a local Visual Studio Code window. The user identifies an SSH target
and a remote project directory, and the CLI starts VS Code in that directory
through the
[Remote - SSH extension](https://code.visualstudio.com/docs/remote/ssh).

The CLI is intended to wrap the local OpenSSH client and VS Code's existing
remote support rather than reimplementing SSH transport or the editor's remote
runtime. VS Code already exposes the underlying launch capability:

```bash
code --remote ssh-remote+remote_server /code/my_project
```

The Codegeist Devenv command name, arguments, path semantics, and supported
launch environments are not specified yet. Future integrations may include
[`devenv`](https://devenv.sh/), additional editors, and extensible development
workflows, but none of those contracts has been selected.

## Current Bootstrap State

This repository currently contains documentation and shared workspace setup
only. It does not contain a CLI executable, Devenv or Nix configuration,
commands, extensions, build tooling, tests, packages, or release automation.

The initial user outcome is defined only at the product level. A later task must
specify the executable and command model, supported local environments, SSH
target and remote-path rules, process and error behavior, implementation
language, extension mechanism, installation and upgrade flow, compatibility
policy, versioning, testing strategy, and consumer integration before runtime
files are added.

## Documentation

- `docs/architecture.md` records the product boundary and deferred technical
  decisions.
- `INDEX.md` provides the repository navigation map.

## Workspace Kits

`.devcontainer/` and `.opencode/` are Git submodules that track the `release`
branches of the shared Codegeist development and agent kits. Initialize them
from this repository with:

```bash
git submodule update --init .devcontainer .opencode
```

These submodules support development of this repository. They are not a design
decision for how future projects will consume the CLI.

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
