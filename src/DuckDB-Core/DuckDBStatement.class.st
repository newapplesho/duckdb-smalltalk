"
I represent a prepared SQL statement compiled by DuckDBConnection>>prepare:.

I bind parameters with the generic `bind:at:` (type is auto-detected from the
Smalltalk value) or explicit `bindBoolean:at:`, `bindInteger:at:`,
`bindFloat:at:`, `bindString:at:` and `bindNull:` (parameter indices are
1-based), then run with `execute` or `executeWith:`, which returns a
DuckDBResult the caller must destroy.
I can be executed repeatedly with different bindings.
Always call `destroy` when done, inside an `ensure:` block.

Example (generic):
	stmt := conn prepare: 'INSERT INTO events VALUES (?, ?)'.
	[ (stmt executeWith: #('click' 1)) destroy ]
		ensure: [ stmt destroy ].

Example (explicit):
	stmt := conn prepare: 'INSERT INTO events VALUES (?, ?)'.
	[ stmt bindString: 'click' at: 1; bindInteger: 1 at: 2; execute destroy ]
		ensure: [ stmt destroy ].
"
Class {
	#name : 'DuckDBStatement',
	#superclass : 'Object',
	#instVars : [
		'handle',
		'connection',
		'sql'
	],
	#classVars : [],
	#package : 'DuckDB-Core'
}

{ #category : 'instance creation' }
DuckDBStatement class >> on: aDuckDBConnection sql: sqlString [
	^ self new
		initializeOn: aDuckDBConnection sql: sqlString;
		yourself
]

{ #category : 'private' }
DuckDBStatement >> initializeOn: aDuckDBConnection sql: sqlString [
	| returnCode slot |
	connection := aDuckDBConnection.
	sql := sqlString.
	slot := DuckDBPreparedHandle allocate: 8.
	returnCode := DuckDBLibrary uniqueInstance
		duckdbPrepare: (aDuckDBConnection handle pointerAt: 1)
		query: sqlString
		outStatement: slot.
	returnCode = DuckDBLibrary success
		ifFalse: [
			slot free.
			DuckDBQueryError signal: 'Failed to prepare statement: ' , sqlString ].
	handle := slot
]

{ #category : 'binding' }
DuckDBStatement >> bind: aValue at: paramIndex [
	aValue ifNil: [ ^ self bindNull: paramIndex ].
	(aValue isKindOf: Boolean) ifTrue: [ ^ self bindBoolean: aValue at: paramIndex ].
	aValue isString ifTrue: [ ^ self bindString: aValue at: paramIndex ].
	aValue isInteger ifTrue: [ ^ self bindInteger: aValue at: paramIndex ].
	aValue isFloat ifTrue: [ ^ self bindFloat: aValue at: paramIndex ].
	(aValue isKindOf: DateAndTime) ifTrue: [
		^ self bindTimestamp: aValue at: paramIndex ].
	(aValue isKindOf: Date) ifTrue: [ ^ self bindDate: aValue at: paramIndex ].
	(aValue isKindOf: Time) ifTrue: [ ^ self bindTime: aValue at: paramIndex ].
	(aValue isKindOf: ByteArray) ifTrue: [
		^ self bindBlob: aValue at: paramIndex ].
	DuckDBBindError signal: 'Unsupported bind type: ' , aValue class name
]

{ #category : 'binding' }
DuckDBStatement >> bindBoolean: aBoolean at: paramIndex [
	| rc |
	rc := DuckDBLibrary uniqueInstance
		duckdbBindBoolean: (handle pointerAt: 1)
		paramIdx: paramIndex
		val: aBoolean.
	self checkBindResult: rc at: paramIndex
]

{ #category : 'binding' }
DuckDBStatement >> bindInteger: anInteger at: paramIndex [
	| rc |
	rc := DuckDBLibrary uniqueInstance
		duckdbBindInt64: (handle pointerAt: 1)
		paramIdx: paramIndex
		val: anInteger.
	self checkBindResult: rc at: paramIndex
]

{ #category : 'binding' }
DuckDBStatement >> bindFloat: aFloat at: paramIndex [
	| rc |
	rc := DuckDBLibrary uniqueInstance
		duckdbBindDouble: (handle pointerAt: 1)
		paramIdx: paramIndex
		val: aFloat.
	self checkBindResult: rc at: paramIndex
]

{ #category : 'binding' }
DuckDBStatement >> bindString: aString at: paramIndex [
	| rc |
	rc := DuckDBLibrary uniqueInstance
		duckdbBindVarchar: (handle pointerAt: 1)
		paramIdx: paramIndex
		val: aString.
	self checkBindResult: rc at: paramIndex
]

{ #category : 'binding' }
DuckDBStatement >> bindNull: paramIndex [
	| rc |
	rc := DuckDBLibrary uniqueInstance
		duckdbBindNull: (handle pointerAt: 1)
		paramIdx: paramIndex.
	self checkBindResult: rc at: paramIndex
]

{ #category : 'binding' }
DuckDBStatement >> bindDate: aDate at: paramIndex [
	"DuckDB DATE is int32 days since 1970-01-01."
	| rc struct epoch |
	epoch := Date year: 1970 month: 1 day: 1.
	struct := DuckDBDateStruct new.
	struct days: aDate julianDayNumber - epoch julianDayNumber.
	rc := DuckDBLibrary uniqueInstance
		duckdbBindDate: (handle pointerAt: 1)
		paramIdx: paramIndex
		val: struct.
	self checkBindResult: rc at: paramIndex
]

{ #category : 'binding' }
DuckDBStatement >> bindTime: aTime at: paramIndex [
	"DuckDB TIME is int64 microseconds since 00:00:00."
	| rc struct |
	struct := DuckDBTimeStruct new.
	struct micros: aTime asDuration asNanoSeconds // 1000.
	rc := DuckDBLibrary uniqueInstance
		duckdbBindTime: (handle pointerAt: 1)
		paramIdx: paramIndex
		val: struct.
	self checkBindResult: rc at: paramIndex
]

{ #category : 'binding' }
DuckDBStatement >> bindTimestamp: aDateAndTime at: paramIndex [
	"DuckDB TIMESTAMP is int64 microseconds since 1970-01-01 (no timezone).
	 The DateAndTime is converted to its UTC instant."
	| rc struct micros |
	micros := (aDateAndTime - (DateAndTime fromUnixTime: 0)) asNanoSeconds // 1000.
	struct := DuckDBTimestampStruct new.
	struct micros: micros.
	rc := DuckDBLibrary uniqueInstance
		duckdbBindTimestamp: (handle pointerAt: 1)
		paramIdx: paramIndex
		val: struct.
	self checkBindResult: rc at: paramIndex
]

{ #category : 'binding' }
DuckDBStatement >> bindBlob: aByteArray at: paramIndex [
	"DuckDB copies the bytes during the bind call."
	| rc |
	rc := DuckDBLibrary uniqueInstance
		duckdbBindBlob: (handle pointerAt: 1)
		paramIdx: paramIndex
		data: aByteArray
		length: aByteArray size.
	self checkBindResult: rc at: paramIndex
]

{ #category : 'private' }
DuckDBStatement >> checkBindResult: returnCode at: paramIndex [
	returnCode = DuckDBLibrary success
		ifFalse: [ DuckDBBindError signal: 'Bind failed at index: ' , paramIndex printString ]
]

{ #category : 'actions' }
DuckDBStatement >> executeWith: anArray [
	anArray withIndexDo: [ :value :index |
		self bind: value at: index ].
	^ self execute
]

{ #category : 'actions' }
DuckDBStatement >> execute [
	"Execute the prepared statement and return a DuckDBResult."
	| resultStruct returnCode |
	resultStruct := ExternalAddress allocate: DuckDBResultStruct byteSize.
	returnCode := DuckDBLibrary uniqueInstance
		duckdbExecutePrepared: (handle pointerAt: 1)
		outResult: resultStruct.
	returnCode = DuckDBLibrary success
		ifFalse: [
			| msg |
			msg := DuckDBLibrary uniqueInstance duckdbResultError: resultStruct.
			DuckDBLibrary uniqueInstance duckdbDestroyResult: resultStruct.
			DuckDBQueryError signal: (msg ifNil: ['Execution failed']) ].
	^ DuckDBResult on: resultStruct
]

{ #category : 'actions' }
DuckDBStatement >> destroy [
	handle ifNil: [ ^ self ].
	DuckDBLibrary uniqueInstance duckdbDestroyPrepare: handle.
	handle free.
	handle := nil
]

{ #category : 'accessing' }
DuckDBStatement >> parameterCount [
	^ DuckDBLibrary uniqueInstance duckdbNparams: (handle pointerAt: 1)
]

{ #category : 'testing' }
DuckDBStatement >> isDestroyed [
	^ handle isNil
]

{ #category : 'printing' }
DuckDBStatement >> printOn: aStream [
	aStream
		nextPutAll: 'DuckDBStatement(';
		nextPutAll: (sql ifNil: ['destroyed']);
		nextPut: $)
]