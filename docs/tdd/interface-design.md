# Interface Design

> Reference: adapted from mattpocock/skills — tdd/interface-design.md

Interfaces are contracts. Design them for the caller, not the implementer.

## Principles

1. **Least surprise** — the interface should behave how it reads
2. **Single responsibility** — one interface, one concern
3. **Minimal surface area** — every method is there for a reason
4. **Composable** — interfaces combine, not inherit

## Interface Smells

- `I*Manager`, `I*Service`, `I*Util` — vague naming, unclear responsibility
- Methods with 3+ parameters — bundle into a parameter object
- Boolean parameters — they create branching behavior, split the method instead
- `void` returns that mutate state — prefer returning a new value

## Design Process

1. Write the calling code first (how you WANT to use it)
2. Extract the interface from the calling pattern
3. Implement against the interface

## TDD Interface Flow

- Red: write test calling the ideal interface
- Green: implement minimally against that interface
- Refactor: improve implementation without changing the interface
