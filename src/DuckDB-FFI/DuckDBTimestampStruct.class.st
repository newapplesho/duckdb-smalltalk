"
I mirror the duckdb_timestamp C struct: a TIMESTAMP stored as int64
microseconds since 1970-01-01 (no timezone).

I am passed and returned BY VALUE in ffiCall: declarations
(duckdb_value_timestamp, duckdb_bind_timestamp).
See: https://github.com/duckdb/duckdb/blob/v1.5.2/src/include/duckdb.h
"
Class {
	#name : 'DuckDBTimestampStruct',
	#superclass : 'FFIExternalStructure',
	#instVars : [],
	#classVars : [],
	#package : 'DuckDB-FFI'
}

{ #category : 'field definition' }
DuckDBTimestampStruct class >> fieldsDesc [
	"typedef struct { int64_t micros; } duckdb_timestamp"
	^ #(
		int64 micros
	)
]

{ #category : 'accessing' }
DuckDBTimestampStruct >> micros [
	^ handle signedLongLongAt: 1
]

{ #category : 'accessing' }
DuckDBTimestampStruct >> micros: anInteger [
	handle signedLongLongAt: 1 put: anInteger
]
