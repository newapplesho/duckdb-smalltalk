"
I test the rich type conversions of DuckDBTypeMapper:
DATE / TIME / TIMESTAMP / BLOB / DECIMAL / HUGEINT extraction
and the corresponding prepared-statement bind methods.
"
Class {
	#name : 'DuckDBTypeTest',
	#superclass : 'TestCase',
	#instVars : [
		'db',
		'conn'
	],
	#package : 'DuckDB-Tests'
}

{ #category : 'running' }
DuckDBTypeTest >> setUp [
	super setUp.
	db := DuckDB openMemory.
	conn := db connect
]

{ #category : 'running' }
DuckDBTypeTest >> tearDown [
	conn ifNotNil: [ conn isConnected ifTrue: [ conn disconnect ] ].
	db ifNotNil: [ db isOpen ifTrue: [ db close ] ].
	super tearDown
]

{ #category : 'tests - select' }
DuckDBTypeTest >> testSelectDateReturnsDate [
	| result value |
	result := conn execute: 'SELECT DATE ''2024-03-15'' AS d'.
	[
		value := result first at: 'd'.
		self assert: value equals: (Date year: 2024 month: 3 day: 15)
	] ensure: [ result destroy ]
]

{ #category : 'tests - select' }
DuckDBTypeTest >> testSelectTimeReturnsTime [
	| result value |
	result := conn execute: 'SELECT TIME ''12:34:56'' AS t'.
	[
		value := result first at: 't'.
		self assert: value equals: (Time hour: 12 minute: 34 second: 56)
	] ensure: [ result destroy ]
]

{ #category : 'tests - select' }
DuckDBTypeTest >> testSelectTimeWithMicrosecondsReturnsTime [
	| result value expected |
	result := conn execute: 'SELECT TIME ''12:34:56.789012'' AS t'.
	[
		value := result first at: 't'.
		expected := Time seconds: 12 * 3600 + (34 * 60) + 56 nanoSeconds: 789012000.
		self assert: value equals: expected
	] ensure: [ result destroy ]
]

{ #category : 'tests - select' }
DuckDBTypeTest >> testSelectTimestampReturnsDateAndTime [
	| result value expected |
	result := conn execute: 'SELECT TIMESTAMP ''2024-03-15 12:34:56'' AS ts'.
	[
		value := result first at: 'ts'.
		expected := DateAndTime
			year: 2024 month: 3 day: 15
			hour: 12 minute: 34 second: 56
			offset: Duration zero.
		self assert: value equals: expected
	] ensure: [ result destroy ]
]

{ #category : 'tests - select' }
DuckDBTypeTest >> testSelectTimestampWithMicrosecondsReturnsDateAndTime [
	| result value expected |
	result := conn execute: 'SELECT TIMESTAMP ''2024-03-15 12:34:56.123456'' AS ts'.
	[
		value := result first at: 'ts'.
		expected := (DateAndTime
			year: 2024 month: 3 day: 15
			hour: 12 minute: 34 second: 56
			offset: Duration zero) + (Duration nanoSeconds: 123456000).
		self assert: value equals: expected
	] ensure: [ result destroy ]
]

{ #category : 'tests - select' }
DuckDBTypeTest >> testSelectVarcharStillReturnsString [
	"Regression guard for the duckdb_free fix: varchar extraction must keep working."
	| result |
	result := conn execute: 'SELECT ''hello'' AS s'.
	[
		self assert: (result first at: 's') equals: 'hello'
	] ensure: [ result destroy ]
]

{ #category : 'tests - select' }
DuckDBTypeTest >> testSelectMultibyteVarcharReturnsUtf8String [
	| result |
	result := conn execute: 'SELECT ''こんにちは'' AS s'.
	[
		self assert: (result first at: 's') equals: 'こんにちは'
	] ensure: [ result destroy ]
]

{ #category : 'tests - select' }
DuckDBTypeTest >> testSelectBlobReturnsByteArray [
	| result |
	result := conn execute: 'SELECT ''ab''::BLOB AS b'.
	[
		self assert: (result first at: 'b') equals: #[97 98]
	] ensure: [ result destroy ]
]

{ #category : 'tests - select' }
DuckDBTypeTest >> testSelectHexBlobReturnsByteArray [
	| result |
	result := conn execute: 'SELECT ''\xDE\xAD\xBE\xEF''::BLOB AS b'.
	[
		self assert: (result first at: 'b') equals: #[222 173 190 239]
	] ensure: [ result destroy ]
]

{ #category : 'tests - select' }
DuckDBTypeTest >> testSelectBlobRepeatedExtractionIsStable [
	"Extract the same blob many times: guards the duckdb_free memory handling."
	| result |
	result := conn execute: 'SELECT ''\xDE\xAD''::BLOB AS b'.
	[
		100 timesRepeat: [
			self assert: (result first at: 'b') equals: #[222 173] ]
	] ensure: [ result destroy ]
]

{ #category : 'tests - select' }
DuckDBTypeTest >> testSelectDecimalReturnsScaledDecimal [
	| result value |
	result := conn execute: 'SELECT 123.45::DECIMAL(5,2) AS d'.
	[
		value := result first at: 'd'.
		self assert: value class equals: ScaledDecimal.
		self assert: value equals: 123.45s2.
		self assert: value scale equals: 2
	] ensure: [ result destroy ]
]

{ #category : 'tests - select' }
DuckDBTypeTest >> testSelectNegativeDecimalReturnsScaledDecimal [
	| result |
	result := conn execute: 'SELECT (-123.45)::DECIMAL(5,2) AS d'.
	[
		self assert: (result first at: 'd') equals: -123.45s2
	] ensure: [ result destroy ]
]

{ #category : 'tests - select' }
DuckDBTypeTest >> testSelectHugeintReturnsInteger [
	| result value |
	result := conn execute:
		'SELECT 170141183460469231731687303715884105727::HUGEINT AS h'.
	[
		value := result first at: 'h'.
		self assert: value equals: 170141183460469231731687303715884105727
	] ensure: [ result destroy ]
]

{ #category : 'tests - select' }
DuckDBTypeTest >> testSelectNegativeHugeintReturnsInteger [
	| result value |
	result := conn execute:
		'SELECT (-170141183460469231731687303715884105727)::HUGEINT AS h'.
	[
		value := result first at: 'h'.
		self assert: value equals: -170141183460469231731687303715884105727
	] ensure: [ result destroy ]
]

{ #category : 'tests - select' }
DuckDBTypeTest >> testSelectDoubleReturnsFloat [
	"Regression guard: DUCKDB_TYPE_DOUBLE is 11 (the constant was off by one,
	 which made DOUBLE columns fall back to String)."
	| result value |
	result := conn execute: 'SELECT 1.5::DOUBLE AS x'.
	[
		value := result first at: 'x'.
		self assert: value isFloat.
		self assert: value equals: 1.5
	] ensure: [ result destroy ]
]

{ #category : 'tests - select' }
DuckDBTypeTest >> testSelectFloatReturnsFloat [
	"1.5 is exactly representable in float32, so equality is safe."
	| result value |
	result := conn execute: 'SELECT 1.5::FLOAT AS x'.
	[
		value := result first at: 'x'.
		self assert: value isFloat.
		self assert: value equals: 1.5
	] ensure: [ result destroy ]
]

{ #category : 'tests - select' }
DuckDBTypeTest >> testSelectNullDateReturnsNil [
	| result |
	result := conn execute: 'SELECT CAST(NULL AS DATE) AS d'.
	[
		self assert: (result first at: 'd') isNil
	] ensure: [ result destroy ]
]

{ #category : 'tests - select' }
DuckDBTypeTest >> testSelectUTinyIntReturnsInteger [
	| result |
	result := conn execute: 'SELECT 255::UTINYINT AS x'.
	[
		self assert: (result first at: 'x') equals: 255
	] ensure: [ result destroy ]
]

{ #category : 'tests - select' }
DuckDBTypeTest >> testSelectUSmallIntReturnsInteger [
	| result |
	result := conn execute: 'SELECT 65535::USMALLINT AS x'.
	[
		self assert: (result first at: 'x') equals: 65535
	] ensure: [ result destroy ]
]

{ #category : 'tests - select' }
DuckDBTypeTest >> testSelectUIntegerReturnsInteger [
	| result |
	result := conn execute: 'SELECT 4294967295::UINTEGER AS x'.
	[
		self assert: (result first at: 'x') equals: 4294967295
	] ensure: [ result destroy ]
]

{ #category : 'tests - select' }
DuckDBTypeTest >> testSelectUBigIntReturnsInteger [
	| result |
	result := conn execute: 'SELECT 18446744073709551615::UBIGINT AS x'.
	[
		self assert: (result first at: 'x') equals: 18446744073709551615
	] ensure: [ result destroy ]
]

{ #category : 'tests - select' }
DuckDBTypeTest >> testSelectUHugeintReturnsInteger [
	| result |
	result := conn execute:
		'SELECT 340282366920938463463374607431768211455::UHUGEINT AS x'.
	[
		self assert: (result first at: 'x')
			equals: 340282366920938463463374607431768211455
	] ensure: [ result destroy ]
]

{ #category : 'tests - select' }
DuckDBTypeTest >> testSelectIntervalReturnsInterval [
	| result value |
	result := conn execute: 'SELECT INTERVAL ''1 year 2 months 3 days 4 hours'' AS i'.
	[
		value := result first at: 'i'.
		self assert: value
			equals: (DuckDBInterval months: 14 days: 3 microseconds: 4 * 3600 * 1000000)
	] ensure: [ result destroy ]
]

{ #category : 'tests - select' }
DuckDBTypeTest >> testSelectMonthFreeIntervalConvertsToDuration [
	| result value |
	result := conn execute: 'SELECT INTERVAL ''3 days 4 hours'' AS i'.
	[
		value := result first at: 'i'.
		self assert: value asDuration
			equals: (Duration days: 3 hours: 4 minutes: 0 seconds: 0)
	] ensure: [ result destroy ]
]

{ #category : 'tests - select' }
DuckDBTypeTest >> testIntervalWithMonthsRefusesDurationConversion [
	self
		should: [ (DuckDBInterval months: 1 days: 0 microseconds: 0) asDuration ]
		raise: Error
]

{ #category : 'tests - chunk' }
DuckDBTypeTest >> testSelectUuidReturnsUUID [
	| result value |
	result := conn execute:
		'SELECT ''550e8400-e29b-41d4-a716-446655440000''::UUID AS u'.
	[
		value := result first at: 'u'.
		self assert: value
			equals: (UUID fromString: '550e8400-e29b-41d4-a716-446655440000')
	] ensure: [ result destroy ]
]

{ #category : 'tests - chunk' }
DuckDBTypeTest >> testSelectEnumReturnsLabelString [
	| result |
	(conn execute: 'CREATE TYPE mood AS ENUM (''sad'', ''happy'')') destroy.
	result := conn execute: 'SELECT ''happy''::mood AS m'.
	[
		self assert: (result first at: 'm') equals: 'happy'
	] ensure: [ result destroy ]
]

{ #category : 'tests - chunk' }
DuckDBTypeTest >> testSelectTimestampTzReturnsInstant [
	"TIMESTAMP_TZ stores the UTC instant; DateAndTime compares by instant,
	 so the +00 literal equals the same moment regardless of display offset."
	| result expected |
	result := conn execute: 'SELECT TIMESTAMPTZ ''2024-03-15 12:34:56+00'' AS ts'.
	[
		expected := DateAndTime
			year: 2024 month: 3 day: 15
			hour: 12 minute: 34 second: 56
			offset: Duration zero.
		self assert: (result first at: 'ts') equals: expected
	] ensure: [ result destroy ]
]

{ #category : 'tests - chunk' }
DuckDBTypeTest >> testChunkPathDecodesScalarColumnsToo [
	"When a chunk-only column (UUID) is present, every column is read via the
	 chunk API; check that ordinary scalar columns still decode correctly."
	| result row |
	result := conn execute: 'SELECT
		''550e8400-e29b-41d4-a716-446655440000''::UUID AS u,
		42::INTEGER AS i,
		DATE ''2024-03-15'' AS d,
		123.45::DECIMAL(5,2) AS dec,
		170141183460469231731687303715884105727::HUGEINT AS h,
		''hi'' AS s'.
	[
		row := result first.
		self assert: (row at: 'i') equals: 42.
		self assert: (row at: 'd') equals: (Date year: 2024 month: 3 day: 15).
		self assert: (row at: 'dec') equals: 123.45s2.
		self assert: (row at: 'h') equals: 170141183460469231731687303715884105727.
		self assert: (row at: 's') equals: 'hi'
	] ensure: [ result destroy ]
]

{ #category : 'tests - chunk' }
DuckDBTypeTest >> testChunkPathNullReturnsNil [
	| result |
	result := conn execute: 'SELECT CAST(NULL AS UUID) AS u, 7::INTEGER AS i'.
	[
		self assert: (result first at: 'u') isNil.
		self assert: (result first at: 'i') equals: 7
	] ensure: [ result destroy ]
]

{ #category : 'private' }
DuckDBTypeTest >> insertInto: tableDdl binding: aBlock [
	"Create a one-column table, bind one value via aBlock, and insert it."
	| stmt |
	(conn execute: 'CREATE TABLE t (v ' , tableDdl , ')') destroy.
	stmt := conn prepare: 'INSERT INTO t VALUES (?)'.
	[
		aBlock value: stmt.
		stmt execute destroy
	] ensure: [ stmt destroy ]
]

{ #category : 'private' }
DuckDBTypeTest >> selectInsertedValue [
	| result |
	result := conn execute: 'SELECT v FROM t'.
	^ [ result first at: 'v' ] ensure: [ result destroy ]
]

{ #category : 'tests - bind' }
DuckDBTypeTest >> testBindDateRoundtrip [
	| date |
	date := Date year: 2024 month: 3 day: 15.
	self insertInto: 'DATE' binding: [ :stmt | stmt bindDate: date at: 1 ].
	self assert: self selectInsertedValue equals: date
]

{ #category : 'tests - bind' }
DuckDBTypeTest >> testBindTimeRoundtrip [
	| time |
	time := Time hour: 12 minute: 34 second: 56.
	self insertInto: 'TIME' binding: [ :stmt | stmt bindTime: time at: 1 ].
	self assert: self selectInsertedValue equals: time
]

{ #category : 'tests - bind' }
DuckDBTypeTest >> testBindTimestampRoundtrip [
	| timestamp |
	timestamp := DateAndTime
		year: 2024 month: 3 day: 15
		hour: 12 minute: 34 second: 56
		offset: Duration zero.
	self insertInto: 'TIMESTAMP' binding: [ :stmt | stmt bindTimestamp: timestamp at: 1 ].
	self assert: self selectInsertedValue equals: timestamp
]

{ #category : 'tests - bind' }
DuckDBTypeTest >> testBindBlobRoundtrip [
	| bytes |
	bytes := #[222 173 190 239].
	self insertInto: 'BLOB' binding: [ :stmt | stmt bindBlob: bytes at: 1 ].
	self assert: self selectInsertedValue equals: bytes
]
