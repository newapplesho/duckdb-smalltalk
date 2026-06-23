"
I map DuckDB column type codes to Smalltalk objects.

I extract cell values from a result struct via the matching duckdb_value_* FFI call:
BOOLEAN as Boolean, the integer family as Integer, FLOAT/DOUBLE as Float,
VARCHAR as String, plus dedicated handlers for DATE, TIME, TIMESTAMP, INTERVAL,
BLOB, DECIMAL and HUGEINT/UHUGEINT. NULL is always answered as nil.

I only handle types the deprecated per-cell value API can read. ENUM, UUID and
TIMESTAMP_TZ cannot be read that way: DuckDBResult detects them (see
`chunkOnlyTypeCodes`) and routes the whole result through the data chunk API
(DuckDBVectorReader) instead, so I am never asked to convert them.

I am used through my singleton: `DuckDBTypeMapper default`.
"
Class {
	#name : 'DuckDBTypeMapper',
	#superclass : 'Object',
	#instVars : [],
	#classVars : [
		'Default'
	],
	#package : 'DuckDB-Core'
}

{ #category : 'accessing' }
DuckDBTypeMapper class >> default [
	Default ifNil: [ Default := self new ].
	^ Default
]

{ #category : 'type codes' }
DuckDBTypeMapper class >> typeBoolean [
	^ 1
]

{ #category : 'type codes' }
DuckDBTypeMapper class >> typeTinyInt [
	^ 2
]

{ #category : 'type codes' }
DuckDBTypeMapper class >> typeSmallInt [
	^ 3
]

{ #category : 'type codes' }
DuckDBTypeMapper class >> typeInteger [
	^ 4
]

{ #category : 'type codes' }
DuckDBTypeMapper class >> typeBigInt [
	^ 5
]

{ #category : 'type codes' }
DuckDBTypeMapper class >> typeUTinyInt [
	^ 6
]

{ #category : 'type codes' }
DuckDBTypeMapper class >> typeUSmallInt [
	^ 7
]

{ #category : 'type codes' }
DuckDBTypeMapper class >> typeUInteger [
	^ 8
]

{ #category : 'type codes' }
DuckDBTypeMapper class >> typeUBigInt [
	^ 9
]

{ #category : 'type codes' }
DuckDBTypeMapper class >> typeFloat [
	"DUCKDB_TYPE_FLOAT = 10 in duckdb.h (v1.5.2)"
	^ 10
]

{ #category : 'type codes' }
DuckDBTypeMapper class >> typeDouble [
	"DUCKDB_TYPE_DOUBLE = 11 in duckdb.h (v1.5.2)"
	^ 11
]

{ #category : 'type codes' }
DuckDBTypeMapper class >> typeTimestamp [
	^ 12
]

{ #category : 'type codes' }
DuckDBTypeMapper class >> typeDate [
	^ 13
]

{ #category : 'type codes' }
DuckDBTypeMapper class >> typeTime [
	^ 14
]

{ #category : 'type codes' }
DuckDBTypeMapper class >> typeInterval [
	^ 15
]

{ #category : 'type codes' }
DuckDBTypeMapper class >> typeHugeInt [
	^ 16
]

{ #category : 'type codes' }
DuckDBTypeMapper class >> typeVarchar [
	^ 17
]

{ #category : 'type codes' }
DuckDBTypeMapper class >> typeBlob [
	^ 18
]

{ #category : 'type codes' }
DuckDBTypeMapper class >> typeDecimal [
	^ 19
]

{ #category : 'type codes' }
DuckDBTypeMapper class >> typeEnum [
	^ 23
]

{ #category : 'type codes' }
DuckDBTypeMapper class >> typeList [
	^ 24
]

{ #category : 'type codes' }
DuckDBTypeMapper class >> typeStruct [
	^ 25
]

{ #category : 'type codes' }
DuckDBTypeMapper class >> typeMap [
	^ 26
]

{ #category : 'type codes' }
DuckDBTypeMapper class >> typeUuid [
	^ 27
]

{ #category : 'type codes' }
DuckDBTypeMapper class >> typeTimestampTz [
	^ 31
]

{ #category : 'type codes' }
DuckDBTypeMapper class >> typeUHugeInt [
	^ 32
]

{ #category : 'type codes' }
DuckDBTypeMapper class >> chunkOnlyTypeCodes [
	"Types the deprecated per-cell value API cannot read; they require the
	 data chunk / vector API (decoded by DuckDBVectorReader)."
	^ {
		self typeEnum.
		self typeList.
		self typeStruct.
		self typeMap.
		self typeUuid.
		self typeTimestampTz }
]

{ #category : 'accessing' }
DuckDBTypeMapper >> valueFromResult: resultStruct col: colIdx row: rowIdx [
	"Return a Smalltalk object for the cell at (colIdx, rowIdx)."
	| lib typeCode |
	lib := DuckDBLibrary uniqueInstance.
	(lib duckdbValueIsNull: resultStruct col: colIdx row: rowIdx)
		ifTrue: [ ^ nil ].
	typeCode := lib duckdbColumnType: resultStruct col: colIdx.
	^ self
		convertType: typeCode
		result: resultStruct
		col: colIdx
		row: rowIdx
]

{ #category : 'private' }
DuckDBTypeMapper >> convertType: typeCode result: resultStruct col: colIdx row: rowIdx [
	^ self
		perform: (self conversionSelectorFor: typeCode)
		with: resultStruct
		with: colIdx
		with: rowIdx
]

{ #category : 'private' }
DuckDBTypeMapper >> conversionSelectorFor: typeCode [
	"Answer my selector that converts a cell of the given type to a Smalltalk object.
	 VARCHAR and unsupported types fall back to string conversion."
	^ (self numericConversionSelectorFor: typeCode)
		ifNil: [ self complexConversionSelectorFor: typeCode ]
]

{ #category : 'private' }
DuckDBTypeMapper >> numericConversionSelectorFor: typeCode [
	typeCode = self class typeBoolean ifTrue: [ ^ #booleanFrom:col:row: ].
	typeCode = self class typeTinyInt ifTrue: [ ^ #int8From:col:row: ].
	typeCode = self class typeSmallInt ifTrue: [ ^ #int16From:col:row: ].
	typeCode = self class typeInteger ifTrue: [ ^ #int32From:col:row: ].
	typeCode = self class typeBigInt ifTrue: [ ^ #int64From:col:row: ].
	typeCode = self class typeUTinyInt ifTrue: [ ^ #uint8From:col:row: ].
	typeCode = self class typeUSmallInt ifTrue: [ ^ #uint16From:col:row: ].
	typeCode = self class typeUInteger ifTrue: [ ^ #uint32From:col:row: ].
	typeCode = self class typeUBigInt ifTrue: [ ^ #uint64From:col:row: ].
	typeCode = self class typeFloat ifTrue: [ ^ #floatFrom:col:row: ].
	typeCode = self class typeDouble ifTrue: [ ^ #doubleFrom:col:row: ].
	^ nil
]

{ #category : 'private' }
DuckDBTypeMapper >> complexConversionSelectorFor: typeCode [
	"UHUGEINT reuses the exact text-based integer conversion.
	 ENUM / UUID / TIMESTAMP_TZ / LIST / STRUCT / MAP cannot be extracted through
	 the deprecated per-cell value API (verified: duckdb_value_varchar returns NULL
	 for them). They never reach this method: DuckDBResult>>needsChunkReading
	 detects the chunk-only type codes and reads the whole result through the data
	 chunk API (DuckDBVectorReader). The stringFrom: fallback below is only the
	 safety net for any other unhandled scalar type."
	typeCode = self class typeDate ifTrue: [ ^ #dateFrom:col:row: ].
	typeCode = self class typeTime ifTrue: [ ^ #timeFrom:col:row: ].
	typeCode = self class typeTimestamp ifTrue: [ ^ #timestampFrom:col:row: ].
	typeCode = self class typeInterval ifTrue: [ ^ #intervalFrom:col:row: ].
	typeCode = self class typeBlob ifTrue: [ ^ #blobFrom:col:row: ].
	typeCode = self class typeDecimal ifTrue: [ ^ #decimalFrom:col:row: ].
	typeCode = self class typeHugeInt ifTrue: [ ^ #hugeintFrom:col:row: ].
	typeCode = self class typeUHugeInt ifTrue: [ ^ #hugeintFrom:col:row: ].
	^ #stringFrom:col:row:
]

{ #category : 'private - conversions' }
DuckDBTypeMapper >> booleanFrom: resultStruct col: colIdx row: rowIdx [
	^ DuckDBLibrary uniqueInstance duckdbValueBoolean: resultStruct col: colIdx row: rowIdx
]

{ #category : 'private - conversions' }
DuckDBTypeMapper >> int8From: resultStruct col: colIdx row: rowIdx [
	^ DuckDBLibrary uniqueInstance duckdbValueInt8: resultStruct col: colIdx row: rowIdx
]

{ #category : 'private - conversions' }
DuckDBTypeMapper >> int16From: resultStruct col: colIdx row: rowIdx [
	^ DuckDBLibrary uniqueInstance duckdbValueInt16: resultStruct col: colIdx row: rowIdx
]

{ #category : 'private - conversions' }
DuckDBTypeMapper >> int32From: resultStruct col: colIdx row: rowIdx [
	^ DuckDBLibrary uniqueInstance duckdbValueInt32: resultStruct col: colIdx row: rowIdx
]

{ #category : 'private - conversions' }
DuckDBTypeMapper >> int64From: resultStruct col: colIdx row: rowIdx [
	^ DuckDBLibrary uniqueInstance duckdbValueInt64: resultStruct col: colIdx row: rowIdx
]

{ #category : 'private - conversions' }
DuckDBTypeMapper >> uint8From: resultStruct col: colIdx row: rowIdx [
	^ DuckDBLibrary uniqueInstance duckdbValueUInt8: resultStruct col: colIdx row: rowIdx
]

{ #category : 'private - conversions' }
DuckDBTypeMapper >> uint16From: resultStruct col: colIdx row: rowIdx [
	^ DuckDBLibrary uniqueInstance duckdbValueUInt16: resultStruct col: colIdx row: rowIdx
]

{ #category : 'private - conversions' }
DuckDBTypeMapper >> uint32From: resultStruct col: colIdx row: rowIdx [
	^ DuckDBLibrary uniqueInstance duckdbValueUInt32: resultStruct col: colIdx row: rowIdx
]

{ #category : 'private - conversions' }
DuckDBTypeMapper >> uint64From: resultStruct col: colIdx row: rowIdx [
	^ DuckDBLibrary uniqueInstance duckdbValueUInt64: resultStruct col: colIdx row: rowIdx
]

{ #category : 'private - conversions' }
DuckDBTypeMapper >> intervalFrom: resultStruct col: colIdx row: rowIdx [
	"INTERVAL keeps its three exact components (months / days / micros):
	 months vary in length, so no fixed Duration can represent them."
	| struct |
	struct := DuckDBLibrary uniqueInstance
		duckdbValueInterval: resultStruct
		col: colIdx
		row: rowIdx.
	^ DuckDBInterval
		months: struct months
		days: struct days
		microseconds: struct micros
]

{ #category : 'private - conversions' }
DuckDBTypeMapper >> floatFrom: resultStruct col: colIdx row: rowIdx [
	^ DuckDBLibrary uniqueInstance duckdbValueFloat: resultStruct col: colIdx row: rowIdx
]

{ #category : 'private - conversions' }
DuckDBTypeMapper >> doubleFrom: resultStruct col: colIdx row: rowIdx [
	^ DuckDBLibrary uniqueInstance duckdbValueDouble: resultStruct col: colIdx row: rowIdx
]

{ #category : 'private - conversions' }
DuckDBTypeMapper >> stringFrom: resultStruct col: colIdx row: rowIdx [
	"duckdb_value_varchar returns a malloc'ed char* owned by the caller:
	 read it as UTF-8, then release it with duckdb_free."
	| lib pointer |
	lib := DuckDBLibrary uniqueInstance.
	pointer := lib duckdbValueVarchar: resultStruct col: colIdx row: rowIdx.
	pointer isNull ifTrue: [ ^ nil ].
	^ [ pointer utf8StringFromCString ] ensure: [ lib duckdbFree: pointer ]
]

{ #category : 'private - conversions' }
DuckDBTypeMapper >> blobFrom: resultStruct col: colIdx row: rowIdx [
	"duckdb_blob.data is a malloc'ed buffer owned by the caller:
	 copy it into a ByteArray, then release it with duckdb_free."
	| lib blob data |
	lib := DuckDBLibrary uniqueInstance.
	blob := lib duckdbValueBlob: resultStruct col: colIdx row: rowIdx.
	data := blob data.
	data isNull ifTrue: [ ^ ByteArray new ].
	^ [ self copyBytesFrom: data size: blob size ]
		ensure: [ lib duckdbFree: data ]
]

{ #category : 'private' }
DuckDBTypeMapper >> copyBytesFrom: anExternalAddress size: byteCount [
	| bytes |
	bytes := ByteArray new: byteCount.
	1 to: byteCount do: [ :i |
		bytes at: i put: (anExternalAddress byteAt: i) ].
	^ bytes
]

{ #category : 'private - conversions' }
DuckDBTypeMapper >> decimalFrom: resultStruct col: colIdx row: rowIdx [
	"DECIMAL is converted exactly via its text representation: duckdb_decimal is a
	 16-byte-plus struct and decimal_to_double would be lossy. The number of digits
	 after the decimal point becomes the ScaledDecimal scale."
	| text |
	text := self stringFrom: resultStruct col: colIdx row: rowIdx.
	^ self class scaledDecimalFromString: text
]

{ #category : 'converting' }
DuckDBTypeMapper class >> scaledDecimalFromString: aString [
	| dotIndex scale |
	dotIndex := aString indexOf: $..
	scale := dotIndex = 0
		ifTrue: [ 0 ]
		ifFalse: [ aString size - dotIndex ].
	^ (aString , 's' , scale printString) asNumber
]

{ #category : 'converting' }
DuckDBTypeMapper class >> dateFromDays: dayCount [
	"DuckDB DATE is int32 days since 1970-01-01 (duckdb.h)."
	^ (Date year: 1970 month: 1 day: 1) addDays: dayCount
]

{ #category : 'converting' }
DuckDBTypeMapper class >> timeFromMicros: micros [
	"DuckDB TIME is int64 microseconds since 00:00:00 (duckdb.h)."
	^ Time seconds: micros // 1000000 nanoSeconds: micros \\ 1000000 * 1000
]

{ #category : 'converting' }
DuckDBTypeMapper class >> dateAndTimeFromMicros: micros [
	"DuckDB TIMESTAMP / TIMESTAMP_TZ is int64 microseconds since 1970-01-01;
	 answered as a DateAndTime at offset 0 (UTC)."
	^ (DateAndTime fromUnixTime: micros // 1000000)
		+ (Duration nanoSeconds: micros \\ 1000000 * 1000)
]

{ #category : 'private - conversions' }
DuckDBTypeMapper >> hugeintFrom: resultStruct col: colIdx row: rowIdx [
	"HUGEINT is converted exactly via its text representation: Pharo Integers have
	 arbitrary precision, while duckdb_hugeint_to_double would be lossy."
	^ (self stringFrom: resultStruct col: colIdx row: rowIdx) asNumber
]

{ #category : 'private - conversions' }
DuckDBTypeMapper >> dateFrom: resultStruct col: colIdx row: rowIdx [
	| dateStruct |
	dateStruct := DuckDBLibrary uniqueInstance
		duckdbValueDate: resultStruct
		col: colIdx
		row: rowIdx.
	^ self class dateFromDays: dateStruct days
]

{ #category : 'private - conversions' }
DuckDBTypeMapper >> timeFrom: resultStruct col: colIdx row: rowIdx [
	| micros |
	micros := (DuckDBLibrary uniqueInstance
		duckdbValueTime: resultStruct
		col: colIdx
		row: rowIdx) micros.
	^ self class timeFromMicros: micros
]

{ #category : 'private - conversions' }
DuckDBTypeMapper >> timestampFrom: resultStruct col: colIdx row: rowIdx [
	| micros |
	micros := (DuckDBLibrary uniqueInstance
		duckdbValueTimestamp: resultStruct
		col: colIdx
		row: rowIdx) micros.
	^ self class dateAndTimeFromMicros: micros
]
