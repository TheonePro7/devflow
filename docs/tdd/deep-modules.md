# Deep Modules

> Reference: adapted from mattpocock/skills — tdd/deep-modules.md

A module is "deep" when it hides complex implementation behind a simple,
stable interface. Shallow modules expose most of their complexity.

## Signs of Shallow Modules

- Public methods that expose internal data structures
- Callers needing to understand internals to use the module
- Configuration options that leak implementation details
- Tests reaching into private state

## Designing Deep Modules

1. **Define the interface first** — what does the caller need? Nothing else.
2. **Hide implementation** — all internal complexity behind private functions/methods
3. **One decision per module** — a module should encapsulate one design decision
4. **Stable interface** — the interface changes slower than the implementation

## Testing Deep Modules

- Test only through the public interface
- If a test needs to inspect internals, the module is probably too shallow
- Integration tests > unit tests for deep modules (they test the contract)
