# Architecture

Codegeist Devenv currently has no runtime architecture. This document records
the intended product boundary and prevents bootstrap files from becoming
accidental technical decisions.

## Intended Boundary

The repository is intended to develop an extensible wrapper CLI around
`devenv`. The wrapper may eventually add Codegeist-specific functions while
preserving access to appropriate upstream behavior, but no command or extension
contract exists yet.

## Current State

The repository contains only documentation, Git metadata, and the shared
development and agent-kit submodules. It has no executable, library, package,
Nix module, Devenv project, shell integration, build, test, or release path.

The `.devcontainer/` and `.opencode/` gitlinks support work on this repository.
They do not define how the future wrapper is installed or consumed.

## Deferred Decisions

A later task must specify at least:

- User problems and initial observable commands.
- Relationship to the upstream `devenv` executable and exit behavior.
- Implementation language and dependency policy.
- Meaning of an extension or additional function.
- Configuration discovery, precedence, namespacing, and collision handling.
- Installation, upgrades, reproducibility, and upstream version compatibility.
- Consumer integration and whether Git submodules are part of that contract.
- Test layers, supported platforms, packaging, versioning, and releases.
- Project licensing and redistribution terms.

These decisions must be based on concrete requirements and current upstream
Devenv documentation. Do not introduce a provisional file layout or executable
stub before that specification exists.

## Public Repository Boundary

Gitea is private, but all committed Git refs are mirrored to public GitHub.
Architecture notes, source code, fixtures, and generated files added later must
therefore be suitable for public redistribution and must never contain secrets
or private planning material.
