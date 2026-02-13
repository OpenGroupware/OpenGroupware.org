# OGoProject - Project Documents

OGoProject provides project-related datasources and
documents. It wraps the project Logic commands and
defines the `SkyProject` document that the WebUI and
protocol layers use.

**Built as:** `libOGoProject` (shared library) and
`OGoProject.ds` (datasource bundle)


## Dependencies

- OGoDocuments
- OGoBase
- LSFoundation (Logic layer)


## Key Classes

| Class | Purpose |
|-------------------------------|-------------------------------|
| `SkyProject`                  | Project document              |
| `SkyProjectDataSource`        | Project datasource            |
| `SkyProjectHistoryDocument`   | Project history entry         |
| `SkyProjectTeamDataSource`    | Project team members          |
| `OGoFileManagerFactory`       | File manager creation         |
| `SkyContentHandler`           | Document content handler      |
| `NGFileManagerCopyTool`       | File copying utility          |
| `SkyProjectBundleManager`     | Bundle principal class        |
| `SkyProjectAccessHandler`     | Access control handler        |


## SkyProject

Represents an OGo project with properties:

- `name`, `number`, `url`
- `startDate`, `endDate`
- `projectStatus`, `kind`, `type`
- `leader` (SkyDocument), `team` (SkyDocument)

Methods: `addAccount:`, `removeAccount:`,
`fileManager`, `documentDataSource`,
`teamDataSource`.


## Project Types

Project *type* (common, private, archived) is derived
at runtime, not stored in the database. Project *kind*
is a database field for special projects but is not
commonly used in core OGo.

"Fake" projects are auto-created projects attached to
company records and hidden from the project listing.


## File Attributes

Projects expose standard file attributes:

- `NSFileType`, `NSFileSize`, `NSFileModificationDate`
- `SkyTitle`, `SkyStatus`, `SkyVersionCount`
- `SkyCreationDate`, `SkyLastModifiedDate`
- `SkyFirstOwnerId`, `SkyOwnerId`
- `projectNumber`, `projectName`, `projectId`
