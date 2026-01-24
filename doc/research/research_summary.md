# Research Summary

## Compiler Architecture

1. `rust-analyzer`'s high-level architecture, from low-level to higher-level<sup>[1](#1)</sup>:
    1. `parser` crate: A recursive descent parser that is tree-agnostic and event-based.
    2. `syntax` crate: Syntax tree structure & parser that exposes a higher-level API for the code's syntactic structure.
    3. `base-db` crate: `salsa` integration, allowing for incremental and on-demand computation.
    4. `hir-xxx` crates: Program analysis phases, explicitly integrating incremental computation.
    5. `hir` crate: A high-level API that provides a static, inert and fully resolved view of the code.
    6. `ide` crate: Provide high-level IDE features on top of `hir` semantic model, speaking IDE languages (such as texts and offsets instead of syntax nodes).
    7. `rust-analyzer`: The language server, knowing about LSP and JSON.

## Design Choices & General Architectures

1. Making a type serializable may seem trivial in Rust, Javascript, etc. but blindly doing it may cause the client to accidentally depend on the internal details of the type. This restricts flexibility and introduces compatibility issues<sup>[1](#1)</sup>.
2. Defining API boundaries (the contract) to create strict, opaque borders between system layers (e.g., `ide` vs. `hir`) that hide implementation details, allowing internal logic to change radically without breaking external consumers<sup>[1](#1)</sup>.
3. Defining architecture invariants (the law) to enforce non-negotiable structural rules (e.g., "core crates never do I/O" or "no bootstrapping") that permanently guarantee critical system properties like speed or reliability against codebase decay<sup>[1](#1)</sup>.

## Testing

1. Tests can be data-driven, avoiding complex API setups to insulate tests from API changes<sup>[1](#1)</sup>.

## References

1. [`rust-analyzer` high-level architecture and conventions](../research/resources/rust-analyzer/high_level_architecture_and_conventions.md) <a id="1"></a>
