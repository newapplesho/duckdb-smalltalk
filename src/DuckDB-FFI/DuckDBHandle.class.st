"
I am an 8-byte slot holding a duckdb_database opaque handle (typedef void* in C).

I subclass ExternalAddress (NOT FFIOpaqueObject — that corrupts the heap on Linux).
Allocate me with `DuckDBHandle allocate: 8`, let duckdb_open write the pointer
into my bytes, and read it back with `pointerAt: 1`. Free me with `free`.
"
Class {
	#name : 'DuckDBHandle',
	#superclass : 'ExternalAddress',
	#type : 'bytes',
	#instVars : [],
	#classVars : [],
	#package : 'DuckDB-FFI'
}

{ #category : 'accessing' }
DuckDBHandle class >> asExternalTypeOn: aGenerator [
	"Required by Pharo UFFI for custom types used in ffiCall: declarations.
	 Per FFICallout class comment, any class used as a type name in ffiCall: must
	 respond to #asExternalTypeOn: (see src/UnifiedFFI/FFICallout.class.st in pharo-project/pharo).
	 ExternalAddress itself is covered via FFICallout TypeAliases (ExternalAddress -> FFIOop),
	 but subclasses are not, so they must define this method explicitly.
	 FFIOop is correct: ExternalAddress is a ByteArray subclass whose bytes ARE the C heap
	 allocation, matching the ExternalAddress -> FFIOop alias in FFICallout>>initializeTypeAliases."
	^ FFIOop new
]

