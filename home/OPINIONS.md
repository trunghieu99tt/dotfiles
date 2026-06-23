# Elliot's opinions

This file captures Elliot's technical and product viewpoints so agents can make decisions that match how he actually thinks.
Read it when a task involves a judgment call, a tradeoff, or a "how would Elliot want this done" moment.

This is a living document. Edit freely. Delete anything that stops being true.

## Engineering philosophy

- Optimize for the reader, not the writer. Code is read far more often than it is written.
- Prefer boring, proven technology over novel tech unless the novelty directly solves the problem.
- Simplicity beats cleverness. If a junior engineer cannot follow it, it is too clever.
- Make the change easy, then make the easy change. Refactor first if it unblocks a clean fix.
- Delete code aggressively. The best code is no code.

## Code style

- Small, focused functions and modules with clear single responsibilities.
- Name things for what they mean, not how they are implemented.
- Comments explain "why", not "what". The code already says what.
- Fail loudly and early at system boundaries. Do not paper over unexpected states.
- Avoid premature abstraction. Wait for the third repetition before extracting a helper.

## Architecture

- Push complexity to the edges; keep the core domain logic pure and testable.
- Prefer explicit data flow over hidden global state.
- Design for deletion and replacement, not just extension.
- Make illegal states unrepresentable with types where the language allows it.

## Testing

- Tests should describe behavior, not implementation details.
- Prefer a few high-value end-to-end tests over many brittle unit tests for user-facing flows.
- A flaky test is a failing test. Fix it or delete it, never ignore it.
- Reproduce bugs with a test before fixing them.

## Product and UX

- Default to the choice that needs the least explanation to the user.
- Pixel perfection matters. Sloppy UI signals sloppy thinking.
- Fast and correct beats feature-rich and confusing.
- Respect the user's time, attention, and data.

## Tools and dependencies

- Every dependency is a liability. Justify it before adding it.
- Pin versions and keep them current; do not let them drift silently.
- Prefer the standard library and platform primitives when they are good enough.

## Dealing with tradeoffs

- When two options are close, pick the one that is easier to reverse.
- When unsure, optimize for long term maintainability over short term speed.
- Document the tradeoff in the PR description so future readers understand the "why".
