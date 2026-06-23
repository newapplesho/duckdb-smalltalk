"
I am the root of the DuckDB exception hierarchy.

I carry an optional `errorCode` (the duckdb_state return value).
Catch me to handle any DuckDB failure, or catch one of my subclasses
(DuckDBConnectionError, DuckDBQueryError, DuckDBBindError) for specific cases.
"
Class {
	#name : 'DuckDBError',
	#superclass : 'Error',
	#instVars : [
		'errorCode'
	],
	#classVars : [],
	#package : 'DuckDB-Core'
}

{ #category : 'instance creation' }
DuckDBError class >> signal: message code: aCode [
	^ self new
		errorCode: aCode;
		signal: message
]

{ #category : 'accessing' }
DuckDBError >> errorCode [
	^ errorCode
]

{ #category : 'accessing' }
DuckDBError >> errorCode: anInteger [
	errorCode := anInteger
]
