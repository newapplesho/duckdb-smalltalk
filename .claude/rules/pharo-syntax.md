---
paths:
  - "src/**/*.st"
---

# Pharo 13 Coding Rules

Based on [Pharo with Style](https://books.pharo.org/booklet-WithStyle/).

This file is **project-independent** — it can be copied as-is to any Pharo project
using Tonel format. Project-specific conventions (class prefix, custom protocol
names, resource cleanup pairs) live in `project-conventions.md`.

## Development Cycle

Edit `.class.st` files, reload into the Pharo image via Metacello or Iceberg, run tests.
Edits to Tonel files are **not live** until re-imported into the image.

## Method Constraints

- **15 lines maximum** per method — extract helpers when exceeded
- **100 characters maximum** per line — wrap long expressions
- **Never access instance variables directly from outside the object** — always go through accessor messages
- Every method **must** have a protocol/category — unclassified methods are a style violation

## Syntax Quick Reference

```smalltalk
"--- Returns ---"
^ value                         "not: return value"

"--- Nil ---"
nil                             "not: null"

"--- Comments ---"
"this is a comment"             "not: // or /* */"

"--- Comparison ---"
x = y                           "value equality  (not: ==)"
x == y                          "identity only"
x ~= y                          "not equal       (not: !=)"

"--- Accessors: no get/set prefix ---"
count                           "getter  (not: getCount)"
count: n                        "setter  (not: setCount:)"

"--- Conditionals ---"
x > 0 ifTrue: [ ... ].
x ifNil: [ ... ].
x ifNil: [ ... ] ifNotNil: [:v | ... ].

"--- Guard clause: early return instead of nesting ---"
handle ifNil: [ ^ ConnectionError signal: 'Not connected' ].

"--- Loops ---"
1 to: 10 do: [:i | ... ].
collection do: [:each | ... ].
collection doWithIndex: [:each :i | ... ].

"--- Collections: prefer semantic messages ---"
col isEmpty.                    "not: col size = 0"
col notEmpty.                   "not: col size > 0"
col includes: x.
col collect: [:x | x * 2 ].
col select: [:x | x > 0 ].
col detect: [:x | x > 0 ] ifNone: [ nil ].
col inject: 0 into: [:sum :x | sum + x ].

"--- yourself: return receiver after cascade ---"
^ OrderedCollection new
    add: firstItem;
    add: secondItem;
    yourself

"--- Exceptions ---"
[ risky ] on: MyError do: [:e | self handleError: e ].
[ risky ] ensure: [ resource release ].

"--- initialize: super first ---"
MyClass >> initialize [
    super initialize.
    count := 0
]

"--- Abstract method ---"
MyClass >> abstractMethod [ self subclassResponsibility ]
```

## Message Formatting

Method bodies **must** use a newline and indent — never inline on the same line as the selector.
The only exception is `self subclassResponsibility`.

```smalltalk
"--- NG: single-line body + space-aligned columns ---"
MyConstants class >> maxRetries     [ ^ 18 ]

"--- OK: body on new line, indented ---"
MyConstants class >> maxRetries [
	^ 18
]

"--- the only exception ---"
MyClass >> abstractMethod [ self subclassResponsibility ]
```

Long lines (>100 chars) must be wrapped. Rules by message type:

> **Exception**: `ffiCall:` array-literal declarations (`^ self ffiCall: #(...)`) cannot be split across lines in Pharo syntax. These may exceed 100 chars.

| Kind | Rule |
|---|---|
| Unary | One line |
| Binary | One line; parenthesize if needed |
| Keyword (1 pair) | One line if ≤100 chars |
| Keyword (multiple pairs) | One `keyword: arg` pair per line, 1 tab indent |
| Cascade (`;`) | One message per line, aligned under receiver |

```smalltalk
"--- multiple keywords: one pair per line ---"
returnCode := MyLibrary uniqueInstance
	connect: aHandle
	outConnection: slot.

"--- cascade: newline per message ---"
^ OrderedCollection new
	add: firstItem;
	add: secondItem;
	yourself.

"--- NG: single long line exceeding 100 chars ---"
typeCode = MyMapper typeBoolean ifTrue: [ ^ lib valueBoolean: aStruct col: colIdx row: rowIdx ].

"--- OK: wrap inside the block ---"
typeCode = MyMapper typeBoolean ifTrue: [
	^ lib valueBoolean: aStruct col: colIdx row: rowIdx
].

"--- condition block: one space before and after [ ---"
x > 0 ifTrue: [ self doSomething ].
result ifNil: [ ^ MyError signal: 'No result' ].
```

## Code Style Idioms

Prefer specialized messages over verbose equivalents (source: mumez/smalltalk-dev-plugin style-guide):

| Anti-pattern | Correct | Reason |
|---|---|---|
| `value isNil ifTrue: [...]` | `value ifNil: [...]` | specialized message |
| `value notNil ifTrue: [...]` | `value ifNotNil: [:v | ...]` | passes non-nil value |
| `col at: 1` | `col first` | intent is clear |
| `col at: col size` | `col last` | intent is clear |
| `MyClass new` (inside a method) | `self class new` | rename-safe, inheritance-friendly |
| `flag = true` | `flag` | redundant comparison |
| `flag = false` | `flag not` | redundant comparison |
| `^ condition ifTrue: [ true ] ifFalse: [ false ]` | `^ condition` | boolean IS the result |

Instance variable access rules:

- **Outside `initialize`**: always use accessor methods — never `ivar := value` directly
- **Inside `initialize`**: direct assignment is permitted and expected

```smalltalk
"--- OK: direct assignment in initialize ---"
initialize
	super initialize.
	count := 0.
	items := OrderedCollection new.

"--- NG: direct assignment outside initialize ---"
increment
	count := count + 1.   "NG"

"--- OK: via accessor ---"
increment
	self count: self count + 1.
```

## Naming Conventions

| Kind            | Rule                                            | Example                |
|-----------------|-------------------------------------------------|------------------------|
| Class           | UpperCamelCase + project prefix (see `project-conventions.md`) | `MyLibConnection` |
| Action method   | lowerCamelCase verb                             | `execute:`, `disconnect` |
| Getter          | noun only (no `get`)                            | `rowCount`, `handle`   |
| Setter          | noun + `:` (no `set`)                           | `rowCount:`, `handle:` |
| Predicate       | `is` + adjective                                | `isOpen`, `isEmpty`    |
| Instance var    | lowerCamelCase, no underscores                  | `resultStruct`         |
| Class var       | UpperCamelCase                                  | `Default`, `Instance`  |

## Protocol Names (standard set)

```
'instance creation'    class-side factory methods
'initialization'       initialize
'accessing'            getters and setters
'actions'              execute:, connect, destroy, etc.
'testing'              isOpen, isEmpty, isConnected, etc.
'private'              internal helpers
'printing'             printOn:
'error handling'       error signaling helpers
'converting'           asDictionary, asArray, etc.
'enumerating'          do:, collect:, select:, etc.
```

Project-specific protocols (e.g. for FFI binding classes) are defined in
`project-conventions.md`.

## Class Comment Convention (first-person "I")

Every class must have a class comment. In Tonel format it is a quoted string
placed immediately before the `Class { ... }` definition.

```smalltalk
"I represent an open connection to a database.

 I execute SQL queries and create prepared statements.
 Always call disconnect when done, or use a with*-style method for automatic cleanup.

 Example:
   conn := MyDatabase openMemory connect.
   result := conn execute: 'SELECT 42 AS n'.
   conn disconnect.
"
```

## Tonel File Layout

Each package is a directory under `src/`. The directory name **must match** the package name exactly.

```
src/
  .properties                ← Tonel repository marker (REQUIRED for CI)
  BaselineOfMyProject/       ← directory name = package name
    package.st               ← Package { #name : 'BaselineOfMyProject' }
    BaselineOfMyProject.class.st
  MyProject-Core/
    package.st               ← Package { #name : 'MyProject-Core' }
    MyProjectConnection.class.st
    ...
```

**`src/.properties` is required.** Without it, smalltalkCI assumes MCFileTree format, causing `NotFound: BaselineOfMyProject` in CI. Locally the explicit `tonel://` prefix hides the problem, so the failure only surfaces in CI and is easy to miss.

```ston
{
	#format : #tonel
}
```

## Metacello Baseline Convention

**CRITICAL:** The baseline package must be named `BaselineOf<ProjectName>`, NOT `<ProjectName>-Baseline`.

| Wrong | Correct |
|-------|---------|
| Package `MyProject-Baseline` | Package `BaselineOfMyProject` |
| Directory `src/MyProject-Baseline/` | Directory `src/BaselineOfMyProject/` |

When Metacello runs `baseline: 'MyProject'`, it looks for a package literally named `BaselineOfMyProject` in the Tonel repository. Any other name causes `NotFound: BaselineOfMyProject`.

```smalltalk
"Correct: class and package both named BaselineOfMyProject"
Class {
    #name : 'BaselineOfMyProject',
    #superclass : 'BaselineOf',
    #package : 'BaselineOfMyProject'    "must match directory and package.st"
}
```

## Do NOT Generate

- `return`, `null`, `//`, `!=`, `getX`, `setX:`
- Direct instance variable access from outside the owning class
- Methods longer than 15 lines
- Lines longer than 100 characters
- Methods without a protocol/category
- `^` inside blocks (causes non-local return — exits the enclosing method)
- 1-line method bodies with space-padding alignment: `method  [ ^ val ]`
- `isNil ifTrue: [...]` — use `ifNil: [...]`
- `notNil ifTrue: [...]` — use `ifNotNil: [:v | ...]`
- `col at: 1` — use `col first`; `col at: col size` — use `col last`
- `ClassName new` inside a method body — use `self class new`
- `flag = true` or `flag = false` — use `flag` or `flag not`
- `someVar := nil` inside `initialize` — instance variables are already `nil` by the VM; only set non-nil default values in `initialize`
