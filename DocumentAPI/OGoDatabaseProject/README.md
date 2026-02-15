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


# README

OGoDatabaseProject
==================

This bundle implements the document storage backend for 'database' based
projects. Such projects store document metadata in the database and the
actual file BLOB in the filesystem.

The functionality is based on the LSDocuments and LSProject Logic bundles.

Note that this bundle was previously one with OGoProjects and got moved out
when additional backend got available. Due to this the source is a bit messy.

Further the design of the SkyProjectFileManager needs a LOT of work, its a
huge class doing all kinds of things at the same time. This needs to get
refactored into several small units doing specific things.


Database Storage
================

Tables: document / document_version / document_editing

- folders are regular document's
- links are document's
- documents know their parents, not the reverse
- filenames are stored in the 'title' column
  - extensions are stored separate, in the 'filetype' column


Standard File Attribute Keys
============================

A few standard attributes are set in documents, some have multiple names. Not
all of them might be set in all documents.

Note: the 'title' is the filename in the database, the 'abstract' is the title
      or subject.

- check for hasPrefix:

This is from SkyProjectFileManager+FileAttributes.m:

attribute			document/database
- NSFileSubject / title		abstract
- filename			formatted 'title'
- fileType			fileType
- fileSize			fileSize
- status [released]		status
- globalID			documentId | documentVersionId
- versionCount			versionCount
- lastmodifiedDate		lastmodifiedDate
- creationDate			creationDate
- NSFileName / SkyFileName	formatted 'title' + extension
- NSFilePath / SkyFilePath	path + filename [+ version-id]
- SkyIsRootDirectory		- no parentDocumentId -
- SkyParentId			parentDocumentId
- SkyParentGID			GID of parentDocumentId
- NSFileMimeType		isFolder + isLink + fileType
- SkyLinkTarget			objectLink	(when !version && isLink)
- NSFileType
- SkyBlobPath
- SkyFirstOwnerId		GID of firstOwnerId
- NSFileOwnerAccountNumber / SkyOwnerId
				lastOwnerId | currentOwnerId
- SkyVersionName		version
- SkyVersionNumber		NSNumber of version
- SkyIsVersion
- SkyTitle			abstract
- SkyCreationDate		creationDate
- SkyStatus			status
- SkyVersionCount		versionCount
- NSFileModificationDate / SkyLastModifiedDate
				lastmodifiedDate | archiveDate (versions)
- projectNumber
- projectName
- projectId
