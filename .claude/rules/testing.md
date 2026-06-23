---
paths:
  - "src/*-Tests/**/*.st"
---

# Testing Conventions

This file is **project-independent** — it can be copied as-is to any Pharo project.
Project-specific test fixtures are described in `project-conventions.md`.

## setUp / tearDown

Acquire shared resources in `setUp`, release them defensively in `tearDown`
(guard with a predicate so a failed setUp does not cascade):

```smalltalk
MyConnectionTest >> setUp [
    super setUp.
    db   := MyDatabase openMemory.
    conn := db connect.
]

MyConnectionTest >> tearDown [
    conn isConnected ifTrue: [ conn disconnect ].
    db isOpen        ifTrue: [ db close ].
    super tearDown.
]
```

- Tests must be independent — no shared state across test methods.
- Use in-memory / temporary resources, never touch real files or networks.

## Test Method Naming

`test` + what is tested + expected outcome.

```
testExecuteSelectIntegerReturnsCorrectValue
testInvalidSQLSignalsQueryError
testOpenMemoryDatabaseSucceeds
```

## Assertions

```smalltalk
self assert: x equals: y.          "prefer over assert: (x = y)"
self assert: x.
self deny: x.
self assert: x isNil.
self assert: x class equals: Integer.
self should: [ conn execute: 'BAD' ] raise: MyQueryError.
```

Prefer `assert:equals:` over `assert: (x = y)` — gives better failure messages.

## Always Release Resources in ensure:

Any object that owns a C-side or external resource must be released inside an
`ensure:` block so cleanup runs even when an assertion fails:

```smalltalk
MyConnectionTest >> testSomething [
    | result |
    result := conn execute: 'SELECT 1 AS n'.
    [
        self assert: (result first at: 'n') equals: 1.
    ] ensure: [ result destroy ]
]
```
