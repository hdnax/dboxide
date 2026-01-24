# Coding Conventions

Official site: [Link](https://rust-analyzer.github.io/book/contributing/style.html).

## General Philosophy

- `rust-analyzer`'s approach to clean code:
  - Velocity over perfection: Do not block functional PRs on purely stylistic changes.
  - "Show, don't just tell": For complex style issues, reviewers are encouraged to merge the PR and then send a follow-up cleanup PR themselves. This resolves the issue faster and teaches the author "by example" rather than through endless comment threads.
- If a review comment applies generally, update the Style Guide instead of leaving a one-off comment. This way, temporary feedback is turned into permanent documentation.
- Small, atomic cleanup PRs (even just renaming a variable) are explicitly encouraged to keep the codebase healthy.
