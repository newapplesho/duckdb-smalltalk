"
I mirror the duckdb_blob C struct: a BLOB as a (data pointer, byte size) pair.

I am returned BY VALUE by duckdb_value_blob. My data pointer is owned by the
caller and must be released with duckdb_free after copying the bytes.
See: https://github.com/duckdb/duckdb/blob/v1.5.2/src/include/duckdb.h
"
Class {
	#name : 'DuckDBBlobStruct',
	#superclass : 'FFIExternalStructure',
	#instVars : [],
	#classVars : [],
	#package : 'DuckDB-FFI'
}

{ #category : 'field definition' }
DuckDBBlobStruct class >> fieldsDesc [
	"typedef struct { void *data; idx_t size; } duckdb_blob"
	^ #(
		void* data
		uint64 size
	)
]

{ #category : 'accessing' }
DuckDBBlobStruct >> data [
	^ handle pointerAt: 1
]

{ #category : 'accessing' }
DuckDBBlobStruct >> size [
	^ handle unsignedLongLongAt: 9
]
