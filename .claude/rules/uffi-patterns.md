---
paths:
  - "src/*-FFI/**/*.st"
  - "src/*-Core/**/*.st"
---

# UFFI Patterns

This file is **project-independent**: the patterns apply to any Pharo project that
wraps a C library via UFFI. Code snippets use DuckDB as the worked example — when
copying this file to another project, the snippets remain valid as illustrations.
Project-specific facts (which handle classes exist, which open/close pairs apply)
live in `project-conventions.md`.

## ffiCall: Syntax

```smalltalk
{ #category : 'ffi - lifecycle' }
DuckDBLibrary >> duckdbOpen: path outDatabase: db [
    ^ self ffiCall: #(int duckdb_open(String path, DuckDBHandle* db))
]
```

Rules:
- One method = one C function. No logic inside `ffiCall:` methods.
- The FFI package contains **only** `ffiCall:` declarations, handle classes, and
  struct definitions — all logic belongs in the Core package.
- Group declarations into `'ffi - <area>'` protocols (see `project-conventions.md`
  for this project's protocol set).

## Type Mapping

| C type (role)                                      | ffiCall: declaration                          |
|----------------------------------------------------|-----------------------------------------------|
| `int` / enum return codes                          | `int`                                         |
| `uint64_t`                                         | `uint64`                                      |
| `int32_t`                                          | `int32`                                       |
| `int64_t`                                          | `int64`                                       |
| `double`                                           | `double`                                      |
| `bool`                                             | `bool`                                        |
| `const char*`                                      | `String`                                      |
| `void`                                             | `void`                                        |
| opaque handle (`typedef void*`), by-value or output | `<YourHandleClass>*`                          |
| struct output parameter                            | `ExternalAddress*` (allocated with `allocate:`) |

## Handle Class Design

C opaque handle types declared as `typedef void*` are raw pointers, not structs.

Handle classes must subclass **`ExternalAddress`**, not `FFIOpaqueObject`.
Using `FFIOpaqueObject` (designed for struct-like data) produces heap corruption on Linux.

```smalltalk
Class {
    #name : 'DuckDBHandle',
    #superclass : 'ExternalAddress',
    #type : 'bytes',
    #instVars : [],
    #package : 'DuckDB-FFI'
}
```

### `#type: 'bytes'` is required

`ExternalAddress` subclasses must declare `#type: 'bytes'`. Without it, Pharo cannot load the class definition correctly.

### `asExternalTypeOn:` must be defined on ExternalAddress subclasses

The `FFICallout` class comment (`src/UnifiedFFI/FFICallout.class.st` in `pharo-project/pharo`) states:

```
"Callout arguments can be either:
 - an integer constant, boolean or nil
 - a type name (string or symbol)
 - a class name
 - a class variable
 - any other object, which responds to #asExternalTypeOn:"
```

`FFICallout >> initializeTypeAliases` registers built-in aliases, including:

```smalltalk
ExternalAddress  FFIOop
```

`ExternalAddress` itself resolves via this alias and does not need `asExternalTypeOn:`.
Its subclasses are not in the alias table, so they must define the method.

`ExternalAddress` is a `ByteArray` subclass — the VM passes its underlying C heap address directly, which is exactly what `FFIOop` (ordinary object pointer) does. Return `FFIOop new`:

```smalltalk
{ #category : 'accessing' }
DuckDBHandle class >> asExternalTypeOn: aGenerator [
    ^ FFIOop new
]
```

Define the same method on **every** `ExternalAddress` subclass used in `ffiCall:` declarations.

## allocate: 8 and pointerAt: 1 Pattern

For output parameters where C writes a handle pointer into memory, allocate an 8-byte slot.

```smalltalk
"Output param: allocate an 8-byte slot and pass it"
slot := DuckDBHandle allocate: 8.
lib duckdbOpen: path outDatabase: slot.
"The C function writes the handle pointer into slot's 8 bytes"
handle := slot.

"By-value param: extract the stored pointer from the slot"
handle pointerAt: 1   "=> ExternalAddress whose getHandle = the handle value"
```

Passing the `ExternalAddress` returned by `pointerAt: 1` to a `<Handle>*` declaration
works correctly — UFFI calls `getHandle` on whatever object is passed (duck typing).

For close/destroy functions taking `handle *`, pass the slot itself:

```smalltalk
lib duckdbClose: handle.   "handle = slot (DuckDBHandle allocate: 8)"
handle free.
```

## Structs vs Opaque Handles

A C type with **defined fields** (a struct) is not an opaque pointer handle.
Allocate it with `ExternalAddress allocate: <StructClass> byteSize`.
Free it explicitly with `free` after calling the C-side destroy function.

## Memory Ownership

Every C-side resource must have exactly one Smalltalk class responsible for
releasing it, and the open/close pair must be documented. List the concrete
pairs for this project in `project-conventions.md`.

Always pair acquisition with `ensure:`:
```smalltalk
[doWork] ensure: [result destroy]
```

Do **not** rely on `autoRelease` / finalization — the GC gives no timing guarantee,
and C-side resources (open files, connections) must be released deterministically.

## FFIExternalStructure (C struct — field order must match C exactly)

```smalltalk
DuckDBResultStruct class >> fieldsDesc [
    ^ #(
        uint64  deprecated_column_count
        uint64  deprecated_row_count
        void*   deprecated_columns
        void*   deprecated_error_message
        void*   internal_data
    )
]
```

> **WARNING:** Use `void*` for pointer-typed fields. The token `pointer` is **not** a valid UFFI
> type name and raises `Unable to resolve external type: pointer` at runtime.
> This applies regardless of Pharo version — `void*` is always the correct form.

Never read/write fields directly. Use public API functions only.

## Structs Passed and Returned BY VALUE

Verified working on Pharo 12/13 (macOS arm64 and Linux x64 CI): an
`FFIExternalStructure` subclass can be used directly as a **return type** and as a
**parameter type** in `ffiCall:` declarations — UFFI/libffi handles the by-value
calling convention, including 16-byte structs.

```smalltalk
"Return by value: duckdb_date duckdb_value_date(duckdb_result*, idx_t, idx_t)"
DuckDBLibrary >> duckdbValueDate: result col: colIdx row: rowIdx [
    ^ self ffiCall: #(DuckDBDateStruct duckdb_value_date(ExternalAddress* result, uint64 colIdx, uint64 rowIdx))
]

"Pass by value: duckdb_state duckdb_bind_date(duckdb_prepared_statement, idx_t, duckdb_date)"
DuckDBLibrary >> duckdbBindDate: stmt paramIdx: idx val: aDateStruct [
    ^ self ffiCall: #(int duckdb_bind_date(DuckDBPreparedHandle* stmt, uint64 idx, DuckDBDateStruct aDateStruct))
]
```

- A by-value **return** allocates a fresh Smalltalk-owned copy — no `free` needed
  for the struct itself (pointer fields inside it may still need freeing; see below).
- For **passing**, create an instance with `new` and set its fields; the callee
  receives a copy.
- Field accessors can be written manually against fixed offsets instead of running
  `rebuildFieldAccessors` (avoids generated `OFFSET_*` class variables in Tonel):

```smalltalk
DuckDBDateStruct class >> fieldsDesc [
    ^ #( int32 days )
]
DuckDBDateStruct >> days [
    ^ handle signedLongAt: 1
]
"int64 field: signedLongLongAt: 1.  void* field: pointerAt: 1.
 uint64 field after a void*: unsignedLongLongAt: 9 (offsets are 1-based bytes)."
```

## Caller-Owned C Buffers (malloc'ed returns)

When a C function returns a **malloc'ed buffer the caller must free**
(e.g. `duckdb_value_varchar` returns `char*` to be freed with `duckdb_free`),
do NOT declare the return as `String`: UFFI copies the text but the original
pointer is lost and the C buffer **leaks**. Declare `void*`, read, then free:

```smalltalk
"FFI layer: keep the pointer accessible"
DuckDBLibrary >> duckdbValueVarchar: result col: colIdx row: rowIdx [
    ^ self ffiCall: #(void* duckdb_value_varchar(ExternalAddress* result, uint64 colIdx, uint64 rowIdx))
]
DuckDBLibrary >> duckdbFree: pointer [
    ^ self ffiCall: #(void duckdb_free(void* pointer))
]

"Core layer: read as UTF-8, free in ensure:"
pointer := lib duckdbValueVarchar: resultStruct col: colIdx row: rowIdx.
pointer isNull ifTrue: [ ^ nil ].
^ [ pointer readStringUTF8 ] ensure: [ lib duckdbFree: pointer ]
```

`String` returns are only correct for `const char*` results owned by the library
(e.g. `duckdb_result_error`, `duckdb_column_name`) — check the header's ownership
comments for every string-returning function.

## Platform-Specific Library Name

**CRITICAL:** These are **instance-side** methods, NOT class-side. Pharo's UFFI calls `macLibraryName`, `unixLibraryName`, `win32LibraryName` on the library instance.
Defining `class >> ffiLibraryName` does nothing and raises `subclassResponsibility` errors at runtime.

```smalltalk
"Correct: instance-side, absolute path via FileLocator (bypasses macOS SIP)"
DuckDBLibrary >> macLibraryName [
    ^ (FileLocator imageDirectory parent / 'lib' / 'libduckdb.dylib') pathString
]
DuckDBLibrary >> unixLibraryName [
    ^ (FileLocator imageDirectory parent / 'lib' / 'libduckdb.so') pathString
]
DuckDBLibrary >> win32LibraryName [ ^ 'duckdb.dll' ]

"Wrong: class-side ffiLibraryName is never called by UFFI"
DuckDBLibrary class >> ffiLibraryName [ ... ]
```

On macOS, `DYLD_LIBRARY_PATH` is stripped by SIP for GUI processes. Always use `FileLocator` to build an absolute path — do not rely on environment variables for library loading.
Providing an environment-variable override (e.g. `DUCKDB_LIB_PATH`) **in addition to**
the FileLocator default is good practice for CI and non-standard installs.
