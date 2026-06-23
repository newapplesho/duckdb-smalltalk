"
I am an 8-byte slot holding a duckdb_prepared_statement opaque handle
(typedef void* in C).
See DuckDBHandle for the slot allocation pattern and design rationale.
"
Class {
	#name : 'DuckDBPreparedHandle',
	#superclass : 'ExternalAddress',
	#type : 'bytes',
	#instVars : [],
	#classVars : [],
	#package : 'DuckDB-FFI'
}

{ #category : 'accessing' }
DuckDBPreparedHandle class >> asExternalTypeOn: aGenerator [
	"Required by Pharo UFFI for custom types used in ffiCall: declarations.
	 See DuckDBHandle class >> asExternalTypeOn: for the full rationale."
	^ FFIOop new
]
