# Claude Rules for Pharo Smalltalk Projects

Rules files in this directory are auto-loaded by Claude Code when editing files
matching the `paths:` globs in each file's frontmatter.

## Layout

| File | Scope | Reusable? |
|------|-------|-----------|
| `pharo-syntax.md` | Pharo 13 syntax, naming, formatting, Tonel layout, Metacello baseline convention | Yes — copy as-is |
| `uffi-patterns.md` | UFFI patterns for wrapping C libraries (handle classes, memory, structs, library loading) | Yes — copy as-is (snippets use DuckDB as a worked example) |
| `testing.md` | SUnit conventions (setUp/tearDown, naming, assertions, resource cleanup) | Yes — copy as-is |
| `project-conventions.md` | Everything specific to THIS project (prefix, packages, protocols, ownership pairs) | No — rewrite per project |

## Reusing in Another Smalltalk Project

1. Copy `pharo-syntax.md` and `testing.md` unchanged.
2. Copy `uffi-patterns.md` only if the project wraps a C library via UFFI.
3. Write a new `project-conventions.md` for the target project, covering at least:
   - class prefix and package layout
   - custom protocol names (if any)
   - resource ownership table (what opens what, what must release it)
   - error hierarchy
4. Adjust `paths:` globs if the source layout differs from `src/<Package>/`
   (the generic files assume `src/**/*.st`, `src/*-FFI/**`, `src/*-Tests/**`).

## Conventions for Editing Rules Files

- Write in **English**.
- Cite primary sources where they exist (official docs, class comments,
  e.g. `src/UnifiedFFI/FFICallout.class.st` in `pharo-project/pharo`).
- No speculation — record only verified facts; write "reason unknown" or omit.
- Only include code examples that have passed local tests.
