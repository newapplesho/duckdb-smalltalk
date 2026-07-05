Class {
	#name : 'DuckDBConnectionTest',
	#superclass : 'TestCase',
	#instVars : [
		'db',
		'conn'
	],
	#classVars : [],
	#package : 'DuckDB-Tests'
}

{ #category : 'running' }
DuckDBConnectionTest >> setUp [
	db   := DuckDB openMemory.
	conn := db connect.
]

{ #category : 'running' }
DuckDBConnectionTest >> tearDown [
	conn ifNotNil: [ conn isConnected ifTrue: [ conn disconnect ] ].
	db ifNotNil: [ db isOpen ifTrue: [ db close ] ].
]

{ #category : 'tests - phase 1: library' }
DuckDBConnectionTest >> testLibraryVersion [
	"Phase 1: Confirm libduckdb is loadable and returns a version string."
	| version |
	version := DuckDBLibrary uniqueInstance duckdbLibraryVersion.
	self assert: (version isNil not).
	self assert: (version isKindOf: String).
	self assert: version isNotEmpty.
]

{ #category : 'tests - phase 1: library' }
DuckDBConnectionTest >> testOpenAndCloseMemoryDatabase [
	"Phase 1: Open and close an in-memory database without error."
	| testDb |
	testDb := DuckDB openMemory.
	self assert: testDb isOpen.
	testDb close.
	self deny: testDb isOpen.
]

{ #category : 'tests - phase 1: library' }
DuckDBConnectionTest >> testConnectAndDisconnect [
	"Phase 1: Connect to and disconnect from an in-memory database."
	self assert: conn isConnected.
	conn disconnect.
	self deny: conn isConnected.
]

{ #category : 'tests - phase 2: basic queries' }
DuckDBConnectionTest >> testExecuteSelectInteger [
	"Phase 2: SELECT an integer literal and verify the returned value."
	| result row |
	result := conn execute: 'SELECT 42 AS n'.
	[
		self assert: result rowCount equals: 1.
		self assert: result columnCount equals: 1.
		row := result first.
		self assert: (row at: 'n') equals: 42.
	] ensure: [ result destroy ].
]

{ #category : 'tests - phase 2: basic queries' }
DuckDBConnectionTest >> testExecuteSelectString [
	"Phase 2: SELECT a string literal."
	| result |
	result := conn execute: 'SELECT ''hello'' AS s'.
	[
		self assert: (result first at: 's') equals: 'hello'.
	] ensure: [ result destroy ].
]

{ #category : 'tests - phase 2: basic queries' }
DuckDBConnectionTest >> testExecuteSelectNull [
	"Phase 2: NULL values must map to nil."
	| result |
	result := conn execute: 'SELECT NULL AS n'.
	[
		self assert: (result first at: 'n') isNil.
	] ensure: [ result destroy ].
]

{ #category : 'tests - phase 2: basic queries' }
DuckDBConnectionTest >> testExecuteSelectMultipleRows [
	"Phase 2: Multiple rows are enumerated correctly."
	| result count |
	result := conn execute: 'SELECT * FROM range(5) t(n)'.
	[
		count := 0.
		result do: [:row | count := count + 1].
		self assert: count equals: 5.
	] ensure: [ result destroy ].
]

{ #category : 'tests - phase 2: basic queries' }
DuckDBConnectionTest >> testExecuteSelectColumnNames [
	"Phase 2: Column names are read correctly."
	| result |
	result := conn execute: 'SELECT 1 AS a, 2 AS b, 3 AS c'.
	[
		self assert: result columnNames equals: #('a' 'b' 'c').
	] ensure: [ result destroy ].
]

{ #category : 'tests - phase 2: error handling' }
DuckDBConnectionTest >> testInvalidSQLSignalsError [
	"Phase 2: A syntax error in SQL must signal DuckDBQueryError."
	self
		should: [ conn execute: 'SELCT * FROM nowhere' ]
		raise: DuckDBQueryError.
]

{ #category : 'tests - phase 2: basic queries' }
DuckDBConnectionTest >> testResultCollect [
	"Phase 2: collect: on DuckDBResult returns an OrderedCollection."
	| result values |
	result := conn execute: 'SELECT * FROM range(3) t(n)'.
	[
		values := result collect: [:row | row at: 'n'].
		self assert: values size equals: 3.
	] ensure: [ result destroy ].
]

{ #category : 'tests - phase 3: prepared statements' }
DuckDBConnectionTest >> testPreparedStatementInsertAndSelect [
	| statement result |
	(conn execute: 'CREATE TABLE events (name VARCHAR, count BIGINT)') destroy.
	statement := conn prepare: 'INSERT INTO events VALUES (?, ?)'.
	[
		statement
			bindString: 'click' at: 1;
			bindInteger: 1 at: 2;
			yourself.
		(statement execute) destroy.
	] ensure: [ statement destroy ].
	result := conn execute: 'SELECT name, count FROM events'.
	[
		self assert: result rowCount equals: 1.
		self assert: (result first at: 'name') equals: 'click'.
		self assert: (result first at: 'count') equals: 1.
	] ensure: [ result destroy ].
]

{ #category : 'tests - phase 3: prepared statements' }
DuckDBConnectionTest >> testPreparedStatementBindNull [
	| statement result |
	(conn execute: 'CREATE TABLE items (name VARCHAR, note VARCHAR)') destroy.
	statement := conn prepare: 'INSERT INTO items VALUES (?, ?)'.
	[
		statement
			bindString: 'box' at: 1;
			bindNull: 2;
			yourself.
		(statement execute) destroy.
	] ensure: [ statement destroy ].
	result := conn execute: 'SELECT note FROM items WHERE name = ''box'''.
	[
		self assert: result rowCount equals: 1.
		self assert: (result first at: 'note') isNil.
	] ensure: [ result destroy ].
]

{ #category : 'tests - phase 3: prepared statements' }
DuckDBConnectionTest >> testPreparedStatementReuse [
	| statement result |
	(conn execute: 'CREATE TABLE metrics (name VARCHAR, value BIGINT)') destroy.
	statement := conn prepare: 'INSERT INTO metrics VALUES (?, ?)'.
	[
		statement
			bindString: 'alpha' at: 1;
			bindInteger: 10 at: 2;
			yourself.
		(statement execute) destroy.
		statement
			bindString: 'beta' at: 1;
			bindInteger: 20 at: 2;
			yourself.
		(statement execute) destroy.
	] ensure: [ statement destroy ].
	result := conn execute: 'SELECT value FROM metrics ORDER BY name'.
	[
		self assert: (result collect: [:row | row at: 'value']) equals: #(10 20) asOrderedCollection.
	] ensure: [ result destroy ].
]

{ #category : 'tests - phase 3: prepared statements' }
DuckDBConnectionTest >> testGenericBindInsertAndSelect [
	| statement result |
	(conn execute: 'CREATE TABLE events (name VARCHAR, count BIGINT)') destroy.
	statement := conn prepare: 'INSERT INTO events VALUES (?, ?)'.
	[
		statement
			bind: 'click' at: 1;
			bind: 1 at: 2;
			yourself.
		statement execute destroy.
	] ensure: [ statement destroy ].
	result := conn execute: 'SELECT name, count FROM events'.
	[
		self assert: result rowCount equals: 1.
		self assert: (result first at: 'name') equals: 'click'.
		self assert: (result first at: 'count') equals: 1.
	] ensure: [ result destroy ]
]

{ #category : 'tests - phase 3: prepared statements' }
DuckDBConnectionTest >> testGenericBindNull [
	| statement result |
	(conn execute: 'CREATE TABLE items (name VARCHAR, note VARCHAR)') destroy.
	statement := conn prepare: 'INSERT INTO items VALUES (?, ?)'.
	[
		statement
			bind: 'box' at: 1;
			bind: nil at: 2;
			yourself.
		statement execute destroy.
	] ensure: [ statement destroy ].
	result := conn execute: 'SELECT note FROM items WHERE name = ''box'''.
	[
		self assert: result rowCount equals: 1.
		self assert: (result first at: 'note') isNil.
	] ensure: [ result destroy ]
]

{ #category : 'tests - phase 3: prepared statements' }
DuckDBConnectionTest >> testExecuteWith [
	| statement result |
	(conn execute: 'CREATE TABLE events (name VARCHAR, count BIGINT)') destroy.
	statement := conn prepare: 'INSERT INTO events VALUES (?, ?)'.
	[
		statement executeWith: #('click' 1).
	] ensure: [ statement destroy ].
	result := conn execute: 'SELECT name, count FROM events'.
	[
		self assert: (result first at: 'name') equals: 'click'.
		self assert: (result first at: 'count') equals: 1.
	] ensure: [ result destroy ]
]

{ #category : 'tests - phase 3: prepared statements' }
DuckDBConnectionTest >> testExecuteWithParameters [
	| result |
	(conn execute: 'CREATE TABLE events (name VARCHAR, count BIGINT)') destroy.
	(conn execute: 'INSERT INTO events VALUES (?, ?)' with: #('click' 1)) destroy.
	result := conn execute: 'SELECT name, count FROM events'.
	[
		self assert: (result first at: 'name') equals: 'click'.
		self assert: (result first at: 'count') equals: 1.
	] ensure: [ result destroy ]
]

{ #category : 'tests - phase 3: prepared statements' }
DuckDBConnectionTest >> testExecuteWithReuse [
	| result |
	(conn execute: 'CREATE TABLE metrics (name VARCHAR, value BIGINT)') destroy.
	(conn
		execute: 'INSERT INTO metrics VALUES (?, ?)'
		with: #('alpha' 10)) destroy.
	(conn
		execute: 'INSERT INTO metrics VALUES (?, ?)'
		with: #('beta' 20)) destroy.
	result := conn execute: 'SELECT value FROM metrics ORDER BY name'.
	[
		self assert: (result collect: [:row | row at: 'value'])
			equals: #(10 20) asOrderedCollection.
	] ensure: [ result destroy ]
]

{ #category : 'tests - phase 4: csv reading' }
DuckDBConnectionTest >> testReadCsvAutoReturnsColumnNames [
	"Phase 4: read_csv_auto infers column names from the header row of a CSV file."
	| csvFile result |
	csvFile := FileLocator temp / 'duckdb_test_cols.csv'.
	csvFile writeStreamDo: [:s |
		s nextPutAll: 'name,age'; nextPut: Character lf.
		s nextPutAll: 'alice,30'; nextPut: Character lf].
	[
		result := conn execute:
			'SELECT * FROM read_csv_auto(''' , csvFile pathString , ''')'.
		[
			self assert: result columnNames equals: #('name' 'age').
		] ensure: [ result destroy ].
	] ensure: [ csvFile delete ]
]

{ #category : 'tests - phase 4: csv reading' }
DuckDBConnectionTest >> testReadCsvAutoReturnsRowValues [
	"Phase 4: read_csv_auto reads row data and maps column values correctly."
	| csvFile result row |
	csvFile := FileLocator temp / 'duckdb_test_vals.csv'.
	csvFile writeStreamDo: [:s |
		s nextPutAll: 'id,label'; nextPut: Character lf.
		s nextPutAll: '1,hello'; nextPut: Character lf].
	[
		result := conn execute:
			'SELECT * FROM read_csv_auto(''' , csvFile pathString , ''')'.
		[
			self assert: result rowCount equals: 1.
			row := result first.
			self assert: (row at: 'label') equals: 'hello'.
		] ensure: [ result destroy ].
	] ensure: [ csvFile delete ]
]

{ #category : 'tests - phase 4: csv reading' }
DuckDBConnectionTest >> testImportCsvIntoTable [
	"Phase 4: CSV data can be imported into an in-memory table via CREATE TABLE AS SELECT.
	 After import, the table can be queried without the original CSV file."
	| csvFile result |
	csvFile := FileLocator temp / 'duckdb_test_import.csv'.
	csvFile writeStreamDo: [:s |
		s nextPutAll: 'product,price'; nextPut: Character lf.
		s nextPutAll: 'apple,150'; nextPut: Character lf.
		s nextPutAll: 'banana,80'; nextPut: Character lf].
	[
		(conn execute: 'CREATE TABLE products AS SELECT * FROM read_csv_auto('''
			, csvFile pathString , ''')') destroy.
		result := conn execute: 'SELECT COUNT(*) AS cnt FROM products'.
		[
			self assert: (result first at: 'cnt') equals: 2.
		] ensure: [ result destroy ].
		(conn execute: 'DROP TABLE products') destroy.
	] ensure: [ csvFile delete ]
]

{ #category : 'tests - phase 4: csv reading' }
DuckDBConnectionTest >> testImportCsvAndAggregate [
	"Phase 4: Aggregate queries (SUM, GROUP BY) work correctly on an imported CSV table."
	| csvFile result |
	csvFile := FileLocator temp / 'duckdb_test_agg.csv'.
	csvFile writeStreamDo: [:s |
		s nextPutAll: 'category,amount'; nextPut: Character lf.
		s nextPutAll: 'food,100'; nextPut: Character lf.
		s nextPutAll: 'food,200'; nextPut: Character lf.
		s nextPutAll: 'drink,50'; nextPut: Character lf].
	[
		(conn execute: 'CREATE TABLE sales AS SELECT * FROM read_csv_auto('''
			, csvFile pathString , ''')') destroy.
		result := conn execute:
			'SELECT category, SUM(amount) AS total FROM sales GROUP BY category ORDER BY category'.
		[
			self assert: result rowCount equals: 2.
			self assert: (result first at: 'category') equals: 'drink'.
		] ensure: [ result destroy ].
		(conn execute: 'DROP TABLE sales') destroy.
	] ensure: [ csvFile delete ]
]
