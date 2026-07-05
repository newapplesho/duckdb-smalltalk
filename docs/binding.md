# Parameter Binding

DuckDB Smalltalk provides three levels of API for binding parameters to prepared
statements, from simplest to most explicit.

## 1. One-shot parameterized query (`execute:with:`)

The simplest API. Prepares, binds, executes, and destroys the statement automatically.
Best for queries that run once.

```smalltalk
(conn execute: 'INSERT INTO events VALUES (?, ?)' with: #('click' 1)) destroy.

result := conn execute: 'SELECT * FROM events WHERE count > ?' with: #(2).
[ result do: [:row | Transcript showCr: (row at: 'name')] ]
    ensure: [ result destroy ].
```

## 2. Reusable prepared statement with generic bind (`bind:at:` / `executeWith:`)

For statements executed multiple times with different values. The type is
auto-detected from the Smalltalk value's class.

```smalltalk
stmt := conn prepare: 'INSERT INTO events VALUES (?, ?)'.
[
    (stmt executeWith: #('click' 1)) destroy.
    (stmt executeWith: #('view' 5)) destroy.
] ensure: [ stmt destroy ].
```

`executeWith:` is equivalent to calling `bind:at:` for each element, then `execute`:

```smalltalk
stmt := conn prepare: 'INSERT INTO events VALUES (?, ?)'.
[
    stmt bind: 'click' at: 1; bind: 1 at: 2.
    stmt execute destroy.
] ensure: [ stmt destroy ].
```

### Type detection rules

`bind:at:` maps Smalltalk classes to DuckDB bind functions:

| Smalltalk value | Detected as | DuckDB bind function |
|-----------------|-------------|----------------------|
| `nil` | NULL | `duckdb_bind_null` |
| `true` / `false` | Boolean | `duckdb_bind_boolean` |
| `String` | VARCHAR | `duckdb_bind_varchar` |
| `Integer` (SmallInteger, LargeInteger) | BIGINT | `duckdb_bind_int64` |
| `Float` | DOUBLE | `duckdb_bind_double` |
| `DateAndTime` | TIMESTAMP | `duckdb_bind_timestamp` |
| `Date` | DATE | `duckdb_bind_date` |
| `Time` | TIME | `duckdb_bind_time` |
| `ByteArray` | BLOB | `duckdb_bind_blob` |

Unsupported types signal `DuckDBBindError`.

DuckDB auto-casts bound values to match the column type, so binding a String
to a DECIMAL column or an Integer to a VARCHAR column works as expected.

## 3. Explicit type binding

For full control over which DuckDB type is used. Each method maps directly
to a single C API function.

```smalltalk
stmt := conn prepare: 'INSERT INTO events VALUES (?, ?, ?, ?)'.
[
    stmt
        bindString: 'click' at: 1;
        bindInteger: 42 at: 2;
        bindFloat: 3.14 at: 3;
        bindBoolean: true at: 4.
    stmt execute destroy.
] ensure: [ stmt destroy ].
```

### Available methods

| Method | Value type | DuckDB C function |
|--------|-----------|-------------------|
| `bindBoolean:at:` | `Boolean` | `duckdb_bind_boolean` |
| `bindInteger:at:` | `Integer` | `duckdb_bind_int64` |
| `bindFloat:at:` | `Float` | `duckdb_bind_double` |
| `bindString:at:` | `String` | `duckdb_bind_varchar` |
| `bindDate:at:` | `Date` | `duckdb_bind_date` |
| `bindTime:at:` | `Time` | `duckdb_bind_time` |
| `bindTimestamp:at:` | `DateAndTime` | `duckdb_bind_timestamp` |
| `bindBlob:at:` | `ByteArray` | `duckdb_bind_blob` |
| `bindNull:` | (index only) | `duckdb_bind_null` |

### NULL binding

With generic bind, pass `nil`:

```smalltalk
stmt bind: nil at: 2.
```

With explicit binding, use `bindNull:` (takes only the parameter index):

```smalltalk
stmt bindNull: 2.
```

## Resource management

Every `DuckDBResult` returned by `execute` / `executeWith:` must be destroyed.
Every `DuckDBStatement` must be destroyed. Always use `ensure:` blocks:

```smalltalk
stmt := conn prepare: 'INSERT INTO t VALUES (?)'.
[
    (stmt executeWith: #(42)) destroy.
] ensure: [ stmt destroy ].
```

`execute:with:` on `DuckDBConnection` destroys the statement automatically —
only the result needs cleanup:

```smalltalk
result := conn execute: 'SELECT ?' with: #(42).
[ "use result" ] ensure: [ result destroy ].
```