"
I represent the result of a DuckDB query.

I provide row access with `first` and enumeration with `do:`, `collect:` and `select:`,
plus metadata: `rowCount`, `columnCount`, `columnNames`.
I own a C-side result struct: always call `destroy` when done, inside an `ensure:` block.

Example:
	result := conn execute: 'SELECT * FROM range(3) t(n)'.
	[ result collect: [:row | row at: 'n'] ] ensure: [ result destroy ].
"
Class {
	#name : 'DuckDBResult',
	#superclass : 'Object',
	#instVars : [
		'resultStruct',
		'rowCount',
		'columnCount',
		'columnNames',
		'destroyed',
		'materializedRows'
	],
	#classVars : [],
	#package : 'DuckDB-Core'
}

{ #category : 'instance creation' }
DuckDBResult class >> on: aDuckDBResultStruct [
	^ self new
		initializeOn: aDuckDBResultStruct;
		yourself
]

{ #category : 'initialization' }
DuckDBResult >> initialize [
	super initialize.
	destroyed := false.
]

{ #category : 'private' }
DuckDBResult >> initializeOn: aDuckDBResultStruct [
	| lib |
	resultStruct := aDuckDBResultStruct.
	lib := DuckDBLibrary uniqueInstance.
	rowCount    := lib duckdbResultRowCount: resultStruct.
	columnCount := lib duckdbResultColumnCount: resultStruct.
	columnNames := (0 to: columnCount - 1) collect: [:i |
		lib duckdbColumnName: resultStruct col: i].
	self needsChunkReading ifTrue: [ self materializeChunks ]
]

{ #category : 'private' }
DuckDBResult >> needsChunkReading [
	"True when any column has a type the per-cell value API cannot read,
	 so the whole result must be materialized through the data chunk API."
	| lib chunkOnly |
	lib := DuckDBLibrary uniqueInstance.
	chunkOnly := DuckDBTypeMapper chunkOnlyTypeCodes.
	^ (0 to: columnCount - 1) anySatisfy: [:c |
		chunkOnly includes: (lib duckdbColumnType: resultStruct col: c) ]
]

{ #category : 'private' }
DuckDBResult >> materializeChunks [
	"Read every column through the data chunk API into a flat rows array.
	 value API and chunk API are not mixed on the same result: once any column
	 needs chunks, all columns are read this way."
	| lib rows chunk |
	lib := DuckDBLibrary uniqueInstance.
	rows := OrderedCollection new.
	[ chunk := lib duckdbFetchChunk: (DuckDBResultStruct fromHandle: resultStruct).
	  chunk isNull ] whileFalse: [
		[ self readChunk: chunk into: rows ] ensure: [ self destroyChunk: chunk ] ].
	materializedRows := rows asArray
]

{ #category : 'private' }
DuckDBResult >> readChunk: chunk into: rows [
	| lib size readers |
	lib := DuckDBLibrary uniqueInstance.
	size := lib duckdbDataChunkGetSize: chunk.
	readers := (0 to: columnCount - 1) collect: [:c |
		DuckDBVectorReader on: (lib duckdbDataChunkGetVector: chunk col: c) ].
	[ 0 to: size - 1 do: [:rowIdx |
		rows add: (readers collect: [:reader | reader valueAt: rowIdx]) ] ]
		ensure: [ readers do: [:reader | reader close] ]
]

{ #category : 'private' }
DuckDBResult >> destroyChunk: chunk [
	| lib slot |
	lib := DuckDBLibrary uniqueInstance.
	slot := ExternalAddress allocate: 8.
	slot pointerAt: 1 put: chunk.
	lib duckdbDestroyDataChunk: slot.
	slot free
]

{ #category : 'private' }
DuckDBResult >> valueAtRow: rowIdx col: colIdx [
	"Used by DuckDBRow. Materialized columns come from the chunk-read rows;
	 otherwise fall back to the per-cell value API via the type mapper."
	materializedRows ifNotNil: [
		^ (materializedRows at: rowIdx + 1) at: colIdx + 1 ].
	^ DuckDBTypeMapper default valueFromResult: resultStruct col: colIdx row: rowIdx
]

{ #category : 'enumerating' }
DuckDBResult >> do: aBlock [
	"Evaluate aBlock with each DuckDBRow."
	self checkNotDestroyed.
	0 to: rowCount - 1 do: [:rowIdx |
		aBlock value: (DuckDBRow on: self rowIndex: rowIdx)]
]

{ #category : 'enumerating' }
DuckDBResult >> collect: aBlock [
	"Return an OrderedCollection of aBlock values for each row."
	| results |
	results := OrderedCollection new.
	self do: [:row | results add: (aBlock value: row)].
	^ results
]

{ #category : 'enumerating' }
DuckDBResult >> select: aBlock [
	"Return an OrderedCollection of rows satisfying aBlock."
	| results |
	results := OrderedCollection new.
	self do: [:row | (aBlock value: row) ifTrue: [results add: row]].
	^ results
]

{ #category : 'accessing' }
DuckDBResult >> first [
	self checkNotDestroyed.
	rowCount = 0 ifTrue: [ self error: 'Result is empty' ].
	^ DuckDBRow on: self rowIndex: 0
]

{ #category : 'accessing' }
DuckDBResult >> rowCount [
	^ rowCount
]

{ #category : 'accessing' }
DuckDBResult >> columnCount [
	^ columnCount
]

{ #category : 'accessing' }
DuckDBResult >> columnNames [
	^ columnNames
]

{ #category : 'accessing' }
DuckDBResult >> resultStruct [
	^ resultStruct
]

{ #category : 'testing' }
DuckDBResult >> isEmpty [
	^ rowCount = 0
]

{ #category : 'testing' }
DuckDBResult >> isDestroyed [
	^ destroyed
]

{ #category : 'actions' }
DuckDBResult >> destroy [
	destroyed ifTrue: [ ^ self ].
	DuckDBLibrary uniqueInstance duckdbDestroyResult: resultStruct.
	resultStruct free.
	resultStruct := nil.
	destroyed := true.
]

{ #category : 'private' }
DuckDBResult >> checkNotDestroyed [
	destroyed ifTrue: [ self error: 'Result has already been destroyed' ]
]

{ #category : 'printing' }
DuckDBResult >> printOn: aStream [
	aStream
		nextPutAll: 'DuckDBResult(';
		print: rowCount;
		nextPutAll: ' rows, ';
		print: columnCount;
		nextPutAll: ' cols)'
]
