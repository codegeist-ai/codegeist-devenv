# Architecture

Codegeist Devenv currently has no runtime architecture. This document records
the intended product boundary and prevents bootstrap files from becoming
accidental technical decisions.

## Intended Boundary

The repository is intended to develop an extensible CLI that launches and
manages development environments by coordinating existing development tools.
It should provide a direct entrypoint into a development workspace without
replacing the tools that own transport, editor, or environment behavior.

## Initial Product Workflow

The first concrete workflow is opening a project on an SSH server directly in a
local Visual Studio Code window. The user identifies an SSH target and a remote
project directory. The CLI then delegates the connection and editor launch to
the local OpenSSH client and VS Code's Remote - SSH extension.

VS Code already supports opening a remote folder from its CLI with a remote SSH
authority. Codegeist Devenv should wrap that capability rather than implement
an SSH protocol, maintain a separate long-lived SSH session, or install its own
editor runtime on the server.

This workflow defines a product outcome, not a command contract. The executable
name, subcommand, flags, accepted SSH target forms, and remote-path semantics
remain deferred. Integration with `devenv`, other editors, and additional
development workflows may be added later through an extension model that has
not yet been designed.

## Current State

The repository contains only documentation, Git metadata, and the shared
development and agent-kit submodules. It has no executable, library, package,
VS Code or SSH integration, Nix module, Devenv project, shell integration,
build, test, or release path.

The `.devcontainer/` and `.opencode/` gitlinks support work on this repository.
They do not define how the future CLI is installed or consumed.

## Deferred Decisions

A later task must specify at least:

- Executable name, subcommands, flags, and observable behavior.
- Supported launch environments, including whether native Linux and WSL are in
  scope.
- How the local VS Code CLI and Remote - SSH extension are discovered and
  validated.
- Accepted SSH targets, including direct `user@host` values and SSH config
  aliases.
- Remote-path rules, including absolute paths, home-relative paths, validation,
  and shell expansion.
- Process handoff, window reuse, authentication prompts, failures, and exit
  behavior.
- Relationship to the upstream `devenv` executable and other editor
  integrations.
- Implementation language and dependency policy.
- Meaning of an extension or additional function.
- Configuration discovery, precedence, namespacing, and collision handling.
- Installation, upgrades, reproducibility, and upstream version compatibility.
- Consumer integration and whether Git submodules are part of that contract.
- Test layers, supported platforms, packaging, versioning, and releases.
- Project licensing and redistribution terms.

These decisions must be based on concrete requirements and current upstream
documentation for the integrated tools. Do not introduce a provisional file
layout or executable stub before that specification exists.

## Public Repository Boundary

Gitea is private, but all committed Git refs are mirrored to public GitHub.
Architecture notes, source code, fixtures, and generated files added later must
therefore be suitable for public redistribution and must never contain secrets
or private planning material.
