# OGoFileSystemProject - Filesystem Storage Backend

OGoFileSystemProject provides a filesystem-based storage
backend for OGo projects (also known as "DocShare").
Project files live directly on the filesystem rather than
in the database.

**Built as:** `libOGoFileSystemProject` (shared library)
and `OGoFileSystemProject.ds` (datasource bundle)


## Dependencies

- OGoDocuments
- OGoProject


## Key Classes

| Class | Purpose |
|---------------------------|-------------------------------|
| `SkyFSFileManager`        | Filesystem file manager       |
| `SkyFSDocument`           | Filesystem document           |
| `SkyFSDataSource`         | Filesystem datasource         |
| `SkyFSFolderDataSource`   | Folder contents datasource    |
| `SkyFSGlobalID`           | Global ID for FS documents    |
| `SkyFSException`          | Custom exception class        |
| `SkyFSProjectModule`      | Bundle principal class        |


## SkyFSFileManager

Wraps `NSFileManager` with OGo document semantics:

- File operations: copy, move, link, remove, create
- Directory operations: create, list
- Symbolic link support
- Distributed lock support
- Trash folder support
- Global ID mapping
- History datasource
- Exception handling


## SkyFSDocument

Represents a file on the filesystem as a document:

- Properties: `fileName`, `content` (NSData/NSString),
  `attributes`, `mimeType`, `fileType`, `path`
- Change tracking: `contentChanged`,
  `attributesChanged`
- Implements `SkyBLOBDocument` and
  `SkyStringBLOBDocument`
- DOM representation support
