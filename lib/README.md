# lib/ — native library location

Place `libduckdb` (macOS / Linux) or `duckdb.dll` (Windows) here.
The binary is not committed to the repository (excluded via `.gitignore`).

## Library lookup order

`DuckDBLibrary` resolves the library path as follows:

1. If the `DUCKDB_LIB_PATH` environment variable is set, use its value.
2. Otherwise, use the platform-specific default path (see below).

Use `DUCKDB_LIB_PATH` to override the path on CI or for non-standard installs.

## macOS

**Default path:** `<repository root>/lib/libduckdb.dylib`

```bash
curl -L -o /tmp/libduckdb-osx.zip \
  https://github.com/duckdb/duckdb/releases/download/v1.5.6/libduckdb-osx-universal.zip
unzip /tmp/libduckdb-osx.zip libduckdb.dylib duckdb.h -d lib/
```

> Due to macOS SIP, `DYLD_LIBRARY_PATH` is ignored. Specify an absolute path directly.

## Linux

**Default path:** `<repository root>/lib/libduckdb.so`

```bash
curl -L -o /tmp/libduckdb-linux.zip \
  https://github.com/duckdb/duckdb/releases/download/v1.5.6/libduckdb-linux-amd64.zip
unzip /tmp/libduckdb-linux.zip libduckdb.so duckdb.h -d lib/
```

To point at a different directory, use `DUCKDB_LIB_PATH`:

```bash
export DUCKDB_LIB_PATH=/usr/local/lib/libduckdb.so
```

## Windows

**Default:** `duckdb.dll` (searched on the system PATH or the current directory)

```powershell
Invoke-WebRequest -Uri https://github.com/duckdb/duckdb/releases/download/v1.5.6/libduckdb-windows-amd64.zip `
  -OutFile $env:TEMP\libduckdb-windows.zip
Expand-Archive $env:TEMP\libduckdb-windows.zip -DestinationPath lib\
```

Add the DLL to the system PATH, or set an absolute path via `DUCKDB_LIB_PATH`:

```powershell
$env:DUCKDB_LIB_PATH = "$PWD\lib\duckdb.dll"
```

## DuckDB 2.x

DuckDB 2.x is supported on Pharo 14 only. From 2.0.0 the release asset is a
`.tar.gz` named `duckdb-shared-libs-<platform>.tar.gz` (e.g.
`duckdb-shared-libs-osx-universal.tar.gz`, `duckdb-shared-libs-linux-amd64.tar.gz`)
instead of `libduckdb-<platform>.zip`. Extract `libduckdb.dylib` / `libduckdb.so`
and `duckdb.h` into this directory with `tar xzf <file> -C lib/ <names>`.

## Checking the version

Run in the Pharo Playground:

```smalltalk
DuckDBLibrary uniqueInstance duckdbLibraryVersion
```
