# Contributing to Port Sheriff

Thanks for your interest. This document covers the workflow, code style, and what to expect from a PR.

## Workflow

1. Open an issue describing the bug or feature before large changes.
2. Fork the repo and create a feature branch off `main`.
3. Make focused commits using [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `chore:`, `refactor:`, `test:`, `docs:`).
4. Run `swift build` and `swift test` locally — both must be green.
5. Open a PR. Describe what changed and why. Link the issue.

## Code style

- Swift 6, strict concurrency on.
- Public API in `PortSheriffKit` must be `Sendable` where it crosses an isolation boundary.
- Prefer `@Observable` and `@MainActor`-isolated classes over `ObservableObject`.
- Views live in `Sources/PortSheriffKit/Views/`. One view per file.
- Services live in `Sources/PortSheriffKit/Services/`. Statics for pure logic; instance methods for stateful operations.
- Tests use `swift-testing` (`@Suite`, `@Test`, `#expect`).
- Follow existing patterns. If you need a new pattern, mention it in the PR description.

## What gets accepted

- Bug fixes with a reproducing test.
- New rule matcher types, view polish, and accessibility improvements.
- Performance improvements with benchmark numbers.

## What does not

- Adding network calls or telemetry.
- Adding runtime dependencies without strong justification.
- Reformatting unrelated files.
- Cosmetic-only changes without functional impact.

## Releasing (maintainers)

1. Bump version in `CHANGELOG.md` and move `[Unreleased]` entries under the new tag.
2. Tag the commit: `git tag -a vX.Y.Z -m "Release vX.Y.Z"`.
3. Push the tag: `git push origin vX.Y.Z`.
4. The CI release workflow builds the `.app`, notarizes (if certs are configured), and attaches the artifact to the GitHub release.
