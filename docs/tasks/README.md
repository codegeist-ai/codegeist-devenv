# Task Docs

This directory stores lightweight implementation specifications that can be
resumed across development sessions. Task documents complement the current
architecture documentation; they do not replace user-facing product docs.

## Conventions

- Top-level tasks use `TNNN_<slug>.md`, starting at `T001`.
- Child tasks use ids such as `T001_01` and live below the owning task's
  `tasks/` directory.
- A task is represented either by a standalone Markdown file or by `task.md`
  inside a task directory, never both.
- Durable task text stays in English and must be suitable for the public Git
  mirror.
- `Tracking` contains an issue URL when one exists and `none` while no external
  tracker owns the task.

## Status Values

- `open` - accepted work that still needs specification.
- `specified` - scope and acceptance criteria are clear enough to implement.
- `in progress` - implementation is active.
- `blocked` - a named dependency or decision prevents implementation.
- `solved` - implementation and required verification are complete.
- `finalized` - review and required handoff are complete.
- `cancelled` - the task will not be implemented and records why.

## Workflow

- Use `/task spec` to create or refine a task without changing runtime files.
- Use `/task impl` to implement a sufficiently specified task and record its
  verification.
- Keep scope, acceptance criteria, file targets, non-goals, and open questions
  current when requirements change.
- Add child tasks only when separate implementation slices materially improve
  clarity or resumability.
