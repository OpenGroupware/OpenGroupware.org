# ZideStore - WebDAV/CalDAV/CardDAV Server

ZideStore is a WebDAV frontend daemon providing CalDAV,
CardDAV, and iCalendar access to OGo data. It is
compatible with Evolution, Apple Calendar, and other
WebDAV/CalDAV clients.

**Built as:** `ogo-zidestore` (daemon executable)


## Dependencies

- ZSBackend, ZSFrontend (internal libraries)
- LSFoundation, GDLAccess
- NGObjWeb, NGiCal, NGMime, NGLdap
- SOPE framework


## Architecture

```
WebDAV/CalDAV/CardDAV Client
         ↓  (HTTP)
ogo-zidestore (SoApplication)
         ↓
SoObjects (mediators)
         ↓
   ┌─────┴─────┐
ZSFrontend   ZSBackend
   │             │
   └─────┬─────┘
         ↓
  Logic / DocumentAPI / Database
```


## Source Structure

### Main/ - Application Entry Point

| File | Purpose |
|---------------------------|-------------------------------|
| `ZideStore.m`             | SoApplication subclass        |
| `SxAuthenticator.m`       | Authentication handler        |

### ZSBackend/ - Backend Library

`libZSBackend` encapsulates business logic and SQL
queries:

| Class | Purpose |
|---------------------------|-------------------------------|
| `SxBackendMaster`         | Master backend controller     |
| `SxAptManager`            | Appointment management        |
| `SxAptManager+iCal`       | iCalendar conversion          |
| `SxContactManager`        | Contact management            |
| `SxTaskManager`           | Task management               |
| `SxFreeBusyManager`       | Free/busy calculation         |
| `SxSQLQuery`              | SQL query builder             |

### ZSFrontend/ - Frontend Library

`libZSFrontend` handles WebDAV protocol:

| Class | Purpose |
|---------------------------|-------------------------------|
| `SxFolder`                | Base folder (WebDAV collection)|
| `SxFolder+DAV`            | WebDAV protocol support       |
| `SxObject`                | Base WebDAV resource          |
| `SxDavAction`             | WebDAV action handler         |
| `SxUserFolder`            | User home folder              |
| `SxPublicFolder`          | Public shared folder          |
| `SxRenderer`              | Response rendering            |

Resources: `E2KAttrMap.plist`, `MAPIPropMap.plist`,
`DAVPropSets.plist` for Exchange/MAPI compatibility.

### SoObjects/ - SOPE Controller Objects

Mediators between frontend and backend, organized as
subprojects:

| Subproject | Purpose |
|---------------------------|-------------------------------|
| `ZSCommon/`               | Common SOPE objects           |
| `ZSAppointments/`         | Calendar SOPE objects         |
| `ZSContacts/`             | Contact SOPE objects          |
| `ZSProjects/`             | Project SOPE objects          |
| `ZSTasks/`                | Task SOPE objects             |
| `ZSResources/`            | Resource SOPE objects         |
| `Mailer/`                 | Mail/IMAP SOPE objects        |
| `Sieve/`                  | Mail filtering objects        |

### Protocols/ - Additional Protocol Handlers

| Subproject | Purpose |
|---------------------------|-------------------------------|
| `EvoConnect/`             | Evolution connectivity        |
| `GData/`                  | Google Data protocol          |
| `RSS/`                    | RSS feed protocol             |
| `Blogger/`                | Blogger protocol              |
| `WCAP/`                   | Wireless Calendar Access      |
| `zOGI/`                   | zOGI protocol                 |


## iCalendar Access

Calendars are available at:
- `/skyrix/so/<user>/calendar.ics` (user calendar)
- Calendar folders expose `calendar.ics` and `ics`
  resources


## Key User Defaults

| Default | Description |
|---------------------------------|---------------------------|
| `SxAptFolder_MonthsIntoFuture`  | Fetch window (default 12) |
| `SxAptFolder_MonthsIntoPast`    | Fetch window (default 2)  |
| `SxCachePath`                   | Cache directory           |
| `ZLRefreshInterval`             | Refresh interval (2 min)  |
| `SxDebugAuthenticator`          | Debug authentication      |
| `SxDebugSQL`                    | Debug SQL queries         |
