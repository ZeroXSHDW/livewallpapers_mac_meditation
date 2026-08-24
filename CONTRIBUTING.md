# Contributing — Live Wallpapers Mac Meditation

## Before changing code

Read the repository README and inspect the current branch before editing. Keep changes focused, preserve user work, and do not commit secrets, generated output, host-specific paths, credentials, device identifiers, or unrelated formatting churn.

## Verification

Run the strongest documented local gate before requesting review:

- run `make quality` (offline manifest validation, ShellCheck, regression
  contracts, and whitespace checks);
- run `make patch-hygiene` when you need the standalone whitespace/conflict-marker
  check;
- run the repository's documented test, lint, type-check, build, audit, or shell-validation commands;
- add or update a regression test for every repaired contract or failure path;
- confirm documentation, examples, links, and configuration match the implementation.

The CI workflow uses Ubuntu 24.04 and runs the patch-hygiene check immediately
after checkout, before installing ShellCheck or running repository checks.

If an external service, device, GPU, cloud credential, or CI account limit prevents a check, record the exact blocker in the pull request and complete every safe local equivalent. Do not weaken a check, hide a warning, or add an unjustified skip to obtain a pass.

## Pull requests

Explain the problem, root cause, files changed, verification performed, security or compatibility impact, and remaining limitations. Keep the pull request independently reviewable. A maintainer reviews and merges approved changes.
