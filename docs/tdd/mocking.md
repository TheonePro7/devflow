# Mocking

> Reference: adapted from mattpocock/skills — tdd/mocking.md

Mock only at system boundaries.

## When to Mock

- External I/O (network, filesystem, database)
- Time-dependent operations
- Third-party services with non-deterministic responses

## When NOT to Mock

- Internal collaborators (refactor to pass results, not mocks)
- Value objects (use real instances)
- Simple queries with no side effects (test the real thing)

## Principles

1. **Mock roles, not objects** — mock the interface/contract, not the class
2. **Integration tests over mocked units** — a mocked test passing + real integration failing = false confidence
3. **Coarse-grained mocks** — mock at the service boundary, not every method call
4. **Prefer fakes over mocks** — an in-memory implementation is more valuable than a mock

## Anti-patterns

- Mocking the system under test's own internals
- Mocking value objects (`new Mock<User>()`)
- Over-specifying mock interactions (testing HOW not WHAT)
