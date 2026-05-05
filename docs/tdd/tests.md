# Tests

> Reference: adapted from mattpocock/skills — tdd/tests.md

## Testing Philosophy

- **Test behavior, not implementation** — the test should pass as long as the
  contract is met, regardless of internal changes
- **Public interface only** — if you must poke at internals, the design is wrong
- **One assertion family per test** — test one logical behavior, not one line

## Test Structure

```
describe("feature or module")
  describe("scenario or state")
    it("expected behavior")
```

## Types of Tests

| Type | Scope | Speed | Confidence |
|------|-------|-------|------------|
| Unit | Single module | Fast | Low (isolated) |
| Integration | Module + real deps | Medium | Medium |
| E2E | Full system | Slow | High |

**Rule of thumb**: prefer integration tests over unit tests for business logic.
Save unit tests for complex algorithmic code with many edge cases.

## Test Smells

- **Test needs to know internals**: the module is too shallow
- **Test is hard to set up**: the module has too many dependencies
- **Test is fragile (breaks on refactor)**: testing implementation, not behavior
- **Multiple mocks in one test**: testing too many things at once
- **Test has logic (if/for/switch)**: the test itself should be linear

## Coverage

- 100% coverage is a trap — it usually means testing getters/setters
- Focus coverage on business logic, error paths, and edge cases
- Infrastructure glue code (config, DI, routing) needs less coverage
