# Roadmap

What you can do with [DuckDB](https://duckdb.org/) from Pharo Smalltalk today,
and what is coming next. Items are ordered roughly by priority within each theme,
not by release date. Each theme links to the relevant official DuckDB
documentation. Contributions and feature requests are welcome — please open
an issue.

## Available now

- [x] Open / close databases (in-memory and file-based)
- [x] SQL query execution with typed results
      (BOOLEAN, TINYINT…BIGINT, UTINYINT…UBIGINT, FLOAT, DOUBLE, VARCHAR,
      NULL as `nil`)
- [x] DATE / TIME / TIMESTAMP results as Pharo `Date` / `Time` / `DateAndTime`
- [x] INTERVAL results as an exact `DuckDBInterval` value object
      (months / days / microseconds)
- [x] BLOB results as `ByteArray`; DECIMAL as `ScaledDecimal` (exact);
      HUGEINT / UHUGEINT as arbitrary-precision `Integer`
- [x] Row access by column name or index, `do:` / `collect:` / `select:` enumeration
- [x] Prepared statements with parameter binding
      (Boolean, Integer, Float, String, Date, Time, DateAndTime, ByteArray, NULL)
- [x] CSV reading via `read_csv_auto` and import into tables
- [x] Explicit, deterministic resource management (`ensure:`-based, no GC surprises)
- [x] macOS / Linux / Windows library loading, CI on Pharo 12 and 13

## Rich type support

DuckDB data types: [official overview](https://duckdb.org/docs/stable/sql/data_types/overview)

- [x] DATE / TIME / TIMESTAMP results returned as Pharo `Date` / `Time` / `DateAndTime`
- [x] BLOB results returned as `ByteArray`
- [x] DECIMAL (as exact `ScaledDecimal`) and HUGEINT / UHUGEINT (as `Integer`) —
      [numeric types](https://duckdb.org/docs/stable/sql/data_types/numeric)
- [x] Unsigned integer types (UTINYINT … UBIGINT)
- [x] INTERVAL as an exact value object —
      [interval type](https://duckdb.org/docs/stable/sql/data_types/interval)
- [x] Bind DATE / TIME / TIMESTAMP / BLOB parameters in prepared statements —
      [C API prepared statements](https://duckdb.org/docs/stable/clients/c/prepared)
- [x] UUID, ENUM and TIMESTAMP_TZ types — the deprecated per-cell C API cannot
      extract these (verified), so they are read through the
      [data chunk API](https://duckdb.org/docs/stable/clients/c/data_chunk)
      (`DuckDBVectorReader`)
- [ ] LIST / STRUCT / MAP nested types — also needs the data chunk API
      (currently routed to the chunk path but raise `Unsupported column type code`)

## Bulk data and performance

- [ ] Appender API for fast bulk inserts —
      [C API appender](https://duckdb.org/docs/stable/clients/c/appender)
- [ ] Chunked / streaming result reading for large datasets —
      [C API data chunks](https://duckdb.org/docs/stable/clients/c/data_chunk)
      (also unlocks UUID / ENUM / TIMESTAMP_TZ / LIST / STRUCT / MAP above)
- [ ] Lazy row iteration without materializing full results
- [ ] Batch statement execution (bind-and-execute loops over collections,
      like Python's `executemany` / Rust's `execute_batch`)

## File formats and import/export

- [ ] Parquet read / write convenience API —
      [Parquet docs](https://duckdb.org/docs/stable/data/parquet/overview)
- [ ] JSON read convenience API —
      [JSON docs](https://duckdb.org/docs/stable/data/json/overview)
- [ ] `COPY TO` / `COPY FROM` helpers (export query results to CSV / Parquet) —
      [COPY statement](https://duckdb.org/docs/stable/sql/statements/copy)
- [ ] Extension management helpers and docs (`INSTALL` / `LOAD`:
      httpfs, json, parquet, icu, …) —
      [extensions overview](https://duckdb.org/docs/stable/extensions/overview),
      [core extensions](https://duckdb.org/docs/stable/core_extensions/overview)

## Query interface

- [ ] Relational (lazy) query builder over connections — compose `filter:` /
      `select:` / `join:` / `order:` messages and run them as one SQL query,
      like the
      [Python relational API](https://duckdb.org/docs/stable/clients/python/relational_api)

## Smalltalk integration

- [ ] Conversion to and from Pharo
      [DataFrame](https://github.com/PolyMathOrg/DataFrame)
      (the pandas / Polars equivalent)
- [ ] Register Smalltalk blocks as scalar SQL functions, like
      [Python UDFs](https://duckdb.org/docs/stable/clients/python/function)
- [ ] Query Smalltalk collections as tables, like Python's
      [`register()` / replacement scans](https://duckdb.org/docs/stable/clients/python/data_ingestion)

## Developer experience

- [ ] Block-based transaction helpers (`inTransaction:` with automatic rollback
      on error) —
      [transaction statements](https://duckdb.org/docs/stable/sql/statements/transactions)
- [ ] Tagged releases installable via Metacello `github://`
- [ ] Getting-started and per-feature documentation in `docs/`
- [ ] Concurrency guidance: one connection per Pharo process, following
      [DuckDB's concurrency model](https://duckdb.org/docs/stable/connect/concurrency)
- [ ] Windows CI coverage

## Ecosystem integration

- [ ] Import BigQuery query results into DuckDB via
      [google-cloud-smalltalk](https://github.com/newapplesho/google-cloud-smalltalk)
- [ ] Interoperable row protocol with other Smalltalk data libraries
