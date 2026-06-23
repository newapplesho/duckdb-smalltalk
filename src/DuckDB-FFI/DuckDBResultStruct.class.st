"
I mirror the duckdb_result C struct layout (DuckDB v1.5.x).

I exist only to provide the correct byteSize for allocating result memory.
All my fields are deprecated internals — never read or write them directly;
use the DuckDBLibrary API functions instead.
"
Class {
	#name : 'DuckDBResultStruct',
	#superclass : 'FFIExternalStructure',
	#instVars : [],
	#classVars : [],
	#package : 'DuckDB-FFI'
}

{ #category : 'accessing' }
DuckDBResultStruct class >> byteSize [
	"duckdb_result is 6 machine words in DuckDB v1.5.x (48 bytes on 64-bit builds).
	 v1.5.2 added deprecated_rows_changed as the third field.
	 See: https://github.com/duckdb/duckdb/blob/v1.5.2/src/include/duckdb.h"
	^ 48
]

{ #category : 'accessing' }
DuckDBResultStruct class >> fieldsDesc [
	"Mirror the duckdb_result C struct layout (DuckDB v1.5.x, from duckdb.h).
	 Fields are intentionally deprecated internals — never access them directly.
	 Use DuckDBLibrary API functions instead.
	 See: https://github.com/duckdb/duckdb/blob/v1.5.2/src/include/duckdb.h"
	^ #(
		uint64  deprecated_column_count
		uint64  deprecated_row_count
		uint64  deprecated_rows_changed
		void*   deprecated_columns
		void*   deprecated_error_message
		void*   internal_data
	)
]
