# OGoRawDatabase - Raw SQL Table Access

OGoRawDatabase provides datasources and documents to
access raw SQL tables directly. It is used by SkyForms
to access RDBMS tables without going through the Logic
command layer.

**Built as:** `libOGoRawDatabase` (shared library) and
`OGoRawDatabase.ds` (datasource bundle)


## Dependencies

- OGoDocuments
- GDLAccess (EOF ORM layer)
- EOControl


## Key Classes

| Class | Purpose |
|---------------------------|-------------------------------|
| `SkyDBDocument`           | Document wrapping a DB row    |
| `SkyDBDataSource`         | DataSource returning documents|
| `SkyAdaptorDataSource`    | Low-level adaptor access      |
| `SkyDBDocumentType`       | Schema type for DB documents  |
| `OGoRawDatabaseModule`    | Bundle principal class        |


## SkyDBDocument

Wraps dictionaries from `SkyAdaptorDataSource` into
document objects with change tracking:

- Read/write property access via KVC
- Change tracking for save operations
- Global ID mapping for identity
- Supports save, delete, revert

Properties: `isValid`, `isDeletable`, `isNew`


## SkyDBDataSource

Wraps `SkyAdaptorDataSource` and returns
`SkyDBDocument` instances instead of raw dictionaries.
Provides schema information via `SkyDocumentType`.
