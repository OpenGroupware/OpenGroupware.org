# OGoBase - Common Base Datasources

OGoBase provides common datasources and documents used
across the DocumentAPI layer. Currently contains logging
datasources and the context-to-document bridge.

**Built as:** `libOGoBase` (shared library) and
`OGoBase.ds` (datasource bundle)


## Dependencies

- OGoDocuments
- LSFoundation (Logic layer)


## Key Classes

| Class | Purpose |
|---------------------------|-------------------------------|
| `SkyLogDataSource`        | DataSource for log entries    |
| `SkyLogDocument`          | Document for a log entry      |
| `LSCommandContext+Doc`    | Context-to-document bridge    |
| `SkyBaseBundleManager`    | Bundle principal class        |


## SkyLogDocument

Represents a single log entry with properties:

- `objectId` - Log entry ID
- `creationDate` - When the entry was created
- `logText` - Log message text
- `accountId` - Account that created the entry
- `action` - Action that triggered the log
- `isNew`, `isSaved` - Status tracking
