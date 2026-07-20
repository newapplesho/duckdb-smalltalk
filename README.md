# DuckDB Smalltalk

Pharo Smalltalk 12/13 client library for [DuckDB](https://duckdb.org/), using UFFI (Unified Foreign Function Interface).

## Requirements

- Pharo 12 or 13
- `libduckdb` for your platform (installed in step 1 below)

## Platform support

| Platform | Status |
|----------|--------|
| macOS | Tested locally |
| Linux | Tested on CI (Pharo 12 & 13, every push) |
| Windows | Not yet tested — reports welcome |

## Installation

### 1. Install libduckdb

DuckDB is a native library, so you need the shared library before loading the Smalltalk
code. Download the release that matches your platform (DuckDB v1.5.2) and unzip it
anywhere you like:

**macOS:**

```bash
curl -fsSL -o /tmp/libduckdb-osx.zip \
  https://github.com/duckdb/duckdb/releases/download/v1.5.2/libduckdb-osx-universal.zip
unzip /tmp/libduckdb-osx.zip libduckdb.dylib duckdb.h -d ~/duckdb/
```

**Linux:**

```bash
curl -fsSL -o /tmp/libduckdb-linux.zip \
  https://github.com/duckdb/duckdb/releases/download/v1.5.2/libduckdb-linux-amd64.zip
unzip /tmp/libduckdb-linux.zip libduckdb.so duckdb.h -d ~/duckdb/
```

Then tell Pharo where the file is by setting `DUCKDB_LIB_PATH` **before starting Pharo**
(the variable must be visible to the Pharo process — exporting it in a shell after Pharo
is already running has no effect):

```bash
export DUCKDB_LIB_PATH=$HOME/duckdb/libduckdb.dylib   # macOS
export DUCKDB_LIB_PATH=$HOME/duckdb/libduckdb.so      # Linux
```

> **Default library path.** With `DUCKDB_LIB_PATH` unset, `DuckDBLibrary` looks for
> `<image directory>/../lib/libduckdb.dylib` (`.so` on Linux). That path mirrors this
> repository's own layout when it is cloned for development, so it rarely exists next to
> an image of your own — which is why the variable is set explicitly above.
>
> Note that `DUCKDB_LIB_PATH` holds the full path to the library *file*, not a directory
> to search. On macOS this is the only reliable option anyway: SIP causes
> `DYLD_LIBRARY_PATH` to be ignored.

See [lib/README.md](lib/README.md) for the full lookup order.

### 2. Load the library

In a Pharo Playground (Tools > Playground, then Ctrl+D to run):

```smalltalk
Metacello new
    baseline: 'DuckDB';
    repository: 'github://newapplesho/duckdb-smalltalk:main/src';
    load.
```

This loads `DuckDB-Core` and `DuckDB-FFI`. To load the SUnit tests as well, use
`load: 'all'.` instead of `load.`.

### 3. Verify

```smalltalk
"Should print the DuckDB version, e.g. 'v1.5.2'"
DuckDBLibrary uniqueInstance duckdbLibraryVersion.

"Should answer an OrderedCollection(42)"
DuckDB openMemory withConnection: [:conn |
    (conn execute: 'SELECT 42 AS n') collect: [:row | row at: 'n'] ].
```

If the first line raises an error about the library not being found, `DUCKDB_LIB_PATH`
is either unset or was set after Pharo had already started.

## Usage

Run the snippets below in the Pharo **Playground** (Tools > Playground, or Ctrl+O+W).
Select code and press **Ctrl+D** to execute.

```smalltalk
"In-memory query"
| db result |
db := DuckDB openMemory.
result := db execute: 'SELECT 42 AS n, ''hello'' AS s'.
result do: [:row |
    Transcript showCr: (row at: 'n') printString.
    Transcript showCr: (row at: 's') ].
db close.

"Block-based resource management (close/disconnect called automatically)"
DuckDB openMemory withConnection: [:conn |
    (conn execute: 'SELECT * FROM range(10) t(n)')
        collect: [:row | row at: 'n'] ].

"Parameterized query (one-shot convenience)"
| db conn result |
db := DuckDB openMemory.
conn := db connect.
(conn execute: 'CREATE TABLE events (name VARCHAR, count INTEGER)') destroy.
(conn execute: 'INSERT INTO events VALUES (?, ?)' with: #('click' 1)) destroy.
(conn execute: 'INSERT INTO events VALUES (?, ?)' with: #('view' 5)) destroy.
result := conn execute: 'SELECT * FROM events WHERE count > ?' with: #(2).
result do: [:row | Transcript showCr: (row at: 'name')].  "=> view"
result destroy.
conn disconnect.
db close.

"Prepared statements (reusable)"
| db conn stmt |
db := DuckDB openMemory.
conn := db connect.
(conn execute: 'CREATE TABLE events (name VARCHAR, count INTEGER)') destroy.
stmt := conn prepare: 'INSERT INTO events VALUES (?, ?)'.
(stmt executeWith: #('click' 1)) destroy.
(stmt executeWith: #('view' 5)) destroy.
stmt destroy.
conn disconnect.
db close.

"Error handling"
| db conn |
db := DuckDB openMemory.
conn := db connect.
[conn execute: 'INVALID SQL']
    on: DuckDBQueryError
    do: [:e | Transcript showCr: e messageText].
conn disconnect.
db close.
```

For explicit type binding (`bindString:at:`, `bindInteger:at:`, etc.) and the
full type mapping table, see the [binding guide](docs/binding.md).

## Package Structure

| Package | Description |
|---------|-------------|
| `DuckDB-FFI` | Low-level C API bindings (UFFI declarations) |
| `DuckDB-Core` | High-level Smalltalk API |
| `DuckDB-Tests` | SUnit test cases |
| `BaselineOfDuckDB` | Metacello baseline |

## Architecture

See [docs/architecture.md](docs/architecture.md) ([日本語](docs/architecture.ja.md)) for
the layered structure, the runtime query flow, and a reading guide to the classes.

## Roadmap

See [ROADMAP.md](ROADMAP.md) for planned features and the development direction.

## Development

For the workflow of working on the library itself — setting up a local Pharo image,
loading `src/`, and the edit/test cycle — see **[docs/development.md](docs/development.md)**.

| Command | What it does |
|---------|--------------|
| `make setup` | Download a local Pharo image + VM into `pharo-local/` |
| `make load` | Load (or reload) `src/` into that image |
| `make test` | Run the SUnit suite headless |
| `make ui` | Open the Pharo GUI |
