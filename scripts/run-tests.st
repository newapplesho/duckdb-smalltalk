"Run all DuckDB tests and print results to the Transcript.
 Paste into the Playground and Ctrl+D, or run headlessly:
   ./pharo Pharo.image test 'DuckDB-Tests'
 (set DUCKDB_LIB_PATH before launching Pharo if the library is not under lib/;
 DYLD_LIBRARY_PATH is ignored by macOS SIP)."
| suite result |
suite := TestSuite new.
suite addTests: DuckDBConnectionTest buildSuite tests.
suite addTests: DuckDBTypeTest buildSuite tests.
result := suite run.
Transcript showCr: '=== DuckDB Test Results ==='.
Transcript showCr: 'Run:    ' , result runCount printString.
Transcript showCr: 'Passed: ' , (result runCount - result failures size - result errors size) printString.
Transcript showCr: 'Failed: ' , result failures size printString.
Transcript showCr: 'Errors: ' , result errors size printString.
result failures do: [:f |
	Transcript showCr: '  FAIL: ' , f printString].
result errors do: [:e |
	Transcript showCr: '  ERR:  ' , e printString].
