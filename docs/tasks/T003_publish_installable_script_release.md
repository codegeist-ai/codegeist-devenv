# Publish Installable Script Release

- ID: `T003`
- Type: `feature`
- Status: `solved`
- Parent: `none`
- Tracking: `none`

## Goal

Publish Codegeist Devenv `v0.1.0` as a public GitHub release with a Linux
installer that downloads, verifies, extracts, and installs the repository's
runtime scripts into the current user's system.

## Context

The production runtime entered this task with only executable files under
`scripts/`, initially `scripts/cgenv`. The repository had no release tags,
release assets, installer, license, or release automation.

Gitea at `git.codegeist.ai` remains the primary write target. Git refs are
mirrored to the public `codegeist-ai/codegeist-devenv` GitHub repository, but
GitHub releases and Actions state are platform-specific and are not created by
the mirror itself. GitHub Actions is enabled for the public repository. The
release workflow must request `contents: write` because the default workflow
token permission is read-only.

The initial release decisions are intentionally narrow:

- Release `v0.1.0` publicly on GitHub.
- Support Linux only.
- Add the project-wide 0BSD license.
- Install to `$HOME/.local/bin` by default.
- Let `install.sh` download its matching release archive.
- Publish `install.sh` under that exact asset name together with the ZIP archive
  and `SHA256SUMS`.
- Keep `install.sh` separate from the ZIP; the archive contains only the
  versioned `scripts/` tree that the installer downloads and extracts.
- Support installation directly from GitHub with:

  ```bash
  curl -fsSL https://github.com/codegeist-ai/codegeist-devenv/releases/latest/download/install.sh | sh
  ```

- Package only the runtime files under `scripts/` in the ZIP archive.
- Use GitHub Actions to create the GitHub release from a SemVer tag.

## Scope

In scope:

- Add a root 0BSD `LICENSE` for the repository.
- Add a root `install.sh` that is pinned to `v0.1.0` and supports Linux.
- Keep `install.sh` independent of its own filesystem location so it works when
  streamed to `sh` over standard input.
- Install every packaged runtime script into `$HOME/.local/bin` with mode
  `0755`.
- Support `--bin-dir <path>` as the only alternate installation destination.
- Download the versioned ZIP and `SHA256SUMS` from the matching GitHub release.
- Verify the ZIP with `sha256sum` before extraction or installation.
- Build deterministic release assets from a selected Git ref with `git archive`.
- Add local release build and installer contract tests.
- Publish the three assets through a GitHub Actions tag workflow.
- Publish `install.sh` beside the ZIP as a separate release asset, never as ZIP
  payload.
- Document installation, release, platform, licensing, and mirror behavior.
- Create and publish the annotated `v0.1.0` tag after implementation is saved.
- Install the public release into the current user's default destination and
  verify the installed `cgenv` launcher.

Out of scope:

- macOS, Windows, WSL-specific, or non-POSIX installers.
- Package managers, system packages, container images, or release branches.
- A Gitea release, duplicated release assets, or Gitea Actions.
- Automatic sudo use or a system-wide default such as `/usr/local/bin`.
- Uninstallation, rollback, self-update, update checks, or version selection.
- Packaging `install.sh`, `Taskfile.yml`, documentation, tests, submodules, or
  repository metadata in the runtime ZIP.
- Adding release helpers below `scripts/`, because every file there is runtime
  payload.

## Acceptance Criteria

- The repository root contains the canonical 0BSD license text and documentation
  no longer describes licensing as unresolved.
- `install.sh` rejects non-Linux systems and reports missing required tools
  before changing the destination.
- `install.sh` downloads the `v0.1.0` ZIP and `SHA256SUMS` from the public GitHub
  release, verifies the archive, extracts it in a temporary directory, and
  removes temporary state on exit.
- The default installation creates `$HOME/.local/bin` when needed and installs
  each runtime script with mode `0755`.
- `install.sh --bin-dir <path>` installs the same payload into the selected
  directory without invoking sudo.
- The release exposes `install.sh` at the stable latest-release URL, and the
  documented `curl -fsSL .../install.sh | sh` command completes successfully.
- The release build produces exactly these assets under ignored output:
  `install.sh`, `codegeist-devenv-v0.1.0.zip`, and `SHA256SUMS`.
- The ZIP contains `codegeist-devenv-v0.1.0/scripts/cgenv` and no files outside
  the selected Git ref's `scripts/` tree.
- The ZIP does not contain `install.sh`; the installer is available only as its
  own GitHub release asset.
- `SHA256SUMS` contains and verifies the digest for
  `codegeist-devenv-v0.1.0.zip`.
- Installer tests prove the default destination, `--bin-dir`, executable mode,
  checksum failure, and the installed launcher's exact argument handoff.
- The GitHub workflow validates the tag, runs release tests, builds the assets,
  and creates the release only after those steps pass.
- The workflow uses the built-in GitHub token with an explicit minimal
  `contents: write` permission and commits no credentials.
- GitHub release `v0.1.0` exists on `codegeist-ai/codegeist-devenv`, points to
  the mirrored Gitea tag commit, and exposes all three expected assets.
- The public `install.sh` installs `cgenv` successfully into
  `$HOME/.local/bin/cgenv` on the current Linux system.
- Product, architecture, index, and task documentation describe the implemented
  release contract and its Linux-only boundary.

## Implementation Plan

1. Add root `LICENSE` with the canonical 0BSD text and change license references
   in user and architecture documentation from unresolved to 0BSD.
2. Add a small POSIX `install.sh` with a fixed `v0.1.0` release constant,
   `--bin-dir`, required-command checks, temporary-directory cleanup, download,
   checksum, archive-layout validation, and `install -m 0755` handoff. Do not
   resolve downloads relative to `$0`; the script must support execution from
   standard input.
3. Add `tools/build-release.sh` to validate the SemVer tag and Git ref, build
   `codegeist-devenv-v0.1.0.zip` with `git archive --format=zip`, copy the root
   installer beside the archive, and generate `SHA256SUMS` under
   `dist/v0.1.0/`. Do not add the installer to the archive input.
4. Add a focused release test that uses temporary directories and a fake `curl`
   command to exercise the installer against locally built assets without
   adding test-only options to the installer.
5. Add Taskfile entrypoints for release building and release testing, ignore
   `dist/`, and verify that release helpers remain outside the packaged
   `scripts/` directory.
6. Add `.github/workflows/release.yml` for `v*.*.*` tag pushes with a manual
   `workflow_dispatch` fallback. Use the current official `actions/checkout@v7`,
   run the release tests, build from the triggering tag, and publish through
   `gh release create --verify-tag` with generated release notes and the exact
   asset name `install.sh`.
7. Update `README.md`, `docs/architecture.md`, and `INDEX.md` with the install
   command, artifact layout, Linux support, 0BSD license, GitHub Actions flow,
   and the Gitea-to-GitHub mirror boundary.
8. Save the implementation on Gitea `main`, verify that the same commit and
   workflow reached GitHub, create and push annotated tag `v0.1.0` to Gitea,
   and verify that GitHub received the same tag object and commit.
9. Observe the tag-triggered Actions run. If the mirror does not emit the
   expected workflow event, invoke the same workflow manually on tag `v0.1.0`
   rather than introducing a second publication path.
10. Verify the public release and its assets, run the downloaded installer with
    its default destination, validate the installed launcher, then record the
    release evidence here and change this task to `solved`.

## Verification

- Run `sh -n scripts/cgenv` and `sh -n install.sh`.
- Run `bash -n tools/build-release.sh tests/release.sh tests/smoke/*.sh`.
- Run the focused installer and release test through its Taskfile entrypoint.
- Build `v0.1.0` assets locally from `HEAD` before tagging.
- Inspect the ZIP with `unzip -Z1` and confirm that only the prefixed `scripts/`
  tree is present and `install.sh` is absent.
- Run `sha256sum -c SHA256SUMS` in the generated asset directory.
- Confirm the generated `install.sh` and ZIP can be downloaded through the URLs
  the installer uses.
- Re-run the installed launcher argument checks with a mocked `code` command.
- Run `git --no-pager diff --check`.
- Save the implementation and verify that GitHub `main` matches the Gitea commit
  before creating the release tag.
- Create and push annotated tag `v0.1.0`, then confirm the GitHub tag resolves to
  the same commit.
- Watch the GitHub Actions release job to completion and inspect its logs for the
  build, checksum, test, and publication boundaries.
- Run `gh release view v0.1.0 --repo codegeist-ai/codegeist-devenv` and confirm
  all three asset names.
- Download all release assets into a temporary directory and verify the ZIP
  against the published `SHA256SUMS`.
- Run
  `curl -fsSL https://github.com/codegeist-ai/codegeist-devenv/releases/latest/download/install.sh | sh`
  and confirm `$HOME/.local/bin/cgenv` exists, is executable, and preserves the
  launcher contract.

Verification completed on 2026-08-27:

- Shell syntax, Compose configuration, Taskfile discovery, workflow YAML,
  executable modes, and `git --no-pager diff --check` passed.
- `task release-test -- v0.1.0 HEAD` passed from implementation commit
  `ed1e4fdd0dda3af37004418bc3d207817a08269a`.
- Repeated builds from the same ref produced the same ZIP digest. The published
  archive contains only the versioned directories and `scripts/cgenv`; it does
  not contain `install.sh`.
- Local tests covered the real streamed installer pipeline, exact download URLs,
  Linux rejection, default and custom destinations, existing-directory mode
  preservation, checksum rejection, truncated-input safety, executable mode,
  and launcher arguments containing spaces.
- Gitea and GitHub `main` matched the implementation commit before release.
  Annotated tag `v0.1.0` resolves to that commit on both hosts.
- GitHub Actions run
  `https://github.com/codegeist-ai/codegeist-devenv/actions/runs/33081157114`
  completed successfully from the mirrored tag and published the release.
- Public release
  `https://github.com/codegeist-ai/codegeist-devenv/releases/tag/v0.1.0`
  exposes exactly `install.sh`, `codegeist-devenv-v0.1.0.zip`, and
  `SHA256SUMS`. Anonymous downloads and the published checksum passed.
- The documented `curl -fsSL .../install.sh | sh` command installed
  `/home/dev/.local/bin/cgenv`. The file is mode `0755`, matches tagged
  `scripts/cgenv` byte-for-byte, resolves through `PATH`, and returns the
  documented usage with exit status `2` for missing arguments.

## File Targets

- `.github/workflows/release.yml`
- `.gitignore`
- `INDEX.md`
- `LICENSE`
- `README.md`
- `Taskfile.yml`
- `docs/architecture.md`
- `docs/tasks/T003_publish_installable_script_release.md`
- `install.sh`
- `tests/release.sh`
- `tools/build-release.sh`

## Dependencies

- Linux with `curl`, `git`, `install`, `mktemp`, `sha256sum`, and Info-ZIP
  `unzip`.
- GitHub Actions enabled on `codegeist-ai/codegeist-devenv`.
- GitHub-hosted runner access to the GitHub CLI and release APIs.
- Gitea push-mirror delivery of the implementation commit and release tag.
- Authenticated Gitea and GitHub sessions for saving the implementation and
  observing or manually dispatching the release workflow.

## Implementation Notes

- Keep the installer pinned to one release instead of adding a general version
  resolver. A future release updates the version constant before tagging.
- Copy the committed root `install.sh` into the release output; do not introduce
  a generated installer template for the initial release or copy the installer
  into the ZIP.
- Keep all release URLs explicit inside `install.sh`; execution through a pipe
  provides no reliable installer file location.
- Use Git's built-in ZIP archive support so the release build does not require a
  separate `zip` package.
- Keep `SHA256SUMS` as a separate release asset and verify the archive before
  extraction.
- Preserve a single publication implementation in GitHub Actions. The manual
  workflow trigger is only a fallback for a missing mirror-generated tag event.
- Keep release diagnostics free of tokens, credentials, private URLs, and raw
  environment dumps.
- Do not modify `scripts/cgenv` unless installer verification exposes a real
  launcher defect.

## Open Questions

- `none`

## Cancellation Reason

- `none`
