# Coding Conventions

Official site: [Link](https://rust-analyzer.github.io/book/contributing/style.html).

## General Philosophy

- `rust-analyzer`'s approach to clean code:
  - Velocity over perfection: Do not block functional PRs on purely stylistic changes.
  - "Show, don't just tell": For complex style issues, reviewers are encouraged to merge the PR and then send a follow-up cleanup PR themselves. This resolves the issue faster and teaches the author "by example" rather than through endless comment threads.
- If a review comment applies generally, update the Style Guide instead of leaving a one-off comment. This way, temporary feedback is turned into permanent documentation.
- Small, atomic cleanup PRs (even just renaming a variable) are explicitly encouraged to keep the codebase healthy.

## Scale of Changes

- Generally, small & focused PRs are preferred; but sometimes, that isn't possible.

- `rust-analyzer` categories PRs into 3 groups.

### Internal Changes (Low Risk)

- Definition: Changes confined to the internals of a single component. No `pub` items are changed or added (no changes to the interfaces and no new dependencies).
- Review standard: Easy Merge.
  - Does the happy path work?
  - Are there tests?
  - Does it avoid panicking on the unhappy path?

### API Expansion (Medium Risk)

- Definition: Adding new `pub` functions or types that expose internal capabilities to other crates.
- Review standard: High scrutiny.
  - The interface matters more than the implementation. It must be correct and future-proof.
- `rust-analyzer`'s guideline: If you start a "Type 1" change and realize you need to change the API, stop. Split the API change into its own separate, focused PR first.

### Dependency Changes (High Risk)

- Definition: Introducing new connections between components via pub use re-exports or `Cargo.toml` dependencies.
- Review standard: Rare & dangerous.
  - These break encapsulation.
  - Even an innocent-looking `pub use` can accidentally degrade the architecture by leaking abstractions across boundaries.
