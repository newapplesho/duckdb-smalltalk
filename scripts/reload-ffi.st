| repo pkg |
repo := TonelRepository on: (FileLocator imageDirectory parent / 'src') asFileReference.
pkg := repo versionFor: 'DuckDB-FFI'.
pkg load.
Smalltalk snapshot: true andQuit: false.
Stdio stdout nextPutAll: 'FFI-reload-ok'; nl.