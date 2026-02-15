# OGoFoundation - WebUI Base Framework

OGoFoundation is the shared library that all WebUI
bundles link against. It provides base classes, session
management, navigation, and common infrastructure for
the web interface.

**Built as:** `libOGoFoundation` (shared library)


## Dependencies

- SOPE (NGObjWeb, WEExtensions)
- DocumentAPI (OGoDocuments, OGoProject)
- LSFoundation


## Key Classes

### Application and Session

| Class | Purpose |
|---------------------------|-------------------------------|
| `OGoSession`              | Session with command context  |
| `OGoNavigation`           | Page navigation stack         |
| `OGoClipboard`            | Transfer pasteboard           |
| `OGoContentPage`          | Base content page             |
| `OGoEditorPage`           | Base editor page              |

### Component Infrastructure

| Class | Purpose |
|---------------------------|-------------------------------|
| `OGoComponent`            | Base UI component             |
| `OGoModuleManager`        | Bundle registration           |
| `LSWContentPage`          | Content page (legacy)         |
| `LSWEditorPage`           | Editor page (legacy)          |
| `LSWViewerPage`           | Viewer page (legacy)          |
| `LSWComponent`            | Base component (legacy)       |

### Utilities

| Class | Purpose |
|---------------------------|-------------------------------|
| `OGoHelpManager`          | Help system integration       |
| `LSWTreeState`            | Tree/hierarchy state          |
| `LSWLabelHandler`         | Localization labels           |
| `LSWConfigHandler`        | Configuration handling        |
| `LSStringFormatter`       | String formatting             |
| `SkyMoneyFormatter`       | Currency formatting           |

### Extensions

| Category | Purpose |
|-------------------------------|---------------------------|
| `NSObject+Commands`           | Command execution helpers |
| `WOComponent+Navigation`      | Navigation helpers        |
| `WOComponent+config`          | Configuration access      |


## Component Lifecycle

OGoFoundation manages the SOPE component lifecycle:

1. **syncAwake** - Component awakens from request
2. **Action handling** - User interaction
3. **Template rendering** - HTML generation
4. **syncSleep** - Component goes to sleep

Components access the Logic layer through the session's
`LSCommandContext`.


# README

OGoFoundation
=============

[explain more]

- generic SKYRiX objects/classes, like
  - session class
  - navigation object
  - superclasses for editors, viewers, pages
  - configuration handler
  - label processors (localization)
  - various formatters

Defaults
========

OGoDebugNavigation - bool - debug page navigation object
OGoProfileConfig   - bool - profile session config object
OGoProfileSleep	   - bool - profile -sleep method
OGoDebugConfig     - bool - debug session config object
OGoDebugPageCache  - bool - debug session page cache

SkyMaxFavoritesCount - num[def:5]
SkyMaxNavLabelLength - num[def:32]
SkyLanguages         - array

OGoDateFormat
OGoTimeFormat
OGoDateTimeFormat
OGoDateTimeTZFormat
OGoAMPMTimeFormat
OGoAMPMDateTimeFormat
OGoAMPMDateTimeTZFormat

LSWResourceManagerDebugEnabled

User Specific Defaults
======================

scheduler_AMPM_dates - bool
