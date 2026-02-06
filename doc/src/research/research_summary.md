# Research Summary

## Operations

1. **Knowledge transfer**: Study established projects to inherit mature operational workflows.
2. **Institutional memory**: Convert recurring code review feedback into a permanent "living style guide" to scale mentorship and prevent repetitive corrections<sup>[1](#1)</sup>.
3. **Release automation**: Structure commit metadata (titles, messages) to automate downstream documentation (changelogs), reducing manual release overhead<sup>[1](#1)</sup>.

## Code Evolution

1. **Risk segmentation**: Classify changes by impact scope (internal vs. API/dependency) to apply proportional review scrutiny<sup>[1](#1)</sup>.
2. **Dependency minimalism**: Internalize trivial utilities ("micro-dependencies") to reduce supply chain attack surface and compilation bloat<sup>[1](#1)</sup>.
3. **Type-driven correctness**: Prefer parsing data into types that *guarantee* validity over simple validation checks. This eliminates "boolean blindness," where the system loses the proof of validity after the check returns `true`<sup>[1](#1)</sup>.
4. **Compilation optimization**: Restrict heavy generics at system boundaries to prevent "monomorphization bloat," trading minor runtime overhead for significant compile-time gains<sup>[1](#1)</sup>.

## Compiler Architecture

1. `rust-analyzer`'s high-level architecture, from low-level to higher-level<sup>[1](#1)</sup>:
    1. `parser` crate: A recursive descent parser that is tree-agnostic and event-based.
    2. `syntax` crate: Syntax tree structure & parser that exposes a higher-level API for the code's syntactic structure.
    3. `base-db` crate: `salsa` integration, allowing for incremental and on-demand computation.
    4. `hir-xxx` crates: Program analysis phases, explicitly integrating incremental computation.
    5. `hir` crate: A high-level API that provides a static, inert and fully resolved view of the code.
    6. `ide` crate: Provide high-level IDE features on top of `hir` semantic model, speaking IDE languages (such as texts and offsets instead of syntax nodes).
    7. `rust-analyzer`: The language server, knowing about LSP and JSON.

## Token & Node 

1. **Token vs Node representation**<sup>[2](#2)</sup>:
    - **Parser tokens** have tags and their corresponding source text. **Parser nodes** have tags and source length.
    - Children nodes are placed in a homogenous vector.
2. Tokens and nodes share the same `SyntaxKind` enum and are not as distinguished as `@dbml/parse`. In fact, tokens are like leaf nodes, and nodes are like interior nodes.<sup>[2](#2)</sup>
4. **Trivia strategy**: [Explicit nodes](./resources/rust-analyzer/syntax_tree_and_parser.md#dealing-with-trivia) (whitespace/comments as sibling nodes).
   - `rust-analyzer` chooses to not treats trivial and error nodes specially. Everything is uniform.
   - Some (like `@dbml/parse`) attach trivia to the nearest semantic parents.
   - Some use a hybrid approach.
5. **Contextual keywords**: Parser checks actual text via `TokenSource::is_keyword()` for context-sensitive keywords like `union`, `default`<sup>[2](#2)</sup>.
5. **Token ambiguity**: Intermediary layer (`TokenSource`/`TreeSink` traits) merges tokens (`>` + `>` → `>>`) based on context.<sup>[2](#2)</sup>.
6. **Position computation**: Nodes store only `text_len` (not offset), tokens store text. SyntaxNode computes offset on-demand from parent. Enables incremental parsing without position invalidation<sup>[2](#2)</sup>.

## Parsing

1. **Three-layer tree architecture**<sup>[2](#2)</sup>:
    - [**GreenNode (storage)**](./resources/rust-analyzer/syntax_tree_and_parser.md#layer-1-greennode-the-storage): Immutable, persistent. Optimizations: DST (single heap allocation), tagged pointers, token interning, `Arc`-sharing. Stores `text_len`, not offset.
    - [**SyntaxNode (cursor/RedNode)**](./resources/rust-analyzer/syntax_tree_and_parser.md#layer-2-syntaxnode-the-cursor--rednode): Adds parent pointers and on-demand position computation. Memory scales with depth, not tree size. Transient (rebuild from GreenNode when needed).
    - [**AST (typed API)**](./resources/rust-analyzer/syntax_tree_and_parser.md#layer-3-ast-the-api): Auto-generated typed wrappers (`FnDef`, `ParamList`) around `SyntaxNode` for ergonomic access.
2. **Lossless representation**: Everything preserved (whitespace, comments, invalid tokens). Invalid input wrapped in `ERROR` nodes. Original text reconstructable by concatenating token text<sup>[2](#2)</sup>.
3. **Error storage**: Errors live in separate `Vec<SyntaxError>`, not embedded in tree. Enables manual tree construction without error state management. Parser outputs `(green_node, errors)`<sup>[2](#2)</sup>.
4. **Resilient parsing**<sup>[2](#2)</sup>:
    - **Algorithm**: Recursive descent + Pratt parsing (expressions). Permissive (accepts invalid constructs, validated later).
    - [**Event-based architecture**](./resources/rust-analyzer/syntax_tree_and_parser.md#parsing---the-token-sequence-transformer): Parser emits abstract events via `TokenSource` (input) and `TreeSink` (output) traits. Parser agnostic to tree structure.
    - **Error recovery**: Panic mode (skip to sync points like `}`, `;`), implicit closing braces, early block termination, ERROR node wrapping.
5. [**Incremental parsing**](./resources/rust-analyzer/syntax_tree_and_parser.md#incremental-reparse)<sup>[2](#2)</sup>:
    - **Red-Green model**: Green = immutable storage, Red = cursors with positions. Separation enables cheap tree patches (swap GreenNode pointers).
    - [**Block heuristic**](./resources/rust-analyzer/syntax_tree_and_parser.md#incremental-reparse): Reparse smallest `{}` block containing edit. Works because parser maintains structurally balanced braces (implicit `}` insertion, ERROR wrapping for extras).
    - **Pragmatic note**: Often not worth it—full reparse is fast and simpler. Valuable for tree edit cheapness and subtree sharing.
6. [**Error messages**](./resources/rust-analyzer/syntax_tree_and_parser.md#reporting-syntax-errors): Permissive parser + separate validation pass for "soft" errors. Parser focuses on structure recovery; validation uses semantic context for detailed diagnostics<sup>[2](#2)</sup>.

## Design Choices & General Architectures

1. **Abstraction leakage prevention**: Avoid blind serialization of internal types, which implicitly couples public clients to private implementation details<sup>[1](#1)</sup>.
2. **Modular decoupling**: Enforce opaque API boundaries (e.g., between analysis and IDE layers) to enable radical internal refactoring without breaking consumers<sup>[1](#1)</sup>.
3. **System invariants**: Codify architectural laws (e.g., "core layers are I/O free") to permanently guarantee non-functional requirements like speed and deterministic testing<sup>[1](#1)</sup>.
4. **Visual hierarchy**: Order function arguments by stability (context  data). This aligns code structure with mental models ("setting"  "actors") and reduces cognitive load during scanning<sup>[1](#1)</sup>.
5. **Type-level taint analysis**: Use distinct types to segregate unverified external input (e.g., "dirty" OS strings) from validated internal data, preventing logic errors from crossing trust boundaries<sup>[1](#1)</sup>.
6. **State consistency**: Enforce invariants via "construction & retrieval" (private fields + public getters) rather than "mutation" (setters), ensuring objects never enter invalid states<sup>[1](#1)</sup>.
7. **Compile-time contracts**: Encode assumptions into the type system (e.g., non-nullable types) to force callers to handle edge cases explicitly, preserving context at the call site<sup>[1](#1)</sup>.
8. **Parameter object / Command pattern**: Encapsulate complex execution arguments into temporary structs to support multiple execution modes without duplicating function signatures<sup>[1](#1)</sup>.
9. **Control flow divergence**: Split functions with boolean flags (e.g., `do(true)`) into distinct named functions. This adheres to the Single Responsibility Principle and prevents unrelated logic paths from becoming coupled<sup>[1](#1)</sup>.

### Implementation Patterns

1. **Computational density**: Prioritize imperative clarity over functional brevity. Code should maximize "work per line" rather than minimizing line count via complex indirections<sup>[1](#1)</sup>.
2. **Cognitive mapping**: Use spatial operators (`<` / `<=`) that map intuitively to the mental number line (`0→∞`), avoiding the mental effort required to "flip" comparisons<sup>[1](#1)</sup>.
3. **Linear scannability**: Prefer syntax that supports left-to-right reading (e.g., explicit type ascription). This reduces the "context window" required to understand a statement by declaring intent up-front<sup>[1](#1)</sup>.
4. **Scope minimization**: Use blocks `{ ... }` to isolate temporary state, preventing variable pollution while retaining access to the parent context<sup>[1](#1)</sup>.
5. **Cost explicitness**: Push resource allocation (memory, I/O) up to the call site (e.g., passing a buffer in) to make performance costs visible and controllable by the caller<sup>[1](#1)</sup>.
6. **Architectural enforcement**: Use explicit namespaces/qualifiers to visually reinforce layer boundaries in code (e.g., `ast::Node` vs `hir::Node`)<sup>[1](#1)</sup>.

## Testing

1. **Test decoupling**: Use data-driven tests that rely on input/output data rather than internal API calls, creating resilience against refactoring<sup>[1](#1)</sup>.
2. **Reproduction isolation**: Minimize test cases to the smallest possible unit required to reproduce a behavior, reducing noise and debugging time<sup>[1](#1)</sup>.
3. **Strict regression policy**: Never ignore failing tests; assert the incorrect behavior (with a FIXME) to ensure the failure remains visible and is not silently forgotten<sup>[1](#1)</sup>.

## Documentation

1. **Intent capturing**: Enforce full-sentence comments (capital + period) to psychologically shift the author from "note-taking" (what) to "explanation" (why/context)<sup>[1](#1)</sup>.

## References

1. [`rust-analyzer` high-level architecture and conventions](https://www.google.com/search?q=../research/resources/rust-analyzer/high_level_architecture_and_conventions.md) <a id="1"></a>
2. [`rust-analyzer` syntax tree and parser](./resources/rust-analyzer/syntax_tree_and_parser.md) <a id="2"></a>
