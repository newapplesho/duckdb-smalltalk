"Run all DuckDB tests and print results to the Transcript.
 Paste into the Playground and Ctrl+D, or run headlessly:
   DYLD_LIBRARY_PATH=../lib ./pharo Pharo.image test 'DuckDB-Tests'"
| suite result |
suite := TestSuite new.
suite addTests: DuckDBConnectionTest buildSuite tests.
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
