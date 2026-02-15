# Project - Project and Document UI

Project provides the web interface for project
management, document storage, notes, and file
operations (upload, download, versioning, zip).


## Sub-Bundles

### OGoProject - Main Project/Document UI

**Bundle:** `OGoProject.lso` (60+ source files)

The largest WebUI bundle, providing:
- **Desktop:** `SkyProject4Desktop` - Project desktop
- **Documents:** `OGoProjectDocView`,
  `SkyProject4BLOBViewer` - Document viewing
- **Search:** `SkyProject4DocumentSearch`
- **Versions:** `SkyProject4VersionList`
- **Navigation:** `SkyP4DocumentPath`,
  `SkyP4FolderView`
- **Downloads:** `SkyP4DownloadLink`,
  `LSWDocumentDownloadAction`
- **Import:** `OGoDocumentImport`
- **Properties:** `SkyDocumentAttributeEditor`
- **Journal:** `SkyP4DocJournal`
- **Access:** `SkyCompanyAccessEditor`

### OGoNote - Note Management

**Bundle:** `OGoNote.lso` (5 source files)

Project notes:
- `SkyNoteList` - List notes
- `SkyNoteEditor` - Edit notes
- `SkyNotePrint` - Print notes

### OGoDocInlineViewers - Document Viewers

**Bundle:** `OGoDocInlineViewers.lso` (13 source files)

Inline document content display:
- `OGoDocAttrsViewer` - Document attributes
- `OGoDocContentsViewer` - File content
- `OGoDocVersionsViewer` - Version history
- `OGoDocAccessViewer` - Access control
- `OGoDocLogsViewer` - Activity log
- `SkyDocImageInlineViewer` - Image preview
- `SkyDocEmbedInlineViewer` - Embedded viewer

### OGoProjectZip - Archive Support

**Bundle:** `OGoProjectZip.lso` (11 source files)

Zip/tar compression and extraction:
- `SkyP4ZipPanel` - Compress files
- `SkyP4UnzipPanel` - Extract archives
- `SkyDocZipInlineViewer` - Preview zip contents
- `SkyDocTarInlineViewer` - Preview tar contents

### OGoProjectInfo - Dock Links

**Bundle:** `OGoProjectInfo.lso` (3 source files)

Lightweight bundle for dock project links:
- `SkyDockedProjects` - Docked project list

### LSWProject - Legacy Project (3.x)

**Bundle:** `LSWProject.lso` (24 source files)

Legacy project components, some still in use:
- `LSWProjectEditor`, `LSWProjectWizard`
- `SkyProjectList`, `SkyProjectSelection`
- `LSWDocumentViewer`
- `LSWProjectPreferences`
- `SkyJobResourceEditor`

### OGoSoProject - SOAP Object Model

**Bundle:** `OGoSoProject.lso` (7 source files)

SOPE/SOAP project object model:
- `OGoSoProject`, `OGoSoDocFolder`,
  `OGoSoProjects`


# README

This directory contains the bundles which implement the OpenGroupware.org
web interface for the "project" application. The project application contains
the document management system and maintains various links between OGo
objects.

Bundles
=======

LSWProject
- contains parts of the "old" SKYRiX 3.x project application
- contains the deprecated "process" things (real project management things)
- contains some components still used in OGoProject
=> TODO: move required stuff to OGoProject

OGoDocInlineViewers
- components for embedding document content

OGoNote
- components for listing and editing "Note" records

OGoProject
- contains most of the OpenGroupware.org UI for the project application
- project viewers, project lists
- document viewers, editors, searches
- etc

OGoProjectInfo
- this bundle contains the component required to show project links in
  the dock, it's placed in a separate bundle to avoid loading the whole
  OGoProject just for displaying a list of links

OGoProjectZip
- contains viewers and components to compress and uncompress files in
  the document system using zip and tar

OGoProjectForms
- all the stuff required for having customized forms in projects
