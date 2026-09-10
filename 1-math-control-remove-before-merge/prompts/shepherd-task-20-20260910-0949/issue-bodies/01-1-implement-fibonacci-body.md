## Campaign context and required reading

On the `experiment/shepherd-control` branch, the directory `1-math-control-remove-before-merge` contains the plan (`math-tool-ignorance-reduction-plan.md`) and supporting resources (diagrams, decision records). Spike subdirectories are research artifacts — read the plan's Resolution sections for findings, not the spike source code.

Before changing code, read the entire plan. Then carefully re-read these exact sections:

- `## Ignorance reduction`
- `### Repository-owned validation`
- `### Output and ordering contracts`
- `## Implementation`
- `### 1. Implement Fibonacci with unit and isolated CLI coverage`

Carry these resolved decisions into the implementation:

- Repository acceptance is defined by `pwsh -NoLogo -NoProfile -File ./eng/test-math-tool.ps1`. The committed workflow `.github/workflows/shepherd-task-math-tool.yml` installs exactly Pester 5.7.1 and invokes that runner; do not replace or bypass either contract.
- Direct CLI execution writes exactly one result line to stdout in the form `Fibonacci(N) = value`.
- `Get-Fibonacci` returns only the numeric value, with no incidental output.
- Inputs are non-negative integers.
- Production and test files are the repository-root files `math-tool.ps1` and `math-tool.Tests.ps1`.
- The tasks are assigned, completed, and merged serially in plan order. This is task 1; task 2 must not begin until this task is merged.

The plan records no separate spike implementation to reuse. Implement production behavior from the resolved contracts above and do not copy or adapt research-artifact source code or test helpers.

## Branch and execution order

Target `experiment/shepherd-control` as the PR base branch. Do not work from or target `main`.

No work starts until this issue is assigned to the coding agent. This issue is the first serial task. Complete it and merge its PR to `experiment/shepherd-control` before the factorial/dispatch task is assigned.

## Implement

Create `math-tool.ps1` and `math-tool.Tests.ps1` together.

In `math-tool.ps1`:

- Declare a script parameter named `N` that accepts non-negative integer input.
- Implement a pure `Get-Fibonacci` function that deterministically returns the Fibonacci number for the supplied `N`.
- Ensure dot-sourcing the script exposes the function for unit testing without emitting CLI output.
- When the script is executed directly, emit exactly one stdout line: `Fibonacci(N) = value`, substituting the requested input and computed result.
- Do not emit progress, labels, debug text, or other incidental pipeline output from the function or direct invocation.

In `math-tool.Tests.ps1`, use Pester 5.7.1-compatible tests:

- Dot-source the production script and test `Get-Fibonacci` directly for `N=0`, `N=1`, and at least one small representative input greater than 1.
- Invoke a separate child `pwsh` process for direct-CLI tests so dot-sourcing cannot satisfy the CLI assertions accidentally.
- Assert successful child-process exit and exact stdout for `N=0`, `N=1`, and a small representative input.
- Assert the CLI produces one non-empty result line and no additional stdout.
- Exercise the repository's non-negative-integer boundary so unsupported negative input is rejected rather than computed.

Follow existing repository conventions and keep the implementation objective and small.

## Completion gates

- `math-tool.ps1` and `math-tool.Tests.ps1` both exist at the repository root.
- Function tests demonstrate the base cases and recurrence result without incidental function output.
- Isolated child-process tests distinguish direct execution from dot-sourcing and verify exact output formatting.
- `pwsh -NoLogo -NoProfile -File ./eng/test-math-tool.ps1` exits zero.
- The pinned pull-request workflow passes with Pester 5.7.1.
- The PR targets `experiment/shepherd-control`, contains only this task's scoped changes, and leaves the repository ready for the serial factorial/dispatch task.

## Out of scope

- Do not add factorial or operation dispatch; those belong to task 2.
- Do not change `eng/test-math-tool.ps1`, the pinned Pester version, or `.github/workflows/shepherd-task-math-tool.yml`.
- Do not add unrelated operations, UI, packaging, dependencies, generated artifacts, or broad repository refactors.
- Do not read, copy, or adapt spike source code or spike test infrastructure.
