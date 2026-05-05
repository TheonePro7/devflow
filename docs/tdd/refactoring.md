# Refactoring

> Reference: adapted from mattpocock/skills — tdd/refactoring.md

Refactoring is changing structure without changing behavior.

## The Refactoring Cycle

1. **Identify the smell** — duplication, long method, large class, etc.
2. **Verify test coverage** — tests pass before refactoring starts
3. **Apply the refactoring** — one small transformation at a time
4. **Verify tests still pass** — after EACH transformation

## Safe Refactoring Rules

- **ONE change at a time** — rename, then extract, then move. Never combine.
- **Never change behavior and structure in the same step**
- **If tests fail, revert the last change** — not everything (undo one step)
- **Use the IDE/source control** — rename, extract method, move to file

## Common Refactorings

| Smell | Refactoring |
|-------|-------------|
| Duplicate code | Extract function / Extract class |
| Long method | Extract smaller methods |
| Large class | Extract class / Extract module |
| Too many params | Introduce parameter object |
| Switch/if chain | Replace with polymorphism / strategy |
| Primitive obsession | Create value object |

## When refactoring IS the task

If you run TDD and the RED step is "refactor this module," then:
1. Start with GREEN (existing tests pass)
2. Refactor step by step, verifying tests after each
3. You end at GREEN with different code
