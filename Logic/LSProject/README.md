# LSProject - Project Management

LSProject manages projects and their associated entities:
company assignments, notes, documents, and jobs (tasks).
Projects serve as containers that group documents and tasks,
and can be assigned to persons, enterprises, and teams.

**Built as:** `LSProject.cmd` (command bundle)


## Dependencies

- LSFoundation
- LSSearch


## Registered Commands

### `project` Domain

| Command | Description |
|--------------------------------------|---------------------------|
| `project::new`                       | Create project            |
| `project::set`                       | Update project            |
| `project::get`                       | Fetch projects            |
| `project::delete`                    | Delete project            |
| `project::archive`                   | Archive project           |
| `project::assignpartners`            | Assign company partners   |
| `project::assign-accounts`           | Assign accounts           |
| `project::get-status`                | Get project status        |
| `project::get-owner`                 | Fetch owner (Person)      |
| `project::get-team`                  | Fetch team                |
| `project::get-company-assignments`   | Fetch company assignments |
| `project::get-persons`               | Fetch assigned persons    |
| `project::get-enterprises`           | Fetch assigned enterprises|
| `project::get-accounts`              | Fetch assigned accounts   |
| `project::get-teams`                 | Fetch assigned teams      |
| `project::get-jobs`                  | Fetch project jobs        |
| `project::get-root-process`          | Fetch root job            |
| `project::get-root-document`         | Fetch root document       |
| `project::get-index-document`        | Fetch index document      |
| `project::get-comment`               | Fetch project comment     |
| `project::get-by-globalid`           | Fetch by global ID        |
| `project::check-permission`          | Check permission          |
| `project::check-get-permission`      | Check read permission     |
| `project::check-write-permission`    | Check write permission    |
| `project::get-favorite-ids`          | Get favorite project IDs  |
| `project::add-favorite`              | Add to favorites          |
| `project::remove-favorite`           | Remove from favorites     |

### `note` Domain

| Command | Description |
|--------------------------------------|---------------------------|
| `note::new`                          | Create note               |
| `note::set`                          | Update note               |
| `note::get`                          | Fetch notes               |
| `note::delete`                       | Delete note               |
| `note::get-attachment-name`          | Get file path on disk     |
| `note::get-current-owner`            | Fetch current owner       |

### `projectcompanyassignment` Domain (Private)

| Command | Description |
|--------------------------------------|---------------------------|
| `projectcompanyassignment::new`      | Create assignment         |
| `projectcompanyassignment::set`      | Update assignment         |
| `projectcompanyassignment::get`      | Fetch assignments         |
| `projectcompanyassignment::delete`   | Delete assignment         |


## Source Structure

The module is organized into three parts:

### Main Directory (20 source files)

Core project commands:
- `LSNewProjectCommand` - Create project
- `LSSetProjectCommand` - Update project
- `LSGetProjectCommand` - Fetch projects
- `LSDeleteProjectCommand` - Delete project
- `LSArchiveProjectCommand` - Archive project
- `LSProjectAssignmentCommand` - Assign companies
- `LSProjectStatusCommand` - Status management
- `LSCheckPermissionProjectCommand` - Permission checks
- `LSGetFavoriteProjectIdsCommand` - Favorites support

### Jobs.subproj (30+ source files)

Task/job commands within projects:
- `LSNewJobCommand`, `LSSetJobCommand`,
  `LSDeleteJobCommand`
- `LSJobActionCommand` - Status transitions
- `LSFetchToDoJobsCommand`, `LSFetchDelegatedJobsCommand`,
  `LSFetchArchivedJobsCommand`
- `LSFilterToDoListJobCommand`,
  `LSFilterDelegatedJobCommand`
- `LSGetParentJobsCommand` - Hierarchy navigation
- `LSAssignProjectToJobCommand`,
  `LSDetachProjectFromJobCommand`

### Documents.subproj (23 source files)

Document commands within projects (shared with
LSDocuments):
- Document CRUD, versioning, and editing
- Permission checking
- Search, filtering, and sorting


## Database Fields

| Field | Type | Description |
|-----------------|---------|-------------------------------|
| `project_id`    | int     | Primary key                   |
| `object_version`| int     | Optimistic locking version    |
| `owner_id`      | int     | Owner person ID               |
| `team_id`       | int     | Assigned team ID              |
| `number`        | string  | Project number                |
| `name`          | string  | Project name                  |
| `start_date`    | date    | Start date                    |
| `end_date`      | date    | End date                      |
| `status`        | string  | Status (e.g. `30_archived`)   |
| `is_fake`       | bool    | Auto-created company project  |
| `db_status`     | string  | Database status               |
| `kind`          | string  | Project kind (rarely used)    |
| `url`           | string  | Associated URL                |

The `is_fake` field marks auto-created projects associated
with a company; these are hidden in the project listing UI.


# README

LSProject
=========

- manages the project table

DB Fields
=========
  project_id
  object_version
  owner_id
  team_id
  number      [string!]
  name
  start_date
  end_date
  status      (eg 30_archived)
  is_fake     (bool) - set for projects associated with companies
  db_status   (eg inserted,updated,archived)
  kind        (usually empty)
  url

Project 'kind' is not really used in OGo. The SkyProjectDataSource can filter
on it, buts thats it. No (core) OGo component currently sets the kind.
'common', 'private' etc are "derived attributes" and not stored in the
table.

The is_fake field is used for auto-created projects associated with a company,
projects with this flag set are hidden in the regular OGo project app.

Notes
=====
project::get-comment is called in:
WebUI/Project/LSWProject/LSWProjectViewer.m
WebUI/Project/LSWProject/LSWProjectEditor.m
WebUI/Project/LSWProject/SkyProjectInlineViewer.m
