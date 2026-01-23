# dboxide

A (second & likely not the last 🐱) rewrite of the DBML parser that tries to apply the past experiences with the noobie `@dbml/parse` package.

## Targets

- Decent architecture and design
  - Interleaved phases: Implement on-demand, query-based lexing, parsing, name resolution, interpretation, etc. to replace rigid compiler stages (like Rust's `salsa`).
  - Lossless syntax representation: Implement a Red-Green tree structure to maintain a full-fidelity, lossless CST that elegantly handles trivia (whitespace, comments) and error tokens.
  - Rust-inspired internals: Research and adopt high-performance patterns for CST and syntax token representation from the Rust compiler.
- Resilience and error handling
  - Elegant resilience: Develop a resilient parsing strategy that recovers gracefully from syntax errors without compromising the logic's elegance.
  - Diagnostic excellence: Implement good error recovery, leveraging best practices for clear error codes and user-friendly diagnostic messages.
- Performance and Incrementalism:  Ensure the compiler is optimized for modern IDE workloads and multi-core environments.
  - Efficient incrementalism: Enable incremental parsing with optimized position (re)computation for syntax nodes and tokens to minimize re-work during typing.
  - Parallel execution: Architect the parser to support parallel execution, maximizing throughput for large-scale codebases.

## Context

The DBML parser was rewritten once around 2023 when I was an intern at Holistics. The original parser was a PEG.js parser.

The main reasons I was assigned to the DBML parser rewrite were (I believe):
- I was an intern at another team that worked solely on the AML language. It was a more complex language so probably, the others thought that a simpler language like DBML was a good task.
- The Peg.js parser had some problems:
  - Slow: I don't think that this is the inherent property of parser combinators. One argument I can come up with to support this idea is that parser combinators tend to have excessive function calls. However, in a compiled language like C++, would this overhead be reduced by inlining or some more sophisticated optimization?
  - Bailing out upon the first error: It didn't implement resilient parsing. Therefore, language services like suggestion is harder to implement, because most of the time when you need suggestion/auto-completion, the source file itself can contain lots of errors.

Since the first version of `@dbml/parse`, there has been some impact, but a lot are left to be desired.

### The Impact

- Performance: Although `@dbml/parse` waas just a naive rewrite, it was already 7 times faster than the Peg.js parser.
- Language services: `@dbml/parse` provides language services like suggestion, go to definition and go to references.
- Resilient parsing: Multiple error messages are allowed. Suggestion works even if the source file is partially broken.

### The Pain

During the first launch, `@dbml/parse` broke a lot of user's code, mainly because the Peg.js parser was too lax that it allowed undocumented/legacy syntax I was not aware of.

Since then, I encountered a lot of pain arising from my poor design choices and the way I wrote tests:
- Fragile snapshot testing: Using snapshots as a shortcut for unit tests led to capturing entire CSTs. This created brittle, 2,000+ line test files where trivial internal changes triggered massive diffs, making genuine regression detection nearly impossible.
- Poor abstraction/Misuse of design patterns: Forcing name resolution and validation into a Template Method pattern created tight coupling. The base class became a bloated, incomprehensible mess of "hooks" and "configs" to handle slight variations in logic across unrelated components.
- Excessive type assertions: Heavy reliance on TypeScript as assertions bypassed the type system, leading to avoidable runtime bugs that the compiler should have caught.
- Lack of type-driven validation (Parse, not validate): The parser was too lax, yielding a generic CST rather than a refined IR. Because validation didn't transform the data into a "known-good" structure, subsequent phases were forced to re-validate or rely on unsafe type assertions.
- The syntax tokens and nodes positions are precomputed, making CST patches almost always invalidate the positions & incremental parsing partly impossible.

Some are minor issues:
- Error messages & error codes in `@dbml/parse` are a mess.
- No linter setup.
