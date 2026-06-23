"
I represent a DuckDB database instance.

I manage the database lifecycle: open with `DuckDB open:` or `DuckDB openMemory`,
and always close with `close` when done.
Create connections with `connect`, or use `withConnection:` for automatic cleanup.

Example:
	db := DuckDB openMemory.
	[ (db execute: 'SELECT 42 AS n') destroy ] ensure: [ db close ].
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
			DuckDBConnectionError signal: 'Failed to open database: ' , path ].
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
	"Evaluate aBlock with a fresh connection, ensuring disconnection on exit."
	| conn |
	conn := self connect.
	^ [aBlock value: conn]
		ensure: [conn disconnect. self close]
]

{ #category : 'testing' }
DuckDB >> isOpen [
	^ handle isNil not
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