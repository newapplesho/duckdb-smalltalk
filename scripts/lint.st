"This script runs Pharo's lint rules (Renraku: the critiques that the System Browser shows
 below the code) on the classes of this project and prints one line per finding.
 Run it from the repository root with: make lint
 The script checks BaselineOf<project> and every package whose name starts with <project>,
 where project is the baseline name.

 The ignored dictionary below lists the findings that this project accepts on purpose, each
 with its reason. Each key is one finding line exactly as the script prints it
 ('<class or method> | <rule name>'). Ignoring one finding therefore does not hide the same
 rule on other classes or methods. The script exits with status 1 when a finding that is not
 in ignored remains.
 The rules check the code loaded in the image, not the files in src/, so run make load first.
 This script is adapted from scripts/lint.st in newapplesho/pharo-metacello-pin."

| project ignored packages findings skipped out |
project := 'DuckDB'.
ignored := Dictionary newFrom: {
	'BaselineOfDuckDB | Class not referenced'
		-> 'Metacello looks up the baseline class by name, so no code refers to it.'.
	'DuckDBBlobStruct | Class not referenced'
		-> ('Only the ffiCall: literal array of duckdb_value_blob refers to this class, '
			, 'and the rule does not count references inside literal arrays.').
	'DuckDBIntervalStruct | Class not referenced'
		-> ('Only the ffiCall: literal array of duckdb_value_interval refers to this class, '
			, 'and the rule does not count references inside literal arrays.').
	'DuckDBLibrary | Excessive number of methods'
		-> 'DuckDBLibrary defines one method for each C function that it binds.'.
	'DuckDBTypeMapper>>#numericConversionSelectorFor: | Long methods'
		-> 'The method compares the type code with each DUCKDB_TYPE value in turn.'.
	'DuckDBTypeMapper>>#numericConversionSelectorFor: | The cyclomatic complexity is high'
		-> 'The method compares the type code with each DUCKDB_TYPE value in turn.'.
	'DuckDBVectorReader>>#numericDecodeSelectorFor: | Long methods'
		-> 'The method compares the type code with each DUCKDB_TYPE value in turn.'.
	'DuckDBVectorReader>>#numericDecodeSelectorFor: | The cyclomatic complexity is high'
		-> 'The method compares the type code with each DUCKDB_TYPE value in turn.'.
	'DuckDBVectorReader>>#temporalDecodeSelectorFor: | Long methods'
		-> 'The method compares the type code with each DUCKDB_TYPE value in turn.' }.

packages := (PackageOrganizer default packages
	select: [ :each | each name beginsWith: project ]) asOrderedCollection.
packages add: (PackageOrganizer default packageNamed: 'BaselineOf' , project).

findings := OrderedCollection new.
skipped := 0.
packages do: [ :package |
	package definedClasses do: [ :class |
		({ class } , class methods , class class methods) do: [ :entity |
			(ReCriticEngine critiquesOf: entity) do: [ :critique |
				| line |
				line := entity printString , ' | ' , critique rule name.
				(ignored includesKey: line)
					ifTrue: [ skipped := skipped + 1 ]
					ifFalse: [ findings add: line ] ] ] ] ].

out := Stdio stdout.
findings do: [ :each | out nextPutAll: each; lf ].
out
	nextPutAll: findings size printString , ' finding(s). ';
	nextPutAll: skipped printString , ' more finding(s) skipped because ignored in ';
	nextPutAll: 'scripts/lint.st lists them.';
	lf;
	flush.
Smalltalk exit: (findings isEmpty ifTrue: [ 0 ] ifFalse: [ 1 ])
