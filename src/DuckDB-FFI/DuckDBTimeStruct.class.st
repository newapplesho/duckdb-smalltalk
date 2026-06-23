"
I mirror the duckdb_time C struct: a TIME stored as int64 microseconds
since 00:00:00.

I am passed and returned BY VALUE in ffiCall: declarations
(duckdb_value_time, duckdb_bind_time).
See: https://github.com/duckdb/duckdb/blob/v1.5.2/src/include/duckdb.h
"
Class {
	#name : 'DuckDBTimeStruct',
	#superclass : 'FFIExternalStructure',
	#instVars : [],
	#classVars : [],
	#package : 'DuckDB-FFI'
}

{ #category : 'field definition' }
DuckDBTimeStruct class >> fieldsDesc [
	"typedef struct { int64_t micros; } duckdb_time"
	^ #(
		int64 micros
	)
]

{ #category : 'accessing' }
DuckDBTimeStruct >> micros [
	^ handle signedLongLongAt: 1
]

{ #category : 'accessing' }
DuckDBTimeStruct >> micros: anInteger [
	handle signedLongLongAt: 1 put: anInteger
]
