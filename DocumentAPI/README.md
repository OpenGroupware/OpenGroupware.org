# DocumentAPI - Document Abstraction Layer

The DocumentAPI wraps the OGo Logic layer in a
higher-level "document" API. It provides three related
abstractions that the WebUI and protocol layers
(XML-RPC, WebDAV) use to interact with OGo data:

- **Document** - Object representation of a record
- **DataSource** - Fetch interface returning Documents
- **FileManager** - Storage abstraction for file operations

**Requires:** SOPE, GDL, Logic


## Build Order

Modules build in this order (defined in GNUmakefile):

1. **OGoDocuments** - Base library with superclasses
2. **OGoRawDatabase** - Raw SQL table access
3. **OGoAccounts** - Account/team documents
4. **OGoContacts** - Person/enterprise documents
5. **OGoBase** - Common datasources (logging)
6. **OGoProject** - Project documents
7. **OGoDatabaseProject** - Database storage backend
8. **OGoFileSystemProject** - Filesystem storage backend
9. **OGoJobs** - Task/job documents
10. **OGoScheduler** - Appointment documents


## Module Overview

| Module | Type | Purpose |
|----------------------|-----------|---------------------------|
| OGoDocuments         | Library   | Base document classes     |
| OGoRawDatabase       | Lib+Bundle| Raw SQL table access      |
| OGoBase              | Lib+Bundle| Common datasources (log)  |
| OGoAccounts          | Lib+Bundle| Account/team wrappers     |
| OGoContacts          | Lib+Bundle| Person/enterprise wrappers|
| OGoProject           | Lib+Bundle| Project documents         |
| OGoDatabaseProject   | Lib+Bundle| DB-backed project storage |
| OGoFileSystemProject | Lib+Bundle| FS-backed project storage |
| OGoJobs              | Lib+Bundle| Task/job documents        |
| OGoScheduler         | Lib+Bundle| Appointment documents     |


## Architecture

Most modules are built as both a shared library (for
compile-time linking) and a `.ds` bundle (for runtime
loading). The library exports the public headers and
classes, while the bundle registers with the document
manager via a principal class.

```
WebUI / XML-RPC / WebDAV
        ↓
  DocumentAPI (Documents, DataSources, FileManagers)
        ↓
  Logic Commands (LSRunCommandV)
        ↓
  Database (GDLAccess / EOF)
```
