"
I am signaled when a SQL query or statement fails: syntax errors,
constraint violations, failed preparation or execution.
My messageText carries the error message reported by the DuckDB C API.
"
Class {
	#name : 'DuckDBQueryError',
	#superclass : 'DuckDBError',
	#instVars : [],
	#classVars : [],
	#package : 'DuckDB-Core'
}
