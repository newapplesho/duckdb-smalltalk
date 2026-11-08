"
I am the Metacello baseline of DuckDB Smalltalk.

I declare the packages DuckDB-FFI, DuckDB-Core and DuckDB-Tests and the order in which
Metacello loads them. The 'default' group loads DuckDB-Core and DuckDB-FFI, which
DuckDB-Core requires. The 'tests' group loads DuckDB-Tests, and the 'all' group loads both.
"
Class {
	#name : 'BaselineOfDuckDB',
	#superclass : 'BaselineOf',
	#instVars : [],
	#classVars : [],
	#package : 'BaselineOfDuckDB'
}

{ #category : 'baselines' }
BaselineOfDuckDB >> baseline: spec [
	<baseline>
	spec for: #common do: [
		spec
			package: 'DuckDB-FFI';
			package: 'DuckDB-Core' with: [ spec requires: #('DuckDB-FFI') ];
			package: 'DuckDB-Tests' with: [ spec requires: #('DuckDB-Core') ].

		spec
			group: 'default' with: #('DuckDB-Core');
			group: 'tests'   with: #('DuckDB-Tests');
			group: 'all'     with: #('DuckDB-Core' 'DuckDB-Tests')
	]
]
