# OGoDatabaseProject - Database Storage Backend

OGoDatabaseProject is the database-based storage backend
for OGo projects. Document metadata is stored in SQL
tables (`document`, `document_version`,
`document_editing`), while BLOB content lives on the
filesystem. This is the primary storage backend used by
most OGo installations.

**Built as:** `libOGoDatabaseProject` (shared library)
and `OGoDatabaseProject.ds` (datasource bundle)


## Dependencies

- OGoDocuments
- OGoProject
- LSFoundation (Logic layer, LSDocuments + LSProject)


## Key Classes

### Documents

| Class | Purpose |
|-------------------------------|-------------------------------|
| `SkyProjectDocument`          | Document in a DB project      |
| `SkyProjectDocument+DOM`      | DOM representation            |
| `SkyProjectDocument+Log`      | Log/history support           |

### File Manager

| Class | Purpose |
|-------------------------------|-------------------------------|
| `SkyProjectFileManager`       | Central file manager          |
| `SkyProjectFileManagerCache`  | Cache management              |
| `SkyDocumentIdHandler`        | Document ID generation        |
| `FMContext`                    | File manager context          |

### DataSources

| Class | Purpose |
|-------------------------------|-------------------------------|
| `SkyProjectDocumentDataSource`| Project document datasource   |
| `SkyProjectFolderDataSource`  | Folder contents datasource    |
| `SkySimpleProjectFolderDataSource`| Simplified folder DS      |
| `SkyDocumentHistoryDataSource`| Document version history      |
| `SkyDocumentDataSource`       | General document datasource   |

### Access Control

| Class | Purpose |
|-------------------------------|-------------------------------|
| `SkyDocumentAccessHandler`    | Document access handler       |
| `SkyDBProjectBundleManager`   | Bundle principal class        |


## Database Storage Model

- **Folders** are regular document records
- **Links** are document records with link targets
- Documents reference their parent via
  `parentDocumentId` (child → parent direction)
- Filenames stored in `title` column
- File extensions stored in `filetype` column


## SkyProjectFileManager

The central class, split across 10 source files for
manageability:

| File | Concern |
|---------------------------------------|-------------------|
| `SkyProjectFileManager.m`             | Core operations   |
| `+Documents.m`                        | Document access   |
| `+Extensions.m`                       | Extended attrs    |
| `+Internals.m`                        | Internal helpers  |
| `+Locking.m`                          | Lock management   |
| `+Notifications.m`                    | Change notify     |
| `+DeleteDocument.m`                   | Delete operations |
| `+Qualifier.m`                        | Qualifier support |
| `+FileAttributes.m`                   | File attributes   |
| `+ContentHandler.m`                   | Content handling  |

Supports: versioning (checkout/release), locking,
trash folder, file/directory operations, history
datasource, custom qualifiers, and global ID
conversion.


## Cache

`SkyProjectFileManagerCache` manages document caching,
split across 4 source files. Supports session-based or
timeout-based flushing with configurable strategy.
