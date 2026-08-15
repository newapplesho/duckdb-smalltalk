"
I represent an active connection to a DuckDB database.

I execute SQL with `execute:` (returning a DuckDBResult the caller must destroy),
parameterized SQL with `execute:with:`, and compile prepared statements with
`prepare:`.
Always call `disconnect` when done, or use DuckDB>>withConnection: for automatic
cleanup.

Example:
	conn := DuckDB openMemory connect.
	result := conn execute: 'SELECT 42 AS n'.
	[ result do: [:row | Transcript showCr: (row at: 'n') printString] ]
		ensure: [ result destroy. conn disconnect ].

Example (parameterized):
	result := conn execute: 'SELECT ? + ? AS sum' with: #(1 2).
	[ Transcript showCr: (result first at: 'sum') printString ]
		ensure: [ result destroy ].
"
Class {
	#name : 'DuckDBConnection',
	#superclass : 'Object',
	#instVars : [
		'handle',
		'database'
	],
	#classVars : [],
	#package : 'DuckDB-Core'
}

{ #category : 'instance creation' }
DuckDBConnection class >> on: aDuckDB handle: aDbHandle [
	^ self new
		initializeOn: aDuckDB handle: aDbHandle;
		yourself
]

{ #category : 'private' }
DuckDBConnection >> initializeOn: aDuckDB handle: aDbHandle [
	| returnCode slot |
	database := aDuckDB.
	slot := DuckDBConnectionHandle allocate: 8.
	returnCode := DuckDBLibrary uniqueInstance
		duckdbConnect: aDbHandle
		outConnection: slot.
	returnCode = DuckDBLibrary success
		ifFalse: [
			slot free.
			DuckDBConnectionError
				signal: 'Failed to connect to database'
				code: returnCode ].
	handle := slot
]

{ #category : 'actions' }
DuckDBConnection >> execute: sqlString [
	"Execute sqlString and return a DuckDBResult.
	 Caller must destroy the result, inside an ensure: block.
	 A column whose type this library cannot decode signals
	 DuckDBUnsupportedTypeError: eagerly here for chunk-only nested types
	 (LIST/STRUCT/MAP), so no result is returned; or lazily when the offending
	 cell is read for other unsupported types (e.g. ARRAY), in which case a result
	 IS returned and the usual ensure: [ result destroy ] still releases it."
	| resultStruct returnCode |
	self isConnected ifFalse: [
		DuckDBConnectionError signal: 'Connection is closed' ].
	resultStruct := ExternalAddress allocate: DuckDBResultStruct byteSize.
	returnCode := DuckDBLibrary uniqueInstance
		duckdbQuery: (handle pointerAt: 1)
		query: sqlString
		outResult: resultStruct.
	returnCode = DuckDBLibrary success
		ifFalse: [
			| msg |
			msg := DuckDBLibrary uniqueInstance duckdbResultError: resultStruct.
			DuckDBLibrary uniqueInstance duckdbDestroyResult: resultStruct.
			resultStruct free.
			DuckDBQueryError
				signal: (msg ifNil: ['Query failed'])
				code: returnCode ].
	^ DuckDBResult on: resultStruct
]

{ #category : 'actions' }
DuckDBConnection >> execute: sqlString with: anArray [
	| stmt |
	self isConnected ifFalse: [
		DuckDBConnectionError signal: 'Connection is closed' ].
	stmt := self prepare: sqlString.
	^ [ stmt executeWith: anArray ] ensure: [ stmt destroy ]
]

{ #category : 'actions' }
DuckDBConnection >> prepare: sqlString [
	"Compile sqlString into a DuckDBStatement for repeated execution."
	self isConnected ifFalse: [
		DuckDBConnectionError signal: 'Connection is closed' ].
	^ DuckDBStatement on: self sql: sqlString
]

{ #category : 'actions' }
DuckDBConnection >> disconnect [
	self isConnected ifFalse: [ ^ self ].
	DuckDBLibrary uniqueInstance duckdbDisconnect: handle.
	handle free.
	handle := nil
]

{ #category : 'testing' }
DuckDBConnection >> isConnected [
	^ handle notNil
]

{ #category : 'accessing' }
DuckDBConnection >> handle [
	^ handle
]

{ #category : 'printing' }
DuckDBConnection >> printOn: aStream [
	aStream
		nextPutAll: 'DuckDBConnection(';
		nextPutAll: (self isConnected ifTrue: ['connected'] ifFalse: ['disconnected']);
		nextPut: $)
]