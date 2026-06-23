"
I mirror the duckdb_interval C struct: an INTERVAL stored in months, days
and microseconds (the three components are independent — months vary in length,
so they cannot be reduced to a fixed number of seconds).

I am returned BY VALUE by duckdb_value_interval.
The user-facing representation is the DuckDBInterval value object in DuckDB-Core.
See: https://github.com/duckdb/duckdb/blob/v1.5.2/src/include/duckdb.h
"
Class {
	#name : 'DuckDBIntervalStruct',
	#superclass : 'FFIExternalStructure',
	#instVars : [],
	#classVars : [],
	#package : 'DuckDB-FFI'
}

{ #category : 'field definition' }
DuckDBIntervalStruct class >> fieldsDesc [
	"typedef struct { int32_t months; int32_t days; int64_t micros; } duckdb_interval"
	^ #(
		int32 months
		int32 days
		int64 micros
	)
]

{ #category : 'accessing' }
DuckDBIntervalStruct >> months [
	^ handle signedLongAt: 1
]

{ #category : 'accessing' }
DuckDBIntervalStruct >> days [
	^ handle signedLongAt: 5
]

{ #category : 'accessing' }
DuckDBIntervalStruct >> micros [
	^ handle signedLongLongAt: 9
]
