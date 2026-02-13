# WebUI - Web User Interface

WebUI provides the HTML-based web interface for OGo.
It is built as a SOPE (GNUstep web framework) application
with modular `.lso` bundles that are loaded at runtime.

**Built as:** `ogo-webui` (executable) plus `.lso`
bundles


## Dependencies

- OGoFoundation (shared library)
- DocumentAPI (all modules)
- Logic (all command bundles)
- SOPE 4.5+ (NGObjWeb, WEExtensions)


## Architecture

```
ogo-webui (Main/)
    ↓ loads
OGoFoundation (libOGoFoundation)
    ↓ loads
*.lso bundles (Contact, Scheduler, Project, ...)
    ↓ uses
DocumentAPI → Logic → Database
```

Each `.lso` bundle registers a module manager that
provides UI components (viewers, editors, lists) for
its domain.


## Module Overview

### Core

| Directory | Bundle | Purpose |
|-------------------|----------------------|------------------------|
| `OGoFoundation/`  | `libOGoFoundation`   | Base framework         |
| `Main/`           | `ogo-webui`          | Application entry point|
| `Resources/`      | -                    | Localization strings   |
| `Templates/`      | -                    | HTML templates (.wox)  |

### Common UI Components

| Directory | Bundle | Purpose |
|---------------------------|----------------------|------------------------|
| `Common/BaseUI/`          | `BaseUI.lso`         | Legacy 3.x components  |
| `Common/OGoUIElements/`   | `OGoUIElements.lso`  | Modern 4.x components  |
| `Common/PropertiesUI/`    | `PropertiesUI.lso`   | Object properties      |
| `Common/RelatedLinksUI/`  | `RelatedLinksUI.lso` | Object linking         |

### Contact Management

| Directory | Bundle | Purpose |
|---------------------------|----------------------|------------------------|
| `Contact/AddressUI/`      | `AddressUI.lso`      | Shared contact UI      |
| `Contact/PersonsUI/`      | `PersonsUI.lso`      | Person management      |
| `Contact/EnterprisesUI/`  | `EnterprisesUI.lso`  | Enterprise management  |
| `Contact/LDAPAccounts/`   | `LDAPAccounts.lso`   | LDAP integration       |

### Calendar

| Directory | Bundle | Purpose |
|----------------------------------|----------------------------|-----------------|
| `Scheduler/LSWScheduler/`        | `LSWScheduler.lso`         | Legacy scheduler|
| `Scheduler/OGoScheduler/`        | `OGoScheduler.lso`         | Modern scheduler|
| `Scheduler/OGoSchedulerViews/`   | `OGoSchedulerViews.lso`    | Calendar views  |
| `Scheduler/OGoSchedulerDock/`    | `OGoSchedulerDock.lso`     | Dock widget     |
| `Scheduler/OGoResourceScheduler/`| `OGoResourceScheduler.lso` | Resource views  |

### Projects and Documents

| Directory | Bundle | Purpose |
|-------------------------------|-------------------------|-----------------|
| `Project/OGoProject/`         | `OGoProject.lso`        | Main project UI |
| `Project/OGoNote/`            | `OGoNote.lso`           | Note management |
| `Project/OGoDocInlineViewers/`| `OGoDocInlineViewers.lso`| Doc viewers    |
| `Project/OGoProjectZip/`     | `OGoProjectZip.lso`     | Zip/tar support |
| `Project/OGoProjectInfo/`    | `OGoProjectInfo.lso`    | Dock links      |
| `Project/LSWProject/`        | `LSWProject.lso`        | Legacy project  |
| `Project/OGoSoProject/`      | `OGoSoProject.lso`      | SOAP objects    |

### Email

| Directory | Bundle | Purpose |
|-------------------------------|-------------------------|-----------------|
| `Mailer/OGoWebMail/`         | `OGoWebMail.lso`        | IMAP webmail    |
| `Mailer/OGoMailViewers/`     | `OGoMailViewers.lso`    | MIME viewers    |
| `Mailer/OGoMailEditor/`      | `OGoMailEditor.lso`     | Mail compose    |
| `Mailer/OGoMailInfo/`        | `OGoMailInfo.lso`       | Dock widget     |
| `Mailer/OGoMailFilter/`      | `OGoMailFilter.lso`     | Mail filters    |
| `Mailer/OGoRecipientLists/`  | `OGoRecipientLists.lso` | Mailing lists   |
| `Mailer/LSWMail/`            | `LSWMail.lso`           | Legacy mail     |

### Other

| Directory | Bundle | Purpose |
|--------------------|----------------------|------------------------|
| `AdminUI/`         | `AdminUI.lso`        | Administration         |
| `PreferencesUI/`   | `PreferencesUI.lso`  | User preferences       |
| `JobUI/`           | `JobUI.lso`          | Task management        |
| `NewsUI/`          | `NewsUI.lso`         | News/announcements     |
| `GroupsUI/`        | `GroupsUI.lso`       | Groups/teams           |
| `HelpUI/`          | `HelpUI.lso`         | Help system            |
| `RegUI/`           | `RegUI.lso`          | Registration           |
| `CTI/`             | CTI bundles          | Telephony integration  |


## Key Patterns

### Module Manager

Each bundle has a principal class inheriting from
`OGoModuleManager` that registers components on load.

### Component Base Class

All UI components inherit from `OGoComponent`
(via `WOComponent`), providing:
- Config handler access
- Label handler (localization)
- Session-based command execution

### Viewer/Editor Pattern

Most domains implement:
- `*Viewer` - Read-only display
- `*Editor` - Edit form
- `*List` - Browse/list view
- `*Wizard` - Creation wizard
