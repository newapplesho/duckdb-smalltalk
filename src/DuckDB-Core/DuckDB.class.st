"
I represent a DuckDB database instance.

I manage the database lifecycle: open with `DuckDB open:` or `DuckDB openMemory`,
and always close with `close` when done.
Create connections with `connect` (disconnect them yourself) or use
`withConnection:` to auto-disconnect a single connection while I stay open.
For a throwaway database that is opened and fully closed around a block, use the
class-side `DuckDB class >> openMemoryConnectionDo:` or `open:connectionDo:`.

Example:
	db := DuckDB openMemory.
	[ (db execute: 'SELECT 42 AS n') destroy ] ensure: [ db close ].

Example (throwaway, fully managed):
	DuckDB openMemoryConnectionDo: [:conn |
		(conn execute: 'SELECT 42 AS n') destroy ].
"
Class {
	#name : 'DuckDB',
	#superclass : 'Object',
	#instVars : [
		'handle',
		'path'
	],
	#classVars : [],
	#package : 'DuckDB-Core'
}

{ #category : 'instance creation' }
DuckDB class >> open: aPathString [
	"Open a DuckDB database at the given path.
	 Use ':memory:' for an in-memory database."
	^ self new
		initializePath: aPathString;
		open;
		yourself
]

{ #category : 'instance creation' }
DuckDB class >> openMemory [
	"Open an in-memory DuckDB database."
	^ self open: ':memory:'
]

{ #category : 'instance creation' }
DuckDB class >> openMemoryConnectionDo: aBlock [
	"Open an in-memory database, evaluate aBlock with a fresh connection, then
	 disconnect and close the database on exit. Returns aBlock's value."
	^ self open: ':memory:' connectionDo: aBlock
]

{ #category : 'instance creation' }
DuckDB class >> open: aPathString connectionDo: aBlock [
	"Open the database at aPathString, evaluate aBlock with a fresh connection,
	 then disconnect and close the database on exit. Returns aBlock's value."
	| db |
	db := self open: aPathString.
	^ [ db withConnection: aBlock ] ensure: [ db close ]
]

{ #category : 'private' }
DuckDB >> initializePath: aPathString [
	path := aPathString
]

{ #category : 'actions' }
DuckDB >> open [
	| slot returnCode |
	slot := DuckDBHandle allocate: 8.
	returnCode := DuckDBLibrary uniqueInstance
		duckdbOpen: path
		outDatabase: slot.
	returnCode = DuckDBLibrary success
		ifFalse: [
			slot free.
			DuckDBConnectionError
				signal: 'Failed to open database: ' , path
				code: returnCode ].
	handle := slot
]

{ #category : 'actions' }
DuckDB >> close [
	self isOpen ifFalse: [ ^ self ].
	DuckDBLibrary uniqueInstance duckdbClose: handle.
	handle free.
	handle := nil
]

{ #category : 'actions' }
DuckDB >> connect [
	self isOpen ifFalse: [ DuckDBConnectionError signal: 'Database is not open' ].
	^ DuckDBConnection on: self handle: (handle pointerAt: 1)
]

{ #category : 'actions' }
DuckDB >> execute: sqlString [
	"Convenience: connect, execute, disconnect."
	| conn |
	conn := self connect.
	^ [conn execute: sqlString]
		ensure: [conn disconnect]
]

{ #category : 'actions' }
DuckDB >> withConnection: aBlock [
	"Evaluate aBlock with a fresh connection, disconnecting it on exit.
	 The database itself stays open — the caller owns it and must close it.
	 For a throwaway database opened and fully closed around the block, use the
	 class-side DuckDB class >> openMemoryConnectionDo: or open:connectionDo:."
	| conn |
	conn := self connect.
	^ [aBlock value: conn]
		ensure: [conn disconnect]
]

{ #category : 'testing' }
DuckDB >> isOpen [
	^ handle notNil
]

{ #category : 'accessing' }
DuckDB >> path [
	^ path
]

{ #category : 'printing' }
DuckDB >> printOn: aStream [
	aStream
		nextPutAll: 'DuckDB(';
		nextPutAll: (path ifNil: ['closed']);
		nextPut: $)
]