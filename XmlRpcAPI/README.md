# XmlRpcAPI - XML-RPC Protocol Access

XmlRpcAPI provides a full-featured XML-RPC server for
remote API access to all OGo data and operations. It
implements the SOPE `WODirectAction` pattern to expose
contacts, appointments, projects, tasks, and accounts
via XML-RPC.

**Built as:** `ogo-xmlrpcd` (daemon executable)


## Dependencies

- OGoContacts, OGoScheduler, OGoJobs, OGoAccounts,
  OGoProject, OGoDocuments
- LSFoundation, GDLAccess
- NGXmlRpc, NGObjWeb (SOPE RPC framework)
- NGiCal, NGMime, NGLdap


## Architecture

The daemon runs as a standalone SOPE application:

```
XML-RPC Client
     ↓  (HTTP POST)
ogo-xmlrpcd (Application)
     ↓
DirectAction+<Domain>.m  (action handler)
     ↓
DocumentAPI / Logic Commands
```


## Source Structure

### Core Application

| File | Purpose |
|---------------------------|-------------------------------|
| `xmlrpcd.m`              | Main entry point              |
| `Application.m`          | WOApplication subclass        |
| `Session.m`              | Session management            |

### Actions.subproj - API Endpoints

Each domain has a DirectAction category:

| File | Domain |
|-------------------------------|------------------------|
| `DirectAction+Person.m`      | Person contacts        |
| `DirectAction+Enterprise.m`  | Enterprise/companies   |
| `DirectAction+Account.m`     | Account management     |
| `DirectAction+Appointment.m` | Calendar/appointments  |
| `DirectAction+Team.m`        | Team management        |
| `DirectAction+Job.m`         | Tasks/jobs             |
| `DirectAction+Project.m`     | Projects               |
| `DirectAction+Resource.m`    | Resources              |
| `DirectAction+Link.m`        | Object links           |
| `DirectAction+Mails.m`       | Mail operations        |
| `DirectAction+Defaults.m`    | User defaults          |
| `DirectAction+System.m`      | System operations      |
| `DirectAction+Generic.m`     | Generic CRUD           |
| `DirectAction+Fault.m`       | Error handling         |

### XmlRpcCoding.subproj - Encoding

Document-to-XML-RPC encoding for each entity type:

- `SkyPersonDocument+XmlRpcCoding.m`
- `SkyEnterpriseDocument+XmlRpcCoding.m`
- `SkyAccountDocument+XmlRpcCoding.m`
- `SkyAppointmentDocument+XmlRpcCoding.m`
- `SkyTeamDocument+XmlRpcCoding.m`
- `SkyJobDocument+XmlRpcCoding.m`
- `SkyProject+XmlRpcCoding.m`
- `SkyAddressDocument+XmlRpcCoding.m`


## Fault Codes

| Code | Constant | Meaning |
|------|--------------------------------------|----------------------|
| 1    | `XMLRPC_FAULT_INVALID_PARAMETER`     | Invalid parameter    |
| 2    | `XMLRPC_FAULT_MISSING_PARAMETER`     | Missing parameter    |
| 3    | `XMLRPC_FAULT_MISSING_CONTEXT`       | No context           |
| 4    | `XMLRPC_FAULT_INVALID_RESULT`        | Invalid result       |
| 5    | `XMLRPC_FAULT_INTERNAL_ERROR`        | Internal error       |
| 6    | `XMLRPC_FAULT_LOCK_ERROR`            | Lock conflict        |
| 7    | `XMLRPC_MISSING_PERMISSIONS`         | Permission denied    |
| 404  | `XMLRPC_FAULT_NOT_FOUND`             | Object not found     |


## API Documentation

The `Documentation/` subdirectory contains detailed API
docs for each domain:

- `README.person` - Person/contact API
- `README.enterprise` - Enterprise API
- `README.appointment` - Calendar API
- `README.project` - Project API
- `README.job` - Task API
- `README.account` - Account API
- `README.fetchspec` - Query format
- `README.defaults` - User defaults API
- `README.system` - System operations
