"
I represent a DuckDB INTERVAL value exactly, as its three independent
components: months, days and microseconds.

Months vary in length, so an INTERVAL cannot generally be reduced to a fixed
Duration without losing meaning. Use `asDuration` when months is zero;
it signals an error otherwise.

Example:
	interval := DuckDBInterval months: 14 days: 3 microseconds: 0.
	interval months.     ""14""
	interval asDuration. ""error: has months""
"
Class {
	#name : 'DuckDBInterval',
	#superclass : 'Object',
	#instVars : [
		'months',
		'days',
		'microseconds'
	],
	#classVars : [],
	#package : 'DuckDB-Core'
}

{ #category : 'instance creation' }
DuckDBInterval class >> months: monthCount days: dayCount microseconds: microCount [
	^ self new
		initializeMonths: monthCount days: dayCount microseconds: microCount;
		yourself
]

{ #category : 'private' }
DuckDBInterval >> initializeMonths: monthCount days: dayCount microseconds: microCount [
	months := monthCount.
	days := dayCount.
	microseconds := microCount
]

{ #category : 'accessing' }
DuckDBInterval >> months [
	^ months
]

{ #category : 'accessing' }
DuckDBInterval >> days [
	^ days
]

{ #category : 'accessing' }
DuckDBInterval >> microseconds [
	^ microseconds
]

{ #category : 'converting' }
DuckDBInterval >> asDuration [
	"Only month-free intervals convert exactly: months vary in length."
	months = 0
		ifFalse: [ ^ self error: 'Interval with months cannot be converted to an exact Duration' ].
	^ (Duration days: days) + (Duration nanoSeconds: microseconds * 1000)
]

{ #category : 'comparing' }
DuckDBInterval >> = anObject [
	self == anObject ifTrue: [ ^ true ].
	(anObject isKindOf: DuckDBInterval) ifFalse: [ ^ false ].
	^ months = anObject months
		and: [ days = anObject days
		and: [ microseconds = anObject microseconds ] ]
]

{ #category : 'comparing' }
DuckDBInterval >> hash [
	^ (months hash bitXor: days hash) bitXor: microseconds hash
]

{ #category : 'printing' }
DuckDBInterval >> printOn: aStream [
	aStream
		nextPutAll: 'DuckDBInterval(';
		print: months;
		nextPutAll: ' months ';
		print: days;
		nextPutAll: ' days ';
		print: microseconds;
		nextPutAll: ' micros)'
]
