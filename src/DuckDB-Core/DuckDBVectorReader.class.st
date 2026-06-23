"
I decode one column vector of a DuckDB data chunk into Smalltalk objects,
row by row, recursing into nested types (LIST / STRUCT / MAP).

I exist because the deprecated per-cell value API cannot read nested types,
ENUM, UUID or TIMESTAMP_TZ — the data chunk / vector API can.
DuckDBResult uses me to materialize columns that the value API cannot handle.

I own a logical type handle and any child readers; always call `close`
when done (DuckDBResult does this after materializing).

Layout facts (DuckDB v1.5.2, from duckdb.h, byte offsets are 1-based for
ExternalAddress accessors):
 - validity: uint64 bitset, bit r%64 of word r//64; 1 = valid. NULL pointer = all valid.
 - VARCHAR/BLOB cell = duckdb_string_t (16 bytes): uint32 length at +0; if length<=12
   the bytes are inlined at +4, otherwise a char* pointer sits at +8.
 - LIST cell = duckdb_list_entry (16 bytes): uint64 offset at +0, uint64 length at +8.
"
Class {
	#name : 'DuckDBVectorReader',
	#superclass : 'Object',
	#instVars : [
		'vector',
		'logicalType',
		'typeCode',
		'lib',
		'dataPointer',
		'validity'
	],
	#classVars : [],
	#package : 'DuckDB-Core'
}

{ #category : 'instance creation' }
DuckDBVectorReader class >> on: aVector [
	^ self new
		initializeOn: aVector;
		yourself
]

{ #category : 'initialization' }
DuckDBVectorReader >> initializeOn: aVector [
	lib := DuckDBLibrary uniqueInstance.
	vector := aVector.
	logicalType := lib duckdbVectorGetColumnType: aVector.
	typeCode := lib duckdbGetTypeId: logicalType.
	dataPointer := lib duckdbVectorGetData: aVector.
	validity := lib duckdbVectorGetValidity: aVector
]

{ #category : 'actions' }
DuckDBVectorReader >> close [
	"Release the logical type handle. Child readers (nested types) override
	 by closing their children first."
	logicalType ifNil: [ ^ self ].
	self destroyLogicalType: logicalType.
	logicalType := nil
]

{ #category : 'private' }
DuckDBVectorReader >> destroyLogicalType: aLogicalType [
	| slot |
	slot := ExternalAddress allocate: 8.
	slot pointerAt: 1 put: aLogicalType.
	lib duckdbDestroyLogicalType: slot.
	slot free
]

{ #category : 'accessing' }
DuckDBVectorReader >> typeCode [
	^ typeCode
]

{ #category : 'reading' }
DuckDBVectorReader >> valueAt: rowIdx [
	"Answer the Smalltalk object for the cell at rowIdx, or nil if it is NULL."
	(self isValidAt: rowIdx) ifFalse: [ ^ nil ].
	^ self perform: (self decodeSelectorFor: typeCode) with: rowIdx
]

{ #category : 'private' }
DuckDBVectorReader >> isValidAt: rowIdx [
	| word |
	validity isNull ifTrue: [ ^ true ].
	word := validity unsignedLongLongAt: rowIdx // 64 * 8 + 1.
	^ (word bitShift: (rowIdx \\ 64) negated) odd
]

{ #category : 'private' }
DuckDBVectorReader >> decodeSelectorFor: aTypeCode [
	^ (self numericDecodeSelectorFor: aTypeCode)
		ifNil: [ (self temporalDecodeSelectorFor: aTypeCode)
		ifNil: [ self bytesDecodeSelectorFor: aTypeCode ] ]
]

{ #category : 'private' }
DuckDBVectorReader >> temporalDecodeSelectorFor: aTypeCode [
	"Temporal, big-integer, decimal, enum and uuid types decoded from the raw
	 vector buffer (the value API cannot reach enum / uuid / timestamp_tz at all)."
	| mapper |
	mapper := DuckDBTypeMapper.
	aTypeCode = mapper typeDate ifTrue: [ ^ #decodeDateAt: ].
	aTypeCode = mapper typeTime ifTrue: [ ^ #decodeTimeAt: ].
	aTypeCode = mapper typeTimestamp ifTrue: [ ^ #decodeTimestampAt: ].
	aTypeCode = mapper typeTimestampTz ifTrue: [ ^ #decodeTimestampAt: ].
	aTypeCode = mapper typeHugeInt ifTrue: [ ^ #decodeHugeintAt: ].
	aTypeCode = mapper typeUHugeInt ifTrue: [ ^ #decodeUHugeintAt: ].
	aTypeCode = mapper typeDecimal ifTrue: [ ^ #decodeDecimalAt: ].
	aTypeCode = mapper typeEnum ifTrue: [ ^ #decodeEnumAt: ].
	aTypeCode = mapper typeUuid ifTrue: [ ^ #decodeUuidAt: ].
	^ nil
]

{ #category : 'private' }
DuckDBVectorReader >> numericDecodeSelectorFor: aTypeCode [
	| mapper |
	mapper := DuckDBTypeMapper.
	aTypeCode = mapper typeBoolean ifTrue: [ ^ #decodeBooleanAt: ].
	aTypeCode = mapper typeTinyInt ifTrue: [ ^ #decodeInt8At: ].
	aTypeCode = mapper typeSmallInt ifTrue: [ ^ #decodeInt16At: ].
	aTypeCode = mapper typeInteger ifTrue: [ ^ #decodeInt32At: ].
	aTypeCode = mapper typeBigInt ifTrue: [ ^ #decodeInt64At: ].
	aTypeCode = mapper typeUTinyInt ifTrue: [ ^ #decodeUInt8At: ].
	aTypeCode = mapper typeUSmallInt ifTrue: [ ^ #decodeUInt16At: ].
	aTypeCode = mapper typeUInteger ifTrue: [ ^ #decodeUInt32At: ].
	aTypeCode = mapper typeUBigInt ifTrue: [ ^ #decodeUInt64At: ].
	aTypeCode = mapper typeFloat ifTrue: [ ^ #decodeFloatAt: ].
	aTypeCode = mapper typeDouble ifTrue: [ ^ #decodeDoubleAt: ].
	^ nil
]

{ #category : 'private' }
DuckDBVectorReader >> bytesDecodeSelectorFor: aTypeCode [
	| mapper |
	mapper := DuckDBTypeMapper.
	aTypeCode = mapper typeVarchar ifTrue: [ ^ #decodeVarcharAt: ].
	aTypeCode = mapper typeBlob ifTrue: [ ^ #decodeBlobAt: ].
	^ self error: 'Unsupported column type code: ' , aTypeCode printString
]

{ #category : 'decoding - numeric' }
DuckDBVectorReader >> decodeBooleanAt: rowIdx [
	^ (dataPointer unsignedByteAt: rowIdx + 1) ~= 0
]

{ #category : 'decoding - numeric' }
DuckDBVectorReader >> decodeInt8At: rowIdx [
	^ dataPointer signedByteAt: rowIdx + 1
]

{ #category : 'decoding - numeric' }
DuckDBVectorReader >> decodeInt16At: rowIdx [
	^ dataPointer signedShortAt: rowIdx * 2 + 1
]

{ #category : 'decoding - numeric' }
DuckDBVectorReader >> decodeInt32At: rowIdx [
	^ dataPointer signedLongAt: rowIdx * 4 + 1
]

{ #category : 'decoding - numeric' }
DuckDBVectorReader >> decodeInt64At: rowIdx [
	^ dataPointer signedLongLongAt: rowIdx * 8 + 1
]

{ #category : 'decoding - numeric' }
DuckDBVectorReader >> decodeUInt8At: rowIdx [
	^ dataPointer unsignedByteAt: rowIdx + 1
]

{ #category : 'decoding - numeric' }
DuckDBVectorReader >> decodeUInt16At: rowIdx [
	^ dataPointer unsignedShortAt: rowIdx * 2 + 1
]

{ #category : 'decoding - numeric' }
DuckDBVectorReader >> decodeUInt32At: rowIdx [
	^ dataPointer unsignedLongAt: rowIdx * 4 + 1
]

{ #category : 'decoding - numeric' }
DuckDBVectorReader >> decodeUInt64At: rowIdx [
	^ dataPointer unsignedLongLongAt: rowIdx * 8 + 1
]

{ #category : 'decoding - numeric' }
DuckDBVectorReader >> decodeFloatAt: rowIdx [
	^ dataPointer floatAt: rowIdx * 4 + 1
]

{ #category : 'decoding - numeric' }
DuckDBVectorReader >> decodeDoubleAt: rowIdx [
	^ dataPointer doubleAt: rowIdx * 8 + 1
]

{ #category : 'decoding - temporal' }
DuckDBVectorReader >> decodeDateAt: rowIdx [
	^ DuckDBTypeMapper dateFromDays: (dataPointer signedLongAt: rowIdx * 4 + 1)
]

{ #category : 'decoding - temporal' }
DuckDBVectorReader >> decodeTimeAt: rowIdx [
	^ DuckDBTypeMapper timeFromMicros: (dataPointer signedLongLongAt: rowIdx * 8 + 1)
]

{ #category : 'decoding - temporal' }
DuckDBVectorReader >> decodeTimestampAt: rowIdx [
	"TIMESTAMP and TIMESTAMP_TZ share the same int64 micros-since-epoch storage."
	^ DuckDBTypeMapper dateAndTimeFromMicros: (dataPointer signedLongLongAt: rowIdx * 8 + 1)
]

{ #category : 'decoding - numeric' }
DuckDBVectorReader >> decodeHugeintAt: rowIdx [
	"duckdb_hugeint: { uint64 lower; int64 upper }; value = upper * 2^64 + lower."
	| base lower upper |
	base := rowIdx * 16.
	lower := dataPointer unsignedLongLongAt: base + 1.
	upper := dataPointer signedLongLongAt: base + 9.
	^ (upper bitShift: 64) + lower
]

{ #category : 'decoding - numeric' }
DuckDBVectorReader >> decodeUHugeintAt: rowIdx [
	"duckdb_uhugeint: { uint64 lower; uint64 upper }; value = upper * 2^64 + lower."
	| base lower upper |
	base := rowIdx * 16.
	lower := dataPointer unsignedLongLongAt: base + 1.
	upper := dataPointer unsignedLongLongAt: base + 9.
	^ (upper bitShift: 64) + lower
]

{ #category : 'decoding - numeric' }
DuckDBVectorReader >> decodeDecimalAt: rowIdx [
	"Raw integer stored in the decimal's internal type, scaled by 10^scale."
	| scale raw |
	scale := lib duckdbDecimalScale: logicalType.
	raw := self decimalRawAt: rowIdx internalType: (lib duckdbDecimalInternalType: logicalType).
	^ (raw / (10 raisedTo: scale)) asScaledDecimal: scale
]

{ #category : 'private' }
DuckDBVectorReader >> decimalRawAt: rowIdx internalType: internalType [
	| mapper |
	mapper := DuckDBTypeMapper.
	internalType = mapper typeSmallInt ifTrue: [ ^ dataPointer signedShortAt: rowIdx * 2 + 1 ].
	internalType = mapper typeInteger ifTrue: [ ^ dataPointer signedLongAt: rowIdx * 4 + 1 ].
	internalType = mapper typeBigInt ifTrue: [ ^ dataPointer signedLongLongAt: rowIdx * 8 + 1 ].
	internalType = mapper typeHugeInt ifTrue: [ ^ self decodeHugeintAt: rowIdx ].
	^ dataPointer signedByteAt: rowIdx + 1
]

{ #category : 'decoding - other' }
DuckDBVectorReader >> decodeEnumAt: rowIdx [
	"The cell stores an index into the enum's dictionary; fetch its label string."
	| idx namePointer |
	idx := self enumIndexAt: rowIdx internalType: (lib duckdbEnumInternalType: logicalType).
	namePointer := lib duckdbEnumDictionaryValue: logicalType index: idx.
	^ [ namePointer utf8StringFromCString ] ensure: [ lib duckdbFree: namePointer ]
]

{ #category : 'private' }
DuckDBVectorReader >> enumIndexAt: rowIdx internalType: internalType [
	| mapper |
	mapper := DuckDBTypeMapper.
	internalType = mapper typeUSmallInt ifTrue: [ ^ dataPointer unsignedShortAt: rowIdx * 2 + 1 ].
	internalType = mapper typeUInteger ifTrue: [ ^ dataPointer unsignedLongAt: rowIdx * 4 + 1 ].
	^ dataPointer unsignedByteAt: rowIdx + 1
]

{ #category : 'decoding - other' }
DuckDBVectorReader >> decodeUuidAt: rowIdx [
	"UUID is stored as a hugeint with the high bit of the upper word flipped.
	 Recover the 128-bit value and render the canonical 8-4-4-4-12 hex form."
	| base lower upper value |
	base := rowIdx * 16.
	lower := dataPointer unsignedLongLongAt: base + 1.
	upper := (dataPointer unsignedLongLongAt: base + 9) bitXor: (1 bitShift: 63).
	value := (upper bitShift: 64) + lower.
	^ UUID fromString: (self uuidStringFromInteger: value)
]

{ #category : 'private' }
DuckDBVectorReader >> uuidStringFromInteger: value [
	| hex |
	hex := (value printPaddedWith: $0 to: 32 base: 16) asLowercase.
	^ String streamContents: [ :s |
		s nextPutAll: (hex copyFrom: 1 to: 8); nextPut: $-.
		s nextPutAll: (hex copyFrom: 9 to: 12); nextPut: $-.
		s nextPutAll: (hex copyFrom: 13 to: 16); nextPut: $-.
		s nextPutAll: (hex copyFrom: 17 to: 20); nextPut: $-.
		s nextPutAll: (hex copyFrom: 21 to: 32) ]
]

{ #category : 'decoding - bytes' }
DuckDBVectorReader >> decodeVarcharAt: rowIdx [
	^ (self rawBytesAt: rowIdx) utf8Decoded
]

{ #category : 'decoding - bytes' }
DuckDBVectorReader >> decodeBlobAt: rowIdx [
	^ self rawBytesAt: rowIdx
]

{ #category : 'private' }
DuckDBVectorReader >> rawBytesAt: rowIdx [
	"Decode the duckdb_string_t (16 bytes) at rowIdx into a ByteArray.
	 length<=12 keeps the bytes inline at +4, otherwise a char* pointer sits at +8."
	| base length |
	base := rowIdx * 16.
	length := dataPointer unsignedLongAt: base + 1.
	^ length <= 12
		ifTrue: [ self readBytes: length from: dataPointer at: base + 4 ]
		ifFalse: [ self readBytes: length from: (dataPointer pointerAt: base + 9) at: 0 ]
]

{ #category : 'private' }
DuckDBVectorReader >> readBytes: length from: aPointer at: byteOffset [
	| bytes |
	bytes := ByteArray new: length.
	1 to: length do: [ :i |
		bytes at: i put: (aPointer unsignedByteAt: byteOffset + i) ].
	^ bytes
]
