# Architecture

Codegeist Devenv currently delegates its only runtime operation to the local
Visual Studio Code CLI and Remote - SSH extension.

## Runtime Flow

```text
task cgenv -- <ssh-target> <directory>
  -> scripts/cgenv <ssh-target> <directory>
  -> code --remote ssh-remote+<ssh-target> <directory>
  -> Visual Studio Code Remote - SSH
```

`Taskfile.yml` is an optional convenience entrypoint. `scripts/cgenv` owns the
two-argument validation, constructs the VS Code remote authority, and replaces
itself with `code` so the caller receives the VS Code CLI exit status.

## Command Contract

The first argument is an SSH config alias or another target accepted by VS Code
Remote - SSH. The launcher prefixes it with `ssh-remote+`. The second argument
is passed verbatim as the directory to open on that SSH target.

The local machine must already provide the `code` CLI, Remote - SSH extension,
SSH configuration, and authentication. The launcher does not inspect or modify
those dependencies.

## Boundary

The launcher does not implement SSH, install a remote editor runtime, start a
Dev Container, manage browser callbacks, or keep a resident process. Visual
Studio Code owns connection establishment, prompts, editor lifecycle, and any
later Dev Container transition.

The repository's `.devcontainer/` and `.opencode/` gitlinks support development
of this repository. They are not part of the `cgenv` runtime contract.

## Installation And Distribution

The Linux distribution path packages only the executable `scripts/` tree:

```text
annotated v0.1.0 tag in Gitea
  -> Git ref mirror to GitHub
  -> GitHub Actions release workflow
  -> install.sh + codegeist-devenv-v0.1.0.zip + SHA256SUMS
  -> install.sh downloads and verifies the ZIP
  -> scripts/* installed into $HOME/.local/bin by default
```

`install.sh` is a separate release asset and is never ZIP payload. The ZIP has a
single versioned root containing only `scripts/`. The installer supports Linux,
does not invoke sudo, and accepts only `--bin-dir` to replace the default
destination. It validates `SHA256SUMS` before extracting or changing the
destination.

`tools/build-release.sh` produces the three local assets with Git's built-in ZIP
archive support. `tests/release.sh` verifies archive isolation, checksum
handling, streamed installer execution, destination selection, executable mode,
and the installed launcher handoff. `.github/workflows/release.yml` applies the
same test before creating the public GitHub release from a mirrored SemVer tag.

## Smoke-Test Topology

The Docker files under `tests/smoke/` exercise the runtime boundary without
adding Docker to the launcher itself:

```text
task smoke
  -> tests/smoke/run.sh
  -> Docker Compose
     -> client: Xvfb + Openbox + VS Code Desktop + Remote - SSH
        -> /repo/scripts/cgenv ssh-server /workspace
     -> ssh-server: OpenSSH + /workspace
        -> VS Code Server installed through Remote - SSH
```

The checkout is mounted read-only into the client, so the test invokes the
current `scripts/cgenv` file. A named volume carries one ephemeral SSH keypair
between the two containers. The runner copies screenshots and logs to ignored
`.test-results/cgenv-smoke/` output before removing containers, the Compose
network, and that volume.

The client runs the real Electron application as an unprivileged user on a
virtual X11 display. This is a test-only arrangement: full VS Code in a Linux
container is outside Microsoft's supported production environments and is not
a consumer deployment model for Codegeist Devenv. A client-only `code` wrapper
adds `--no-sandbox` because Chromium's namespace sandbox cannot initialize under
default Docker isolation; the container receives no extra host capabilities.

## Deferred Decisions

- Additional editors or workspace launch modes.
- Installer or package-manager support outside Linux.
- Compatibility and upgrade policy beyond the initial `v0.1.0` release.

## Public Repository Boundary

Gitea is private, but all committed Git refs are mirrored to public GitHub and
release assets are published there under the repository's 0BSD license. Source,
documentation, fixtures, and generated files must therefore be suitable for
public redistribution and must never contain secrets or private planning
material.
