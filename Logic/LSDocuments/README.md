# LSDocuments - Document Storage and Versioning

LSDocuments provides commands for managing documents stored
in the database, including versioning, checkout/release
workflows, and permission checking. Documents live within
projects and support collaborative editing through a
checkout/release cycle.

**Built as:** `LSDocuments.cmd` (command bundle)


## Dependencies

- LSFoundation


## Registered Commands

### `doc` Domain

| Command | Class | Description |
|-------------------------------|----------------------------------------------|---------------------------|
| `doc::new`                    | `LSNewDocumentCommand`                       | Create document           |
| `doc::set`                    | `LSSetDocumentCommand`                       | Update document           |
| `doc::get`                    | `LSGetDocumentCommand`                       | Fetch documents           |
| `doc::delete`                 | `LSDeleteDocumentCommand`                    | Delete document           |
| `doc::move`                   | `LSMoveDocumentCommand`                      | Move document             |
| `doc::checkout`               | `LSCheckoutDocumentCommand`                  | Check out for editing     |
| `doc::release`                | `LSReleaseDocumentCommand`                   | Release after editing     |
| `doc::reject`                 | `LSRejectDocumentCommand`                    | Reject checkout           |
| `doc::set-folder`             | `LSSetFolderCommand`                         | Update folder             |
| `doc::set-object-link`        | `LSSetObjectLinkCommand`                     | Set object link           |
| `doc::get-attachment-name`    | `LSGetAttachmentNameCommand`                 | Get file path on disk     |
| `doc::get-by-globalid`        | `LSGetDocumentForGlobalIDs`                  | Fetch by global ID        |
| `doc::extended-search`        | `LSExtendedSearchDocumentCommand`            | Extended search           |
| `doc::check-get-permission`   | `LSCheckGetPermissionDocumentCommand`        | Check read permission     |
| `doc::get-current-owner`      | `LSDBFetchRelationCommand`                   | Fetch current owner       |
| `doc::get-document-editing`   | `LSDBFetchRelationCommand`                   | Fetch editing record      |

### `documentversion` Domain

| Command | Description |
|----------------------------------------------|---------------------------|
| `documentversion::get`                       | Fetch versions            |
| `documentversion::new`                       | Create version            |
| `documentversion::set`                       | Update version            |
| `documentversion::delete`                    | Delete version            |
| `documentversion::checkout`                  | Check out version         |
| `documentversion::get-attachment-name`       | Get file path on disk     |
| `documentversion::get-last-owner`            | Fetch last owner          |
| `documentversion::check-get-permission`      | Check read permission     |

### `documentediting` Domain

| Command | Description |
|----------------------------------------------|---------------------------|
| `documentediting::get`                       | Fetch editing records     |
| `documentediting::get-attachment-name`       | Get file path on disk     |
| `documentediting::get-by-globalid`           | Fetch by global ID        |
| `documentediting::check-get-permission`      | Check read permission     |
| `documentediting::get-current-owner`         | Fetch current owner       |


## Key Classes

| Class | Base Class | Purpose |
|----------------------------------------------|--------------------------|---------------------------|
| `LSNewDocumentCommand`                       | `LSDBObjectNewCommand`   | Create document record    |
| `LSGetDocumentCommand`                       | `LSDBObjectGetCommand`   | Fetch documents           |
| `LSSetDocumentCommand`                       | `LSDBObjectSetCommand`   | Update document record    |
| `LSDeleteDocumentCommand`                    | `LSDBObjectDeleteCommand`| Delete document           |
| `LSCheckoutDocumentCommand`                  | `LSDBObjectBaseCommand`  | Checkout workflow         |
| `LSReleaseDocumentCommand`                   | `LSDBObjectBaseCommand`  | Release workflow          |
| `LSRejectDocumentCommand`                    | `LSDBObjectBaseCommand`  | Reject checkout           |
| `LSMoveDocumentCommand`                      | `LSDBObjectBaseCommand`  | Move between folders      |
| `LSGetAttachmentNameCommand`                 | `LSDBObjectBaseCommand`  | Resolve filesystem path   |
| `LSExtendedSearchDocumentCommand`            | `LSExtendedSearchCommand`| Structured search         |
| `LSFilterAndSortDocCommand`                  | -                        | Filter/sort documents     |
| `LSFilterAndSortFolderCommand`               | -                        | Filter/sort folders       |


## Document Workflow

Documents use a checkout/release cycle for collaborative
editing:

1. **Checkout** (`doc::checkout`) - Lock the document for
   editing by the current user
2. **Edit** - Modify the document content
3. **Release** (`doc::release`) - Unlock and create a new
   version
4. **Reject** (`doc::reject`) - Discard changes and unlock


## User Defaults

| Default | Type | Description |
|-------------------------------|--------|---------------------------|
| `UseFlatDocumentFileStructure`| BOOL   | Use flat file layout      |
| `UseFoldersForIDRanges`       | BOOL   | Group files by ID ranges  |
