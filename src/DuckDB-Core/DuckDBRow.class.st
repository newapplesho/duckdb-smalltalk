"
I represent a single row in a DuckDBResult.

I provide value access by column name (`at:`), by 0-based index (`atIndex:`),
and conversion to a Dictionary (`asDictionary`).
I am only valid while my result has not been destroyed — do not keep me
after the result's `destroy` has been called.

Example:
	result do: [:row | Transcript showCr: (row at: 'name') ].
"
Class {
	#name : 'DuckDBRow',
	#superclass : 'Object',
	#instVars : [
		'result',
		'rowIndex'
	],
	#classVars : [],
	#package : 'DuckDB-Core'
}

{ #category : 'instance creation' }
DuckDBRow class >> on: aDuckDBResult rowIndex: anIndex [
	^ self new
		initializeOn: aDuckDBResult rowIndex: anIndex;
		yourself
]

{ #category : 'private' }
DuckDBRow >> initializeOn: aDuckDBResult rowIndex: anIndex [
	result   := aDuckDBResult.
	rowIndex := anIndex.
]

{ #category : 'accessing' }
DuckDBRow >> at: columnName [
	"Return the value at the named column (case-sensitive)."
	| colIdx |
	colIdx := result columnNames indexOf: columnName.
	colIdx = 0 ifTrue: [
		self error: 'Unknown column: ' , columnName ].
	^ self atIndex: colIdx - 1
]

{ #category : 'accessing' }
DuckDBRow >> atIndex: zeroBasedColIndex [
	"Return the value at the given 0-based column index.
	 The result decides whether this comes from materialized chunk data or the
	 per-cell value API."
	^ result valueAtRow: rowIndex col: zeroBasedColIndex
]

{ #category : 'accessing' }
DuckDBRow >> first [
	^ self atIndex: 0
]

{ #category : 'converting' }
DuckDBRow >> asDictionary [
	"Return a Dictionary mapping column name → value."
	| dict |
	dict := Dictionary new.
	result columnNames doWithIndex: [:name :i |
		dict at: name put: (self atIndex: i - 1)].
	^ dict
]

{ #category : 'printing' }
DuckDBRow >> printOn: aStream [
	aStream nextPutAll: 'DuckDBRow('.
	result columnNames doWithIndex: [:name :i |
		i > 1 ifTrue: [aStream nextPutAll: ', '].
		aStream
			nextPutAll: name;
			nextPutAll: ': ';
			print: (self atIndex: i - 1)].
	aStream nextPut: $)
]
