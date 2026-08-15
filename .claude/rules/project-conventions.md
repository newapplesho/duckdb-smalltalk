---
paths:
  - "src/**/*.st"
---

# DuckDB Smalltalk — Project Conventions

This file holds everything **specific to this project**. The other rules files
(`pharo-syntax.md`, `uffi-patterns.md`, `testing.md`) are generic and reusable;
when starting a new Smalltalk library, copy those and rewrite only this file.

## Class Prefix

All classes use the `DuckDB` prefix: `DuckDBConnection`, `DuckDBResult`, ...

## Packages

| Package          | Role                                                |
|------------------|-----------------------------------------------------|
| `DuckDB-FFI`     | `ffiCall:` declarations only — logic is forbidden   |
| `DuckDB-Core`    | User-facing high-level API                          |
| `DuckDB-Tests`   | SUnit tests                                         |
| `BaselineOfDuckDB` | Metacello baseline                                |

Only `DuckDBConnection` and `DuckDBStatement` call the FFI layer directly.
Users interact with five classes: `DuckDB`, `DuckDBConnection`, `DuckDBResult`,
`DuckDBRow`, `DuckDBStatement`.

## FFI Protocol Names (DuckDBLibrary only)

```
'ffi - lifecycle'        duckdb_open, duckdb_close, duckdb_connect, duckdb_disconnect
'ffi - query'            duckdb_query, duckdb_destroy_result
'ffi - prepared'         duckdb_prepare, duckdb_destroy_prepare, duckdb_prepare_error,
                         duckdb_execute_prepared, duckdb_nparams
'ffi - bind'             duckdb_bind_*
'ffi - result access'    duckdb_value_*, duckdb_result_error
'ffi - result metadata'  duckdb_row_count, duckdb_column_count, duckdb_column_name, duckdb_column_type
'ffi - data chunk'       duckdb_fetch_chunk, duckdb_data_chunk_*, duckdb_vector_get_*
'ffi - logical type'     duckdb_get_type_id, duckdb_destroy_logical_type, duckdb_enum_*, duckdb_decimal_*
'ffi - nested type'      duckdb_list_*/struct_*/map_* — scaffolding for LIST/STRUCT/MAP, no callers yet
'ffi - memory'           duckdb_free
'ffi - utility'          duckdb_library_version
```

## Memory Ownership (must pair with `ensure:`)

| Opens with          | Must close with         | Responsible class  | Release method |
|---------------------|-------------------------|--------------------|----------------|
| `duckdb_open`       | `duckdb_close`          | `DuckDB`           | `close`        |
| `duckdb_connect`    | `duckdb_disconnect`     | `DuckDBConnection` | `disconnect`   |
| `duckdb_query`      | `duckdb_destroy_result` | `DuckDBResult`     | `destroy`      |
| `duckdb_prepare`    | `duckdb_destroy_prepare`| `DuckDBStatement`  | `destroy`      |

No `autoRelease` — explicit `ensure:` blocks are required (Pharo GC timing vs
DuckDB resource lifetime conflict; see `docs/architecture.md`).

## Error Hierarchy

`DuckDBError` (carries `errorCode`) with subclasses `DuckDBConnectionError`,
`DuckDBQueryError`, `DuckDBBindError`, `DuckDBUnsupportedTypeError` (a result
column has a type not decodable yet — nested LIST/STRUCT/MAP/ARRAY/UNION or any
unmapped type). Error messages are extracted from the
C API (`duckdb_result_error`) before destroying the failed result.

## Handle Classes

`DuckDBHandle` (duckdb_database), `DuckDBConnectionHandle` (duckdb_connection),
`DuckDBPreparedHandle` (duckdb_prepared_statement) — all `ExternalAddress`
subclasses with `#type: 'bytes'` and class-side `asExternalTypeOn:` returning
`FFIOop new`. `DuckDBResultStruct` mirrors the `duckdb_result` struct
(48 bytes in DuckDB v1.5.x — see the class comment for the duckdb.h source URL).

By-value structs (`FFIExternalStructure` subclasses, see uffi-patterns.md):
`DuckDBDateStruct` (duckdb_date), `DuckDBTimeStruct` (duckdb_time),
`DuckDBTimestampStruct` (duckdb_timestamp), `DuckDBIntervalStruct` (duckdb_interval),
`DuckDBBlobStruct` (duckdb_blob).
Note: C also defines `duckdb_date_struct` (year/month/day form) — not wrapped.

## Type Mapping (DuckDBTypeMapper)

| DuckDB type (code) | Smalltalk object | How |
|--------------------|------------------|-----|
| BOOLEAN (1) | `Boolean` | `duckdb_value_boolean` |
| TINYINT…BIGINT (2–5) | `Integer` | `duckdb_value_int8/16/32/64` |
| UTINYINT…UBIGINT (6–9) | `Integer` | `duckdb_value_uint8/16/32/64` |
| FLOAT (10) / DOUBLE (11) | `Float` | `duckdb_value_float/double` |
| TIMESTAMP (12) | `DateAndTime` (offset 0, UTC) | micros since 1970-01-01 |
| DATE (13) | `Date` | days since 1970-01-01 |
| TIME (14) | `Time` | micros since 00:00:00 |
| INTERVAL (15) | `DuckDBInterval` (exact value object) | by-value struct (months/days/micros) |
| HUGEINT (16) / UHUGEINT (32) | `Integer` (arbitrary precision) | varchar text, parsed — exact |
| VARCHAR (17) | `String` (UTF-8) | `void*` + read + `duckdb_free` |
| BLOB (18) | `ByteArray` | by-value struct; `data` freed after copy |
| DECIMAL (19) | `ScaledDecimal` | varchar text, parsed — exact |
| NULL | `nil` | `duckdb_value_is_null` first |
| ENUM (23) | label `String` | data chunk API (`DuckDBVectorReader`) — see below |
| UUID (27) | `UUID` | data chunk API — hugeint storage, high bit flipped |
| TIMESTAMP_TZ (31) | `DateAndTime` (UTC instant) | data chunk API — int64 micros, same storage as TIMESTAMP |
| LIST (24), STRUCT (25), MAP (26) | — (NOT supported) | known limitation — see below |

Type codes come from the `DUCKDB_TYPE` enum in duckdb.h — always verify against
the header, never guess (a historical off-by-one in `typeFloat`/`typeDouble`
made DOUBLE columns silently fall back to String).
DECIMAL/HUGEINT go through text on purpose: `duckdb_decimal_to_double` /
`duckdb_hugeint_to_double` are lossy, text parsing is exact.
INTERVAL keeps months/days/micros separately (`DuckDBInterval`): months vary in
length, so only month-free intervals convert to `Duration` (`asDuration`).

### Two read paths: per-cell value API vs data chunk API

`DuckDBTypeMapper` uses the deprecated per-cell `duckdb_value_*` API, which cannot
read ENUM, UUID or TIMESTAMP_TZ (verified: `duckdb_value_varchar` returns NULL,
numeric casts return 0). `DuckDBResult>>needsChunkReading` checks each column
against `DuckDBTypeMapper class>>chunkOnlyTypeCodes`; if any column is chunk-only,
the **whole** result is materialized through the data chunk / vector API
(`DuckDBVectorReader`). The two APIs are never mixed on one result.

**Known limitation:** `chunkOnlyTypeCodes` also lists LIST/STRUCT/MAP, so a query
returning them takes the chunk path, but `DuckDBVectorReader` has no decoder for
nested types and signals `DuckDBUnsupportedTypeError`. Nested-type support is
not implemented yet.

Bind support (`DuckDBStatement`): Boolean, Integer (int64), Float (double),
String, `Date`, `Time`, `DateAndTime` (UTC instant), `ByteArray` (blob), NULL.
Generic `bind:at:` auto-detects type from the Smalltalk value's class.
`executeWith:` binds an array and executes in one call.
`DuckDBConnection>>execute:with:` is a one-shot convenience (prepare + bind + execute + destroy).

## Library Loading

`DuckDBLibrary` resolves the library per platform; `DUCKDB_LIB_PATH` overrides
on all platforms (checked first). The platform default is built from the image
directory via `FileLocator imageDirectory parent / 'lib' / ...`:
`<image dir>/../lib/libduckdb.dylib` (macOS, absolute path for SIP),
`<image dir>/../lib/libduckdb.so` (Linux), `duckdb.dll` (Windows PATH search).
With the Pharo image in `pharo-local/` inside the repo, this resolves to
`<repo>/lib/...`.

## Tests

- Test classes: `DuckDBConnectionTest` (lifecycle/query/prepared/CSV) and
  `DuckDBTypeTest` (type round-trips + chunk path). Fixture: in-memory database
  (`:memory:`) opened in `setUp`, closed defensively in `tearDown`.
- Every `DuckDBResult` and `DuckDBStatement` created in a test must be destroyed
  in an `ensure:` block.

## Reference Docs

- Design rationale: `docs/architecture.md`
- DuckDB C API source of truth: `lib/duckdb.h` (downloaded by `make setup`,
  not committed) and
  https://github.com/duckdb/duckdb/blob/v1.5.2/src/include/duckdb.h
