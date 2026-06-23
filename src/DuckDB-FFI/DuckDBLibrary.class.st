"
I am the UFFI bridge to libduckdb (the DuckDB C API).

Every method is a single ffiCall: declaration mirroring one C function — no logic here.
I resolve the library path per platform (instance-side *LibraryName methods),
honoring the DUCKDB_LIB_PATH environment variable override.
Use me through `DuckDBLibrary uniqueInstance`; user code should go through
the DuckDB-Core classes instead of calling me directly.
"
Class {
	#name : 'DuckDBLibrary',
	#superclass : 'FFILibrary',
	#instVars : [],
	#classVars : [],
	#package : 'DuckDB-FFI'
}

{ #category : 'accessing' }
DuckDBLibrary >> macLibraryName [
	"Absolute path bypasses macOS SIP restriction (DYLD_LIBRARY_PATH is ignored by SIP).
	 DUCKDB_LIB_PATH overrides the default path (CI / non-standard installs)."
	Smalltalk os environment at: 'DUCKDB_LIB_PATH' ifPresent: [ :path | ^ path ].
	^ (FileLocator imageDirectory parent / 'lib' / 'libduckdb.dylib') pathString
]

{ #category : 'accessing' }
DuckDBLibrary >> unixLibraryName [
	Smalltalk os environment at: 'DUCKDB_LIB_PATH' ifPresent: [ :path | ^ path ].
	^ (FileLocator imageDirectory parent / 'lib' / 'libduckdb.so') pathString
]

{ #category : 'accessing' }
DuckDBLibrary >> win32LibraryName [
	"DUCKDB_LIB_PATH overrides the default DLL name (CI / non-standard installs)."
	Smalltalk os environment at: 'DUCKDB_LIB_PATH' ifPresent: [ :path | ^ path ].
	^ 'duckdb.dll'
]

{ #category : 'constants' }
DuckDBLibrary class >> success [
	^ 0
]

{ #category : 'constants' }
DuckDBLibrary class >> error [
	^ 1
]

{ #category : 'ffi - lifecycle' }
DuckDBLibrary >> duckdbOpen: path outDatabase: db [
	"duckdb_state duckdb_open(const char *path, duckdb_database *out_database)"
	^ self ffiCall: #(int duckdb_open(String path, DuckDBHandle* db))
]

{ #category : 'ffi - lifecycle' }
DuckDBLibrary >> duckdbClose: db [
	"void duckdb_close(duckdb_database *database)"
	^ self ffiCall: #(void duckdb_close(DuckDBHandle* db))
]

{ #category : 'ffi - lifecycle' }
DuckDBLibrary >> duckdbConnect: db outConnection: conn [
	"duckdb_state duckdb_connect(duckdb_database database, duckdb_connection *out_connection)"
	^ self ffiCall: #(int duckdb_connect(DuckDBHandle* db, DuckDBConnectionHandle* conn))
]

{ #category : 'ffi - lifecycle' }
DuckDBLibrary >> duckdbDisconnect: conn [
	"void duckdb_disconnect(duckdb_connection *connection)"
	^ self ffiCall: #(void duckdb_disconnect(DuckDBConnectionHandle* conn))
]

{ #category : 'ffi - query' }
DuckDBLibrary >> duckdbQuery: conn query: sql outResult: result [
	"duckdb_state duckdb_query(duckdb_connection connection, const char *query, duckdb_result *out_result)"
	^ self ffiCall: #(int duckdb_query(DuckDBConnectionHandle* conn, String sql, ExternalAddress* result))
]

{ #category : 'ffi - query' }
DuckDBLibrary >> duckdbDestroyResult: result [
	"void duckdb_destroy_result(duckdb_result *result)"
	^ self ffiCall: #(void duckdb_destroy_result(ExternalAddress* result))
]

{ #category : 'ffi - result metadata' }
DuckDBLibrary >> duckdbResultRowCount: result [
	"idx_t duckdb_row_count(duckdb_result *result)"
	^ self ffiCall: #(uint64 duckdb_row_count(ExternalAddress* result))
]

{ #category : 'ffi - result metadata' }
DuckDBLibrary >> duckdbResultColumnCount: result [
	"idx_t duckdb_column_count(duckdb_result *result)"
	^ self ffiCall: #(uint64 duckdb_column_count(ExternalAddress* result))
]

{ #category : 'ffi - result metadata' }
DuckDBLibrary >> duckdbColumnName: result col: colIdx [
	"const char *duckdb_column_name(duckdb_result *result, idx_t col)"
	^ self ffiCall: #(String duckdb_column_name(ExternalAddress* result, uint64 colIdx))
]

{ #category : 'ffi - result metadata' }
DuckDBLibrary >> duckdbColumnType: result col: colIdx [
	"duckdb_type duckdb_column_type(duckdb_result *result, idx_t col)"
	^ self ffiCall: #(int duckdb_column_type(ExternalAddress* result, uint64 colIdx))
]

{ #category : 'ffi - result access' }
DuckDBLibrary >> duckdbValueIsNull: result col: colIdx row: rowIdx [
	^ self ffiCall: #(bool duckdb_value_is_null(ExternalAddress* result, uint64 colIdx, uint64 rowIdx))
]

{ #category : 'ffi - result access' }
DuckDBLibrary >> duckdbValueBoolean: result col: colIdx row: rowIdx [
	^ self ffiCall: #(bool duckdb_value_boolean(ExternalAddress* result, uint64 colIdx, uint64 rowIdx))
]

{ #category : 'ffi - result access' }
DuckDBLibrary >> duckdbValueInt8: result col: colIdx row: rowIdx [
	^ self ffiCall: #(int8 duckdb_value_int8(ExternalAddress* result, uint64 colIdx, uint64 rowIdx))
]

{ #category : 'ffi - result access' }
DuckDBLibrary >> duckdbValueInt16: result col: colIdx row: rowIdx [
	^ self ffiCall: #(int16 duckdb_value_int16(ExternalAddress* result, uint64 colIdx, uint64 rowIdx))
]

{ #category : 'ffi - result access' }
DuckDBLibrary >> duckdbValueInt32: result col: colIdx row: rowIdx [
	^ self ffiCall: #(int32 duckdb_value_int32(ExternalAddress* result, uint64 colIdx, uint64 rowIdx))
]

{ #category : 'ffi - result access' }
DuckDBLibrary >> duckdbValueInt64: result col: colIdx row: rowIdx [
	^ self ffiCall: #(int64 duckdb_value_int64(ExternalAddress* result, uint64 colIdx, uint64 rowIdx))
]

{ #category : 'ffi - result access' }
DuckDBLibrary >> duckdbValueFloat: result col: colIdx row: rowIdx [
	^ self ffiCall: #(float duckdb_value_float(ExternalAddress* result, uint64 colIdx, uint64 rowIdx))
]

{ #category : 'ffi - result access' }
DuckDBLibrary >> duckdbValueDouble: result col: colIdx row: rowIdx [
	^ self ffiCall: #(double duckdb_value_double(ExternalAddress* result, uint64 colIdx, uint64 rowIdx))
]

{ #category : 'ffi - result access' }
DuckDBLibrary >> duckdbValueUInt8: result col: colIdx row: rowIdx [
	^ self ffiCall: #(uint8 duckdb_value_uint8(ExternalAddress* result, uint64 colIdx, uint64 rowIdx))
]

{ #category : 'ffi - result access' }
DuckDBLibrary >> duckdbValueUInt16: result col: colIdx row: rowIdx [
	^ self ffiCall: #(uint16 duckdb_value_uint16(ExternalAddress* result, uint64 colIdx, uint64 rowIdx))
]

{ #category : 'ffi - result access' }
DuckDBLibrary >> duckdbValueUInt32: result col: colIdx row: rowIdx [
	^ self ffiCall: #(uint32 duckdb_value_uint32(ExternalAddress* result, uint64 colIdx, uint64 rowIdx))
]

{ #category : 'ffi - result access' }
DuckDBLibrary >> duckdbValueUInt64: result col: colIdx row: rowIdx [
	^ self ffiCall: #(uint64 duckdb_value_uint64(ExternalAddress* result, uint64 colIdx, uint64 rowIdx))
]

{ #category : 'ffi - result access' }
DuckDBLibrary >> duckdbValueInterval: result col: colIdx row: rowIdx [
	"duckdb_interval duckdb_value_interval(duckdb_result *result, idx_t col, idx_t row)
	 Returns the duckdb_interval struct (months, days, micros) BY VALUE."
	^ self ffiCall: #(DuckDBIntervalStruct duckdb_value_interval(ExternalAddress* result, uint64 colIdx, uint64 rowIdx))
]

{ #category : 'ffi - result access' }
DuckDBLibrary >> duckdbValueDate: result col: colIdx row: rowIdx [
	"duckdb_date duckdb_value_date(duckdb_result *result, idx_t col, idx_t row)
	 Returns the duckdb_date struct (int32 days since 1970-01-01) BY VALUE."
	^ self ffiCall: #(DuckDBDateStruct duckdb_value_date(ExternalAddress* result, uint64 colIdx, uint64 rowIdx))
]

{ #category : 'ffi - result access' }
DuckDBLibrary >> duckdbValueTime: result col: colIdx row: rowIdx [
	"duckdb_time duckdb_value_time(duckdb_result *result, idx_t col, idx_t row)
	 Returns the duckdb_time struct (int64 micros since 00:00:00) BY VALUE."
	^ self ffiCall: #(DuckDBTimeStruct duckdb_value_time(ExternalAddress* result, uint64 colIdx, uint64 rowIdx))
]

{ #category : 'ffi - result access' }
DuckDBLibrary >> duckdbValueTimestamp: result col: colIdx row: rowIdx [
	"duckdb_timestamp duckdb_value_timestamp(duckdb_result *result, idx_t col, idx_t row)
	 Returns the duckdb_timestamp struct (int64 micros since 1970-01-01) BY VALUE."
	^ self ffiCall: #(DuckDBTimestampStruct duckdb_value_timestamp(ExternalAddress* result, uint64 colIdx, uint64 rowIdx))
]

{ #category : 'ffi - result access' }
DuckDBLibrary >> duckdbValueBlob: result col: colIdx row: rowIdx [
	"duckdb_blob duckdb_value_blob(duckdb_result *result, idx_t col, idx_t row)
	 Returns the duckdb_blob struct BY VALUE; blob.data must be freed with duckdbFree:."
	^ self ffiCall: #(DuckDBBlobStruct duckdb_value_blob(ExternalAddress* result, uint64 colIdx, uint64 rowIdx))
]

{ #category : 'ffi - result access' }
DuckDBLibrary >> duckdbValueVarchar: result col: colIdx row: rowIdx [
	"char *duckdb_value_varchar(duckdb_result *result, idx_t col, idx_t row)
	 Returns a malloc'ed char* that the CALLER must free with duckdbFree:.
	 Declared void* (not String) so the pointer stays accessible for freeing."
	^ self ffiCall: #(void* duckdb_value_varchar(ExternalAddress* result, uint64 colIdx, uint64 rowIdx))
]

{ #category : 'ffi - memory' }
DuckDBLibrary >> duckdbFree: pointer [
	"void duckdb_free(void *ptr)
	 Frees values returned by duckdb_value_varchar / duckdb_value_blob (blob.data)."
	^ self ffiCall: #(void duckdb_free(void* pointer))
]

{ #category : 'ffi - result access' }
DuckDBLibrary >> duckdbResultError: result [
	"const char *duckdb_result_error(duckdb_result *result)"
	^ self ffiCall: #(String duckdb_result_error(ExternalAddress* result))
]

{ #category : 'ffi - prepared' }
DuckDBLibrary >> duckdbPrepare: conn query: sql outStatement: stmt [
	"duckdb_state duckdb_prepare(duckdb_connection connection, const char *query, duckdb_prepared_statement *out)"
	^ self ffiCall: #(int duckdb_prepare(DuckDBConnectionHandle* conn, String sql, DuckDBPreparedHandle* stmt))
]

{ #category : 'ffi - prepared' }
DuckDBLibrary >> duckdbDestroyPrepare: stmt [
	"void duckdb_destroy_prepare(duckdb_prepared_statement *prepared_statement)"
	^ self ffiCall: #(void duckdb_destroy_prepare(DuckDBPreparedHandle* stmt))
]

{ #category : 'ffi - prepared' }
DuckDBLibrary >> duckdbExecutePrepared: stmt outResult: result [
	"duckdb_state duckdb_execute_prepared(duckdb_prepared_statement prepared_statement, duckdb_result *out_result)"
	^ self ffiCall: #(int duckdb_execute_prepared(DuckDBPreparedHandle* stmt, ExternalAddress* result))
]

{ #category : 'ffi - prepared' }
DuckDBLibrary >> duckdbNparams: stmt [
	"idx_t duckdb_nparams(duckdb_prepared_statement prepared_statement)"
	^ self ffiCall: #(uint64 duckdb_nparams(DuckDBPreparedHandle* stmt))
]

{ #category : 'ffi - bind' }
DuckDBLibrary >> duckdbBindBoolean: stmt paramIdx: idx val: value [
	^ self ffiCall: #(int duckdb_bind_boolean(DuckDBPreparedHandle* stmt, uint64 idx, bool value))
]

{ #category : 'ffi - bind' }
DuckDBLibrary >> duckdbBindInt32: stmt paramIdx: idx val: value [
	^ self ffiCall: #(int duckdb_bind_int32(DuckDBPreparedHandle* stmt, uint64 idx, int32 value))
]

{ #category : 'ffi - bind' }
DuckDBLibrary >> duckdbBindInt64: stmt paramIdx: idx val: value [
	^ self ffiCall: #(int duckdb_bind_int64(DuckDBPreparedHandle* stmt, uint64 idx, int64 value))
]

{ #category : 'ffi - bind' }
DuckDBLibrary >> duckdbBindDouble: stmt paramIdx: idx val: value [
	^ self ffiCall: #(int duckdb_bind_double(DuckDBPreparedHandle* stmt, uint64 idx, double value))
]

{ #category : 'ffi - bind' }
DuckDBLibrary >> duckdbBindVarchar: stmt paramIdx: idx val: value [
	^ self ffiCall: #(int duckdb_bind_varchar(DuckDBPreparedHandle* stmt, uint64 idx, String value))
]

{ #category : 'ffi - bind' }
DuckDBLibrary >> duckdbBindNull: stmt paramIdx: idx [
	^ self ffiCall: #(int duckdb_bind_null(DuckDBPreparedHandle* stmt, uint64 idx))
]

{ #category : 'ffi - bind' }
DuckDBLibrary >> duckdbBindDate: stmt paramIdx: idx val: aDateStruct [
	"duckdb_state duckdb_bind_date(duckdb_prepared_statement, idx_t, duckdb_date val)
	 The duckdb_date struct is passed BY VALUE."
	^ self ffiCall: #(int duckdb_bind_date(DuckDBPreparedHandle* stmt, uint64 idx, DuckDBDateStruct aDateStruct))
]

{ #category : 'ffi - bind' }
DuckDBLibrary >> duckdbBindTime: stmt paramIdx: idx val: aTimeStruct [
	"duckdb_state duckdb_bind_time(duckdb_prepared_statement, idx_t, duckdb_time val)
	 The duckdb_time struct is passed BY VALUE."
	^ self ffiCall: #(int duckdb_bind_time(DuckDBPreparedHandle* stmt, uint64 idx, DuckDBTimeStruct aTimeStruct))
]

{ #category : 'ffi - bind' }
DuckDBLibrary >> duckdbBindTimestamp: stmt paramIdx: idx val: aTimestampStruct [
	"duckdb_state duckdb_bind_timestamp(duckdb_prepared_statement, idx_t, duckdb_timestamp val)
	 The duckdb_timestamp struct is passed BY VALUE."
	^ self ffiCall: #(int duckdb_bind_timestamp(DuckDBPreparedHandle* stmt, uint64 idx, DuckDBTimestampStruct aTimestampStruct))
]

{ #category : 'ffi - bind' }
DuckDBLibrary >> duckdbBindBlob: stmt paramIdx: idx data: bytes length: len [
	"duckdb_state duckdb_bind_blob(duckdb_prepared_statement, idx_t, const void *data, idx_t length)
	 DuckDB copies the bytes during the call, so passing a pinned ByteArray is safe."
	^ self ffiCall: #(int duckdb_bind_blob(DuckDBPreparedHandle* stmt, uint64 idx, void* bytes, uint64 len))
]

{ #category : 'ffi - utility' }
DuckDBLibrary >> duckdbLibraryVersion [
	"const char *duckdb_library_version()"
	^ self ffiCall: #(String duckdb_library_version())
]

{ #category : 'ffi - data chunk' }
DuckDBLibrary >> duckdbFetchChunk: aResultStruct [
	"duckdb_data_chunk duckdb_fetch_chunk(duckdb_result result)
	 Takes the 48-byte duckdb_result BY VALUE (not a pointer like the value API).
	 Returns an opaque duckdb_data_chunk pointer, or NULL when the result is exhausted."
	^ self ffiCall: #(void* duckdb_fetch_chunk(DuckDBResultStruct aResultStruct))
]

{ #category : 'ffi - data chunk' }
DuckDBLibrary >> duckdbDataChunkGetSize: chunk [
	"idx_t duckdb_data_chunk_get_size(duckdb_data_chunk chunk)"
	^ self ffiCall: #(uint64 duckdb_data_chunk_get_size(void* chunk))
]

{ #category : 'ffi - data chunk' }
DuckDBLibrary >> duckdbDataChunkGetColumnCount: chunk [
	"idx_t duckdb_data_chunk_get_column_count(duckdb_data_chunk chunk)"
	^ self ffiCall: #(uint64 duckdb_data_chunk_get_column_count(void* chunk))
]

{ #category : 'ffi - data chunk' }
DuckDBLibrary >> duckdbDataChunkGetVector: chunk col: colIdx [
	"duckdb_vector duckdb_data_chunk_get_vector(duckdb_data_chunk chunk, idx_t col_idx)
	 The vector is valid as long as the chunk is alive; it must NOT be destroyed."
	^ self ffiCall: #(void* duckdb_data_chunk_get_vector(void* chunk, uint64 colIdx))
]

{ #category : 'ffi - data chunk' }
DuckDBLibrary >> duckdbDestroyDataChunk: chunkSlot [
	"void duckdb_destroy_data_chunk(duckdb_data_chunk *chunk)
	 chunkSlot is an 8-byte slot holding the chunk pointer (pass the slot, not the pointer)."
	^ self ffiCall: #(void duckdb_destroy_data_chunk(void* chunkSlot))
]

{ #category : 'ffi - data chunk' }
DuckDBLibrary >> duckdbVectorGetData: vector [
	"void *duckdb_vector_get_data(duckdb_vector vector)
	 Pointer to the column's flat data array (interpretation depends on the type)."
	^ self ffiCall: #(void* duckdb_vector_get_data(void* vector))
]

{ #category : 'ffi - data chunk' }
DuckDBLibrary >> duckdbVectorGetValidity: vector [
	"uint64_t *duckdb_vector_get_validity(duckdb_vector vector)
	 Bitset (one bit per row, 1 = valid). Returns NULL when every value is valid."
	^ self ffiCall: #(void* duckdb_vector_get_validity(void* vector))
]

{ #category : 'ffi - data chunk' }
DuckDBLibrary >> duckdbListVectorGetChild: vector [
	"duckdb_vector duckdb_list_vector_get_child(duckdb_vector vector)
	 Child vector holding all list elements; valid while the parent vector is alive."
	^ self ffiCall: #(void* duckdb_list_vector_get_child(void* vector))
]

{ #category : 'ffi - data chunk' }
DuckDBLibrary >> duckdbListVectorGetSize: vector [
	"idx_t duckdb_list_vector_get_size(duckdb_vector vector)"
	^ self ffiCall: #(uint64 duckdb_list_vector_get_size(void* vector))
]

{ #category : 'ffi - data chunk' }
DuckDBLibrary >> duckdbStructVectorGetChild: vector index: childIdx [
	"duckdb_vector duckdb_struct_vector_get_child(duckdb_vector vector, idx_t index)"
	^ self ffiCall: #(void* duckdb_struct_vector_get_child(void* vector, uint64 childIdx))
]

{ #category : 'ffi - logical type' }
DuckDBLibrary >> duckdbVectorGetColumnType: vector [
	"duckdb_logical_type duckdb_vector_get_column_type(duckdb_vector vector)
	 The returned logical type must be destroyed with duckdbDestroyLogicalType:."
	^ self ffiCall: #(void* duckdb_vector_get_column_type(void* vector))
]

{ #category : 'ffi - logical type' }
DuckDBLibrary >> duckdbGetTypeId: logicalType [
	"duckdb_type duckdb_get_type_id(duckdb_logical_type type)"
	^ self ffiCall: #(uint32 duckdb_get_type_id(void* logicalType))
]

{ #category : 'ffi - logical type' }
DuckDBLibrary >> duckdbDestroyLogicalType: logicalTypeSlot [
	"void duckdb_destroy_logical_type(duckdb_logical_type *type)
	 logicalTypeSlot is an 8-byte slot holding the logical type pointer."
	^ self ffiCall: #(void duckdb_destroy_logical_type(void* logicalTypeSlot))
]

{ #category : 'ffi - logical type' }
DuckDBLibrary >> duckdbListTypeChildType: logicalType [
	"duckdb_logical_type duckdb_list_type_child_type(duckdb_logical_type type)
	 Accepts LIST (and MAP). Returned type must be destroyed."
	^ self ffiCall: #(void* duckdb_list_type_child_type(void* logicalType))
]

{ #category : 'ffi - logical type' }
DuckDBLibrary >> duckdbStructTypeChildCount: logicalType [
	"idx_t duckdb_struct_type_child_count(duckdb_logical_type type)"
	^ self ffiCall: #(uint64 duckdb_struct_type_child_count(void* logicalType))
]

{ #category : 'ffi - logical type' }
DuckDBLibrary >> duckdbStructTypeChildName: logicalType index: childIdx [
	"char *duckdb_struct_type_child_name(duckdb_logical_type type, idx_t index)
	 Returned char* must be freed with duckdbFree:."
	^ self ffiCall: #(void* duckdb_struct_type_child_name(void* logicalType, uint64 childIdx))
]

{ #category : 'ffi - logical type' }
DuckDBLibrary >> duckdbStructTypeChildType: logicalType index: childIdx [
	"duckdb_logical_type duckdb_struct_type_child_type(duckdb_logical_type type, idx_t index)
	 Returned type must be destroyed."
	^ self ffiCall: #(void* duckdb_struct_type_child_type(void* logicalType, uint64 childIdx))
]

{ #category : 'ffi - logical type' }
DuckDBLibrary >> duckdbMapTypeKeyType: logicalType [
	"duckdb_logical_type duckdb_map_type_key_type(duckdb_logical_type type)
	 Returned type must be destroyed."
	^ self ffiCall: #(void* duckdb_map_type_key_type(void* logicalType))
]

{ #category : 'ffi - logical type' }
DuckDBLibrary >> duckdbMapTypeValueType: logicalType [
	"duckdb_logical_type duckdb_map_type_value_type(duckdb_logical_type type)
	 Returned type must be destroyed."
	^ self ffiCall: #(void* duckdb_map_type_value_type(void* logicalType))
]

{ #category : 'ffi - logical type' }
DuckDBLibrary >> duckdbEnumInternalType: logicalType [
	"duckdb_type duckdb_enum_internal_type(duckdb_logical_type type)
	 The integer storage type (UTINYINT / USMALLINT / UINTEGER) of the enum index."
	^ self ffiCall: #(uint32 duckdb_enum_internal_type(void* logicalType))
]

{ #category : 'ffi - logical type' }
DuckDBLibrary >> duckdbEnumDictionaryValue: logicalType index: dictIdx [
	"char *duckdb_enum_dictionary_value(duckdb_logical_type type, idx_t index)
	 Returned char* must be freed with duckdbFree:."
	^ self ffiCall: #(void* duckdb_enum_dictionary_value(void* logicalType, uint64 dictIdx))
]

{ #category : 'ffi - logical type' }
DuckDBLibrary >> duckdbDecimalScale: logicalType [
	"uint8_t duckdb_decimal_scale(duckdb_logical_type type)"
	^ self ffiCall: #(uint8 duckdb_decimal_scale(void* logicalType))
]

{ #category : 'ffi - logical type' }
DuckDBLibrary >> duckdbDecimalInternalType: logicalType [
	"duckdb_type duckdb_decimal_internal_type(duckdb_logical_type type)"
	^ self ffiCall: #(uint32 duckdb_decimal_internal_type(void* logicalType))
]
