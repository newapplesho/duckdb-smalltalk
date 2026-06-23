# DuckDB Smalltalk

A client library that wraps the DuckDB C API with Pharo 12/13 + UFFI.
Sources are in [Tonel](https://github.com/pharo-vcs/tonel) format (`src/`): one `.class.st` per class, one `package.st` per package.

## Commands

```bash
# Load the project (headless) — scripts/load-project.st is the single source of truth for the load expression
make load

# Run tests (headless)
make test

# Launch the Pharo GUI
make ui
```

To load from a Playground, run the contents of `scripts/load-project.st` with Ctrl+D.
After editing a `.st` file, reload it into the image with `make load`, otherwise the
change will not be reflected in the tests.

## Library path

`DuckDBLibrary` looks for the native library at the following per-platform paths.
Set the `DUCKDB_LIB_PATH` environment variable to override it on any platform (used on
CI or for non-standard installs).

| Platform | Default |
|----------|---------|
| macOS | `<repository root>/lib/libduckdb.dylib` (absolute path, SIP-safe) |
| Linux | `<repository root>/lib/libduckdb.so` (absolute path) |
| Windows | `duckdb.dll` (searched on the system PATH) |

## Packages

| Package | Role |
|---------|------|
| DuckDB-FFI | `ffiCall:` declarations only (no logic) |
| DuckDB-Core | High-level API for users |
| DuckDB-Tests | SUnit tests |
| BaselineOfDuckDB | Metacello baseline |

## Memory management (required)

| Class | Release method | Always call via `ensure:` |
|-------|----------------|---------------------------|
| `DuckDB` | `close` | yes |
| `DuckDBConnection` | `disconnect` | yes |
| `DuckDBResult` | `destroy` | yes |
| `DuckDBStatement` | `destroy` | yes |

## Documentation style

- In Japanese text, do not put a space between Japanese characters and Latin characters
  (English words, code, numbers) — e.g. `FFIは`, `Playgroundで`, `第0章`.
- Do not use `→`. Express references with `：` and connections with words like `と` / `して`.

## Detailed rules

The rules are split into "generic (copyable to other Smalltalk projects)" and
"specific to this project". See `.claude/rules/README.md` for how they are organized.

- Pharo 13 syntax & naming (generic): `.claude/rules/pharo-syntax.md` (auto-loaded when editing `.st` files)
- UFFI patterns (generic): `.claude/rules/uffi-patterns.md` (auto-loaded when editing `*-FFI/` and `*-Core/`)
- Testing conventions (generic): `.claude/rules/testing.md` (auto-loaded when editing `*-Tests/`)
- Project-specific conventions: `.claude/rules/project-conventions.md` (prefix, FFI protocol names, memory ownership)
- Architecture: `docs/architecture.md` ([日本語](docs/architecture.ja.md))

## Conventions for writing rules files

- **Language: English.**
- **Cite sources:** where a primary source exists (official docs, class comments, specs),
  point to it (e.g. `src/UnifiedFFI/FFICallout.class.st` in `pharo-project/pharo`).
- **No speculation:** record only verified facts. If a reason is unknown, write "reason unknown" or omit it.
- **Only verified code:** include code examples only for patterns that have passed local tests.
