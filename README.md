# Codegeist Devenv

Codegeist Devenv provides a small local launcher for opening an SSH-hosted
directory through Visual Studio Code Remote - SSH.

## Usage

The local `code` CLI and the
[Remote - SSH extension](https://code.visualstudio.com/docs/remote/ssh) must
already be installed. The SSH target must already work with the user's normal
SSH configuration and authentication.

Run the workspace task with an SSH target and remote directory:

```bash
task cgenv -- remote_server /code/my_project
```

The script can also be called directly:

```bash
./scripts/cgenv remote_server /code/my_project
```

`scripts/cgenv` requires exactly two arguments and hands off to:

```bash
code --remote ssh-remote+remote_server /code/my_project
```

The launcher passes both values through without implementing SSH, starting a
Dev Container, or managing VS Code after the handoff.

## Current Scope

The production runtime consists only of `scripts/cgenv` and its optional
`Taskfile.yml` entrypoint. There is no Devenv/Nix configuration, Docker-based
runtime image, resident service, package, or release automation yet.

## Graphical Smoke Test

`tests/smoke/` contains test-only Docker infrastructure for exercising the
complete VS Code Remote - SSH handoff. It starts an OpenSSH server and a real
VS Code Electron client on an Xvfb display, then invokes the checkout's launcher
against `/workspace`:

```bash
task smoke
```

The test currently pins Visual Studio Code `1.134.0` and Remote - SSH `0.126.0`.
Its image build and first remote connection require outbound HTTPS access to
Debian and Microsoft download services. Running the task downloads software
subject to its upstream license terms.

Results are written under ignored `.test-results/cgenv-smoke/`, including a
screenshot and available client, Compose, and remote-server logs. Containers,
the Compose network, and the volume holding the ephemeral SSH keypair are
removed after artifact collection.

Microsoft does not support full VS Code as a production application inside a
Linux container. This topology is an isolated smoke-test fixture only and does
not change the `cgenv` runtime contract. The client remains non-root and receives
no extra Docker capabilities, but a test-local `code` wrapper passes
`--no-sandbox` because Chromium's namespace sandbox cannot initialize under the
default Docker isolation.

## Documentation

- `docs/architecture.md` records the product boundary and deferred technical
  decisions.
- `docs/tasks/T001_launch_vscode_remote_workspace.md` records the implemented
  launcher contract and verification.
- `docs/tasks/T002_graphical_remote_ssh_smoke_test.md` records the graphical
  end-to-end test contract and verification.
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
