## Campaign context and required reading

On the `experiment/shepherd-control` branch, the directory `1-math-control-remove-before-merge` contains the plan (`math-tool-ignorance-reduction-plan.md`) and supporting resources (diagrams, decision records). Spike subdirectories are research artifacts — read the plan's Resolution sections for findings, not the spike source code.

Before changing code, read the entire plan. Then carefully re-read these exact sections:

- `## Ignorance reduction`
- `### Repository-owned validation`
- `### Output and ordering contracts`
- `## Implementation`
- `### 1. Implement Fibonacci with unit and isolated CLI coverage`
- `### 2. Add factorial and operation dispatch`

Carry these resolved decisions into the implementation:

- Repository acceptance is defined by `pwsh -NoLogo -NoProfile -File ./eng/test-math-tool.ps1`. The committed workflow `.github/workflows/shepherd-task-math-tool.yml` installs exactly Pester 5.7.1 and invokes that runner; do not replace or bypass either contract.
- Direct CLI execution writes exactly one result line to stdout: either `Fibonacci(N) = value` or `Factorial(N) = value`.
- `Get-Fibonacci` and `Get-Factorial` return only numeric values, with no incidental output.
- Inputs are non-negative integers.
- Production and test files remain the repository-root files `math-tool.ps1` and `math-tool.Tests.ps1`.
- The tasks are assigned, completed, and merged serially in plan order. This is task 2 and starts only after task 1 is merged into `experiment/shepherd-control`.

The plan records no separate spike implementation to reuse. Implement production behavior from the resolved contracts above and do not copy or adapt research-artifact source code or test helpers.

## Branch and execution order

Target `experiment/shepherd-control` as the PR base branch. Do not work from or target `main`.

No work starts until this issue is assigned to the coding agent, after task 1 has merged. Begin from the resulting `experiment/shepherd-control` state so the Fibonacci implementation and its tests are present. Preserve that behavior while completing this second and final serial task.

## Implement

Extend the existing repository-root `math-tool.ps1`:

- Add a pure `Get-Factorial` function for non-negative integer input.
- Add an `Operation` parameter that accepts the supported operations `fibonacci` and `factorial` and dispatches to the corresponding pure function while retaining `N`.
- Preserve the task-1 Fibonacci interface and behavior; invocation without a new operation argument must continue to perform Fibonacci, while explicit `fibonacci` dispatch must behave identically.
- Direct Fibonacci execution must emit exactly `Fibonacci(N) = value`; direct factorial execution must emit exactly `Factorial(N) = value`.
- Keep function return values numeric and free of labels or other incidental output. Direct execution must emit exactly one result line.
- Reject unsupported operations and inputs outside the resolved non-negative-integer contract rather than silently selecting or computing another result.

Extend `math-tool.Tests.ps1` using Pester 5.7.1-compatible tests:

- Preserve all Fibonacci unit and isolated CLI regression coverage from task 1.
- Dot-source the production script and test `Get-Factorial` directly for `N=0`, `N=1`, and at least one small representative input greater than 1.
- Use isolated child `pwsh` processes to test factorial dispatch for the same edge and representative cases, asserting successful exit and exact stdout.
- Add explicit Fibonacci dispatch coverage and verify it matches the preserved default Fibonacci behavior.
- Assert each successful CLI path produces one non-empty stdout line and no additional stdout.
- Cover rejection of an unsupported operation without weakening the existing non-negative-integer boundary.

Keep the interface and tests objective and small.

## Completion gates

- Factorial unit tests establish `0! = 1`, `1! = 1`, and a representative multiplication result.
- Dispatch tests discriminate `fibonacci` from `factorial`, verify exact operation-specific output labels, and prevent accidental fallback for unsupported operations.
- The complete task-1 Fibonacci suite remains green, including direct invocation without an operation argument.
- Functions produce numeric values without incidental output, and successful CLI execution produces exactly one result line.
- `pwsh -NoLogo -NoProfile -File ./eng/test-math-tool.ps1` exits zero for the combined regression suite.
- The pinned pull-request workflow passes with Pester 5.7.1.
- The PR targets `experiment/shepherd-control` and contains only the scoped factorial, dispatch, and test changes.

## Out of scope

- Do not add operations other than Fibonacci and factorial.
- Do not rename or relocate `math-tool.ps1`, `math-tool.Tests.ps1`, or the existing `Get-Fibonacci` function.
- Do not change `eng/test-math-tool.ps1`, the pinned Pester version, or `.github/workflows/shepherd-task-math-tool.yml`.
- Do not add UI, packaging, dependencies, generated artifacts, performance-oriented rewrites, or unrelated refactors.
- Do not read, copy, or adapt spike source code or spike test infrastructure.
