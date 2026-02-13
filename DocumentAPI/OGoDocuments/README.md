# OGoDocuments - Base Document Framework

OGoDocuments provides the superclasses and protocols for
the DocumentAPI abstraction layer. All document, datasource,
and file manager implementations in other DocumentAPI
modules extend these base classes.

Also includes documents and datasources for accessing
local filesystem project dumps (e.g. those emitted by
`OGoProjectExporter`).

**Built as:** `libOGoDocuments` (shared library)


## Dependencies

- Foundation, EOControl, NGExtensions


## Key Protocols

| Protocol | Purpose |
|---------------------------|-------------------------------|
| `SkyDocument`             | Base document interface       |
| `SkyDocumentEditing`      | Editable document interface   |
| `SkyBLOBDocument`         | Binary content (NSData)       |
| `SkyStringBLOBDocument`   | String content                |
| `SkyDOMBLOBDocument`      | DOM tree content              |
| `SkyContext`              | Context providing doc manager |
| `SkyDocumentFileManager`  | File manager protocol         |
| `SkyDocumentManager`      | URL/GID/Document mapping      |


## Key Classes

| Class | Purpose |
|---------------------------|-------------------------------|
| `SkyDocument`             | Base document class           |
| `SkyDocumentType`         | Schema descriptor             |
| `SkyDocumentManagerImp`   | Document manager impl         |
| `NGLocalFileManager`      | Filesystem file manager       |
| `NGLocalFileDocument`     | Filesystem document           |
| `NGLocalFileDataSource`   | Filesystem datasource         |
| `NGLocalFileGlobalID`     | Filesystem global ID          |
| `LSCommandContext+Doc`    | Context-to-doc bridge         |


## Document Protocol

All documents conform to the `SkyDocument` protocol:

```objc
- (EOGlobalID *)globalID;
- (NSURL *)baseURL;
- (id)context;
- (BOOL)supportsFeature:(NSString *)feature;
- (BOOL)isNew;
- (BOOL)isValid;
- (BOOL)isComplete;
- (void)logException:(NSException *)e;
```

Editable documents add:

```objc
- (BOOL)isEdited;
- (void)save;
- (void)delete;
- (void)reload;
```
