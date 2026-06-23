# DuckDB Smalltalk

Pharo Smalltalk 12/13 client library for [DuckDB](https://duckdb.org/), using UFFI (Unified Foreign Function Interface).

## Requirements

- Pharo 12 or 13 (`pharo-local/` — installed separately, see below)
- `libduckdb` for your platform — see `lib/README.md`

## Platform support

| Platform | Status |
|----------|--------|
| macOS | Tested locally |
| Linux | Tested on CI (Pharo 12 & 13, every push) |
| Windows | Not yet tested — reports welcome |

## Quick Start

### 1. Install Pharo

```bash
mkdir -p pharo-local && cd pharo-local
# Pharo 13
curl -fsSL https://get.pharo.org/64/130+vm | bash
# Pharo 12
# curl -fsSL https://get.pharo.org/64/120+vm | bash
cd ..
```

### 2. Get libduckdb

**macOS:**

```bash
curl -fsSL -o /tmp/libduckdb-osx.zip \
  https://github.com/duckdb/duckdb/releases/download/v1.5.2/libduckdb-osx-universal.zip
unzip /tmp/libduckdb-osx.zip libduckdb.dylib duckdb.h -d lib/
```

**Linux:**

```bash
curl -fsSL -o /tmp/libduckdb-linux.zip \
  https://github.com/duckdb/duckdb/releases/download/v1.5.2/libduckdb-linux-amd64.zip
unzip /tmp/libduckdb-linux.zip libduckdb.so duckdb.h -d lib/
```

**Windows** (not yet tested):

```powershell
Invoke-WebRequest -Uri https://github.com/duckdb/duckdb/releases/download/v1.5.2/libduckdb-windows-amd64.zip `
  -OutFile $env:TEMP\libduckdb.zip
Expand-Archive $env:TEMP\libduckdb.zip -DestinationPath lib\
```

For non-standard install paths, set `DUCKDB_LIB_PATH` to the full path of the library file. See `lib/README.md` for details.

### 3. Load the project into Pharo

**Option A: make (macOS / Linux)**

```bash
make load
```

This runs [scripts/load-project.st](scripts/load-project.st) headlessly — the single
source of truth for the load expression.

**Option B: Pharo Playground** (Tools > Playground, then Ctrl+D to run)

Paste the contents of [scripts/load-project.st](scripts/load-project.st):

```smalltalk
Metacello new
    baseline: 'DuckDB';
    repository: 'tonel://' , (FileLocator imageDirectory / '..' / 'src') resolve fullName;
    onConflict: [ :ex | ex allow ];
    load: 'all'.
```

**Option C: headless without make (e.g. Windows)**

```powershell
cd pharo-local
.\pharo.exe --headless Pharo.image eval --save "Metacello new baseline: 'DuckDB'; repository: 'tonel://' , (FileLocator imageDirectory / '..' / 'src') resolve fullName; onConflict: [ :ex | ex allow ]; load: 'all'."
```

### 4. Run tests

**macOS / Linux:**

```bash
make test
```

**Windows** (not yet tested):

```powershell
cd pharo-local
.\pharo.exe --headless Pharo.image test --junit-xml-output 'DuckDB.*'
```

## Usage

Run the snippets below in the Pharo **Playground** (Tools > Playground, or Ctrl+O+W).
Select code and press **Ctrl+D** to execute.

**Start Pharo GUI (macOS / Linux):**

```bash
make ui
```

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

"Prepared statements"
| db conn stmt |
db := DuckDB openMemory.
conn := db connect.
conn execute: 'CREATE TABLE events (name VARCHAR, count INTEGER)'.
stmt := conn prepare: 'INSERT INTO events VALUES (?, ?)'.
stmt bindString: 'click' at: 1; bindInteger: 1 at: 2; execute.
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

## Local Development Workflow

```
[Daily cycle]
make ui                          # open GUI (macOS / Linux)
# edit in System Browser, Ctrl+S to compile
# Tools - Test Runner (Ctrl+O+U) to run tests
# Tools - Iceberg to commit, .class.st files update
# exit Pharo
git add src/ && git commit -m "feat: ..."
```

Editing Tonel files directly instead? Reload them into the image with `make load`,
then run `make test`.
