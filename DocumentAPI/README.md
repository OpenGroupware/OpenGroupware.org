# DocumentAPI - Document Abstraction Layer

[STABLE]

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
|----------------------|------------|---------------------------|
| OGoDocuments         | Library    | Base document classes     |
| OGoRawDatabase       | Lib+Bundle | Raw SQL table access      |
| OGoBase              | Lib+Bundle | Common datasources (log)  |
| OGoAccounts          | Lib+Bundle | Account/team wrappers     |
| OGoContacts          | Lib+Bundle | Person/enterprise wrappers|
| OGoProject           | Lib+Bundle | Project documents         |
| OGoDatabaseProject   | Lib+Bundle | DB-backed project storage |
| OGoFileSystemProject | Lib+Bundle | FS-backed project storage |
| OGoJobs              | Lib+Bundle | Task/job documents        |
| OGoScheduler         | Lib+Bundle | Appointment documents     |


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




DocumentAPI
===========

The DocumentAPI is a set of Objective-C libraries wrapping the SKYRiX
Logic in a "document" API.

The DocumentAPI has three related abstractions:
- Document
- DataSource
- FileManager

OGoDocuments
============
- library providing superclasses for document abstractions
- include documents/datasources for access project dumps
  (eg emitted by OGoProjectExporter)

OGoBase
=======
- a library and a bundle
- some datasources used everywhere
  - currently only "log" datasources, documents

OGoRawDatabase
=====
- datasources/documents to access "raw" SQL tables
- eg used to access RDBMS from SkyForms

OGoAccounts
===========
- wrappers around accounts/team

OGoContacts
===========
- wrappers around person and enterprise records

OGoScheduler
============
- document API for the scheduling module of OGo

OGoProject
==========
- project related datasources/documents

OGoJobs
=======
- document API for the todolist module of OGo

OGoDatabaseProject
==================
- "ProjectDocument", filemanager, etc.
- the database based storage backend for OGo projects

OGoFileSystemProject
====================
- the filesystem based storage backend for OGo projects
  (aka DocShare)
