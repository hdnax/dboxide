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

## Crates.io Dependencies

- Restrict external dependencies: Be extremely conservative with `crates.io` usage to minimize compile times and breakage risks.
- Do not use small "helper" libraries (allowed exceptions: `itertools`, `either`).
- Internalize utilities: Place general, reusable logic into the internal `stdx` crate rather than adding a dependency.
- Audit dependency tree: Periodically review `Cargo.lock` to prune irrational transitive dependencies.

### Rationale

- Compilation speed:
  - Rust compiles dependencies from source.
  - Avoiding bloat is the best way to keep build times and feedback loops fast.
- Transitive bloat:
  - Small "helper" crates often pull in deep chains of hidden dependencies (the "iceberg" effect).
- Stability & Security:
  - Reduce the risk of upstream abandonment, breaking changes, or supply chain attacks.
- Self-reliance: If logic is simple enough for a micro-crate, it belongs in the internal `stdx` library, not as an external liability.

## Commit Style

- Document for changelogs to avoid release burden on the maintainers.
- Changelogs > Clean history.

### Git History

- Clean git history is strongly encouraged but not mandated.
- Use a rebase workflow. It is explicitly acceptable to rewrite history (force push) during the PR review process.
- Before the final merge, use interactive rebase to squash small "fixup" commits into logical units.

### Commit Message & PR Description

- Do not `@mention` users in commit messages or PR descriptions.
  - Reason: Rebasing re-commits the message, spamming the mentioned user with duplicate notifications.
- User-centric titles: Write PR titles/descriptions describing the user benefit, not the implementation details.
  - Good: "Make goto definition work inside macros".
  - Bad: "Use original span for `FileId`".
- Changelog automation: You must categorize PRs so release notes can be auto-generated. Use one of two methods:
  - Title prefix: `feat:`, `fix:`, `internal:`, or `minor:` (e.g., `feat: Add hover support`).
  - Magic comment: `changelog [fix] Description here in the PR body`.
- Visuals: For UI changes, include a GIF in the description to demonstrate the feature.

## Linting

- Clippy is used.

## Code

### Minimal Tests

- Tests must use the absolute minimum code necessary to reproduce the case. Aggressively strip "noise" from copy-pasted real-world code.
- Format declarative code densely (e.g., `enum E { A, B }` on a single line) to keep the test concise, provided it remains readable.
- Unindented raw strings: Use `r#...#` literals for multiline fixtures. Ensure the content is unindented (starts at column `0`) so that character offsets in the test match the actual file positions exactly.
- Rationale:
  - Reduce visual noise and scrolling, making the actual test case immediately obvious.
  - Lower execution time and keeps debug logs clean.
  - Unindented formatting allows you to use your editor's "selection character count" to verify byte offsets directly, without needing to manually subtract indentation whitespace.

### Marked Tests

- Marked test: A technique used to verify that a specific, often hard-to-reach line of code was actually executed during a test.
- Use `cov_mark::hit!` (in code) and `cov_mark::check!` (in tests) to create a strictly unique link between a specific edge case in the implementation and its corresponding test.
- Principle: Only maintain one mark per test and one mark per code branch.
- Never place multiple marks in a single test, and never reuse the same mark across different tests.
- Rationale: This ensures that searching for a mark immediately reveals the single canonical test responsible for verifying that specific code branch, eliminating ambiguity.

### `#[should_panic]`

- `#[should_panic]` is prohibited - `None` and `Err` should be explicitly checked.
- Rationale:
  - `#[should_panic]` is a tool for library authors to make sure that the API does not fail silently when misused.
  - `rust-analyzer` is a long-running server, not a library. It must handle all input gracefully, even invalid input (returning `Err` or `None`). It should never intentionally crash.
  - Expected panics still dump stack traces into the test logs. This "noise" creates confusion, making it difficult to distinguish between a test verifying a panic and an actual bug causing a crash.
  - Expected panics still dump stack traces into the test logs. This "noise" creates confusion, making it difficult to distinguish between a test verifying a panic and an actual bug causing a crash.

### `#[ignore]`

- Never ignore tests. Explicitly assert the wrong behavor and add a `FIXME` comment.
- Rationale:
  - Visibility: It ensures the test fails immediately if the bug is accidentally fixed (alerting you to update the test).
  - Safety: It proves the bug causes incorrect output rather than a server crash (panic), which is a critical distinction for a long-running service.

### Function Preconditions

#### Type Encoding

- Function's assumptions should be expressed in types.
- The caller must be enforced to provide them.

```rust
// GOOD
fn is_zero(n: i32) -> bool {
  ...
}

// BAD
fn is_zero(n: Option<i32>) -> bool {
   let n = match n {
       Some(it) => ...,
       None => ...,
   };
}
```

- Rationale:
  - The caller has more context as to why to the callee's assumptions do not hold.
  - The control flow is therefore more explicit at the call site.

#### Parse, Don't Validate

- Bad practice:
  - One function validates that the data is valid (validate the assumption).
  - Another function uses that data based on the assumptions.
- Good practice: Validate and immediately use the data in the same place (like `match` instead of bare `if`).

- Reasons:
  - The bad practice is prone to decay over time. The maintainer has to memorize the assumptions and make sure refactoring efforts of checks actually verify the assumptions.
  - The good practice always ensure that the assumptions hold when manipulating the data.

- Example from `rust-analyzer`
  ```rust
  // GOOD
  fn main() {
      let s: &str = ...;
      if let Some(contents) = string_literal_contents(s) {
  
      }
  }
  
  fn string_literal_contents(s: &str) -> Option<&str> {
      if s.starts_with('"') && s.ends_with('"') {
          Some(&s[1..s.len() - 1])
      } else {
          None
      }
  }
  
  // BAD
  fn main() {
      let s: &str = ...;
      if is_string_literal(s) {
          let contents = &s[1..s.len() - 1];
      }
  }
  
  fn is_string_literal(s: &str) -> bool {
      s.starts_with('"') && s.ends_with('"')
  }
  ```

- Remarks:
  - This pattern perfectly illustrates Robert Harper's concept of "Boolean Blindness". By reducing a complex check to a simple bool (true/false), we discard the proof of validity. The compiler sees a "true" flag, but it doesn't see the "valid data," forcing us to rely on faith later in the code.
  - I learned this the hard way while building a DBML parser. I designed a system where the "validation phase" was separate from the "execution phase". Because the validation step didn't return a new, safe type (it just returned true), the execution phase had to blindly trust that the validation had run correctly.
  - While systems like TypeScript uses Flow Typing to mitigate this (by inferring types inside `if` blocks), that safety is often local only. As soon as you pass that variable into a different function, the "flow context" is lost unless explicitly redefined.

### Control Flow

- Push "if"s up and "for"s down.

### Assertions

- Use `stdx::never!` liberally instead of `assert!`.
- `never!` checks a condition and logs a backtrace if it fails, but returns a `bool` instead of crashing. This allows you to write: `if stdx::never!(condition) { return; }`.
- Rationale: `rust-analyzer` is a long-running server. A bug in a minor feature (like a specific completion) should **log an error** and bail out of that specific request, not **crash** the entire IDE session.

### Getters & Setters

- Two cases to consider:
  - No invariants: If a field can hold any value safely, just make it `pub`. Don't write boilerplate code.
  - Invariants exist: If the data has rules (e.g., "cannot be empty"), make the field private, enforce the rule in the Constructor, and provide a Getter.
- Never provide setters. If data needs to change, it should likely be done via a specific behavior method or by creating a new instance, ensuring invariants are never bypassed.

- Getters should return borrowed data. `rust-analyzer`'s example:
  ```rust
  struct Person {
    // Invariant: never empty
    first_name: String,
    middle_name: Option<String>
  }
  
  // GOOD
  impl Person {
      fn first_name(&self) -> &str { self.first_name.as_str() }
      fn middle_name(&self) -> Option<&str> { self.middle_name.as_ref() }
  }
  
  // BAD
  impl Person {
      fn first_name(&self) -> String { self.first_name.clone() }
      fn middle_name(&self) -> &Option<String> { &self.middle_name }
  }
  ```
- Rationale:
  - The APIs are internal so (internal) breaking changes can be allowed to move fast:
    - Using a `pub` field (with no invariants) introduces less boilerplate but may be breaking if the `pub` field is suddenly imposed an invariant and has to be changed to private.
    - Using an accessor can prevent breaking changes, but it means implicitly promising a contract and imposing some maintenance boilerplate.
  - Privacy helps make invariants local to prevent code rot.
  - A type that is too specific (borrow owned types like `&String`) leaks irrelevant details (neither right nor wrong), which creates noise and the client may accidentally rely on those irrelevent details.

### Useless Types

- Prefer general types.
- If generality is not important, consistency is important.

```rust
// GOOD      BAD
&[T]         &Vec<T>
&str         &String
Option<&T>   &Option<T>
&Path        &PathBuf
```

- Rationale:
  - General types are more flexible.
  - General types leak fewer irrelevant details (which the client may accidentally rely on).

### Constructors

- If a `new` function accepts zero arguments, then use the `Default` trait (either derive or manually implemented).
  - Rationale:
    - Less boilerplate.
    - Consistent: Less cognitive load for the caller - "Should I call `new()` or `default()`?"
- Use `Vec::new` instead of `vec![]`.
  - Rationale:
    - Strength reduction.
    - Uniformity.
- Do not provide `Default` if the type doesn't have sensible default value (many possible defaults or defaults that has invalid states).
  - Preserve invariants.
  - The user does not need to wonder if the provided default is their desired initial values.

```rust
// GOOD
#[derive(Default)] // 1. Best case: Derive it automatically
struct Options {
    check_on_save: bool,
}

// GOOD (Manual Implementation)
struct Buffer {
    data: Vec<u8>,
}

impl Default for Buffer {
    fn default() -> Self {
        Self {
            // 2. Use Vec::new() instead of vec![] (Strength Reduction)
            // It is semantically lighter (function vs macro) and more uniform.
            data: Vec::new(), 
        }
    }
}

// BAD
struct OptionsBad {
    check_on_save: bool,
}

impl OptionsBad {
    // 3. Avoid zero-arg new(). 
    // It forces users to remember "Do I call new() or default() for this type?"
    fn new() -> Self {
        Self { check_on_save: false }
    }
}
```

### Functions Over Objects

- Public API: Prefer simple functions (`do_thing()`) over transient objects that exist only to execute one method (`ThingDoer::new().do()`).
- Internal logic: It is acceptable (and encouraged) to use "Context" structs *inside* the function to manage complex state or arguments during execution.
- Rationale:
  - The "Iceberg" pattern: The user sees a simple function interface; the developer uses a structured object implementation behind the scenes.
  - Implementor API is not mixed with user API.
- Middle ground: If a struct is preferred for namespacing, provide a static `do()` helper method that handles the instantiation and execution in one step.
- Rationale:
  - Reduce boilerplate for the caller.
  - Prevent implementation details (like temporary state management) from leaking into the public API.

```rust
// BAD (Caller has to build and run)
ThingDoer::new(arg1, arg2).do();

// GOOD (Caller just acts)
do_thing(arg1, arg2);

// ACCEPTABLE INTERNAL IMPLEMENTATION (Using a struct to organize code)
pub fn do_thing(arg1: Arg1, arg2: Arg2) -> Res {
    // The struct is an implementation detail, hidden from the user
    let mut ctx = Ctx { arg1, arg2 };
    ctx.run()
}
```
