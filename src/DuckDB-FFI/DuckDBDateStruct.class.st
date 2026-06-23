"
I mirror the duckdb_date C struct: a DATE stored as int32 days since 1970-01-01.

I am passed and returned BY VALUE in ffiCall: declarations
(duckdb_value_date, duckdb_bind_date).
Note: the C API also defines a different type named duckdb_date_struct
(year/month/day decomposition) — that one is NOT me and is not wrapped;
day arithmetic from the epoch is done on the Smalltalk side instead.
See: https://github.com/duckdb/duckdb/blob/v1.5.2/src/include/duckdb.h
"
Class {
	#name : 'DuckDBDateStruct',
	#superclass : 'FFIExternalStructure',
	#instVars : [],
	#classVars : [],
	#package : 'DuckDB-FFI'
}

{ #category : 'field definition' }
DuckDBDateStruct class >> fieldsDesc [
	"typedef struct { int32_t days; } duckdb_date"
	^ #(
		int32 days
	)
]

{ #category : 'accessing' }
DuckDBDateStruct >> days [
	^ handle signedLongAt: 1
]

{ #category : 'accessing' }
DuckDBDateStruct >> days: anInteger [
	handle signedLongAt: 1 put: anInteger
]
