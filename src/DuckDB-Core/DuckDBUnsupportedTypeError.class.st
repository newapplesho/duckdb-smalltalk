"
I am signaled when a query returns a column whose DuckDB type this library
cannot decode yet — the nested types LIST, STRUCT, MAP, ARRAY and UNION, and
any other type not mapped by DuckDBTypeMapper. Both read paths (the value API
and the chunk API) raise me through DuckDBUnsupportedTypeError class>>signalForTypeCode:.
My messageText carries the offending DuckDB type code. Nested-type support is
not implemented yet.
"
Class {
	#name : 'DuckDBUnsupportedTypeError',
	#superclass : 'DuckDBError',
	#instVars : [],
	#classVars : [],
	#package : 'DuckDB-Core'
}

{ #category : 'error handling' }
DuckDBUnsupportedTypeError class >> signalForTypeCode: aTypeCode [
	"Signal that a column's DuckDB type code cannot be decoded yet. Used by both
	 read paths (the value API in DuckDBTypeMapper and the chunk API in
	 DuckDBVectorReader) so they share one error contract and message."
	^ self signal: 'Unsupported column type code: ' , aTypeCode printString
]
