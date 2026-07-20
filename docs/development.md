# Development

How to work on DuckDB Smalltalk itself. If you only want to *use* the library in your own
Pharo image, follow [Installation](../README.md#installation) in the README instead.

## Set up

```bash
git clone https://github.com/newapplesho/duckdb-smalltalk.git
cd duckdb-smalltalk

make setup                        # download Pharo image + VM into pharo-local/ (Pharo 13)
# For Pharo 12: make setup PHARO_VERSION=120
```

Place `libduckdb` in `lib/`. This is the default lookup path for the cloned layout
(`<image directory>/../lib/`), so no `DUCKDB_LIB_PATH` is needed:

```bash
# macOS
curl -fsSL -o /tmp/libduckdb-osx.zip \
  https://github.com/duckdb/duckdb/releases/download/v1.5.2/libduckdb-osx-universal.zip
unzip /tmp/libduckdb-osx.zip libduckdb.dylib duckdb.h -d lib/

# Linux
curl -fsSL -o /tmp/libduckdb-linux.zip \
  https://github.com/duckdb/duckdb/releases/download/v1.5.2/libduckdb-linux-amd64.zip
unzip /tmp/libduckdb-linux.zip libduckdb.so duckdb.h -d lib/
```

See [lib/README.md](../lib/README.md) for the full lookup order and the
`DUCKDB_LIB_PATH` override.

## Load the working copy

**Option A: make**

```bash
make load
```

This runs [scripts/load-project.st](../scripts/load-project.st) headlessly — the single
source of truth for the load expression.

**Option B: Pharo Playground** — paste the contents of
[scripts/load-project.st](../scripts/load-project.st) and press Ctrl+D:

```smalltalk
Metacello new
    baseline: 'DuckDB';
    repository: 'tonel://' , (FileLocator imageDirectory / '..' / 'src') resolve fullName;
    onConflict: [ :ex | ex allow ];
    load: 'all'.
```

Note that this loads from the local `src/` directory (`tonel://`), not from GitHub, so
your working-copy edits are what get compiled.

## Run tests

```bash
make test
```

## Daily cycle

Editing in the Pharo GUI (recommended — Iceberg writes the Tonel files for you):

```
make ui                          # open GUI
# edit in System Browser, Ctrl+S to compile
# Tools - Test Runner (Ctrl+O+U) to run tests
# Tools - Iceberg to commit, .class.st files update
# exit Pharo
git add src/ && git commit -m "feat: ..."
```

Editing the Tonel files in `src/` directly instead? The image does not pick up the change
by itself — reload with `make load`, then run `make test`.

## Project layout

| Path | Contents |
|------|----------|
| `src/` | Tonel sources — one `.class.st` per class, one `package.st` per package |
| `scripts/load-project.st` | The load expression (single source of truth) |
| `lib/` | Native `libduckdb` (not committed) |
| `docs/` | [architecture.md](architecture.md), [binding.md](binding.md), this file |
| `pharo-local/` | Local Pharo image + VM created by `make setup` (not committed) |

See [architecture.md](architecture.md) ([日本語](architecture.ja.md)) for the layered
structure, the runtime query flow, and a reading guide to the classes.
