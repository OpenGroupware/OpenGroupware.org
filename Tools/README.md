# Tools - Command-Line Utilities

Tools provides command-line utilities for managing OGo
data and configuration without the web interface.

**Built as:** Individual executables (GNUstep tools)


## Dependencies

- LSFoundation, GDLAccess
- OGoDocuments, OGoProject, OGoScheduler
- NGMime, NGiCal, NGLdap


## Account Management

| Tool | Purpose |
|--------------------------|--------------------------------|
| `ogo-account-add`        | Add user accounts              |
| `ogo-account-del`        | Delete user accounts           |
| `ogo-account-list`       | List login names               |

## Data Management

| Tool | Purpose |
|--------------------------|--------------------------------|
| `ogo-runcmd`             | Execute Logic commands via CLI |
| `ogo-defaults`           | Read/write user defaults       |
| `ogo-list-acls`          | Display access control lists   |
| `ogo-check-permission`   | Check user permissions         |
| `ogo-check-aptconflicts` | Verify appointment conflicts   |
| `ogo-prop-list`          | List object properties         |
| `ogo-prop-set`           | Set object properties          |

## Project Management

| Tool | Purpose |
|--------------------------|--------------------------------|
| `ogo-project-export`     | Export project data            |
| `ogo-project-import`     | Import project data            |
| `ogo-project-list`       | List projects                  |

## Contact and Search

| Tool | Purpose |
|--------------------------|--------------------------------|
| `ogo-qsearch-persons`    | Quick search for persons       |
| `ogo-qsearch-enterprises`| Quick search for enterprises   |
| `ogo-qsearch-tasks`      | Quick search for tasks         |
| `ogo-vcard-get`           | Export contacts as vCard       |
| `ogo-vcard-put`           | Import vCard contacts          |

## Mail and Notifications

| Tool | Purpose |
|--------------------------|--------------------------------|
| `skyaptnotify`           | Appointment email/SMS reminders|
| `sky_install_sieve`      | Install Sieve mail filters     |
| `sky_send_bulk_messages`  | Send bulk email messages       |
| `ogo-instfilter-procmail`| Install procmail filters       |
| `ogo-jobs-export`         | Export task/job data           |


## Base Classes

- `SkyTool` - Base class for Sky* tools, handles OGo
  context setup and authentication
- `NGUnixTool` - Unix tool utilities (zip handling)
