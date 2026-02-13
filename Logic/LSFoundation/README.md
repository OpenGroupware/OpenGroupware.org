# LSFoundation - Command Infrastructure

LSFoundation is the core library for the OGo business
logic. It provides base command classes, the command
context, command factory, transaction management, and
access control infrastructure. All other Logic modules
depend on it.

**Built as:** `libLSFoundation` (shared library)


## Command Lifecycle

```
runInContext:
  _prepareForExecutionInContext:
  _executeInContext:
  _executeCommandsInContext:
  _validateInContext:
```


## Key Classes

### Command Base Classes

| Class | Purpose |
|-----------------------------|------------------------------|
| `LSBaseCommand`             | Base for all commands         |
| `LSDBObjectBaseCommand`     | Base for database commands    |
| `LSDBObjectGetCommand`      | Fetch/search objects          |
| `LSDBObjectSetCommand`      | Update objects                |
| `LSDBObjectNewCommand`      | Create objects                |
| `LSDBObjectDeleteCommand`   | Delete objects                |
| `LSDBFetchRelationCommand`  | Fetch related objects         |
| `LSGetObjectForGlobalIDs`   | Fetch by global IDs           |

### Context & Factory

| Class | Purpose |
|-----------------------------|------------------------------|
| `LSCommandContext`          | Execution context, login,    |
|                             | transactions, command runner  |
| `LSBundleCmdFactory`       | Bundle-based command factory  |
| `OGoContextManager`        | Context lifecycle, DB connect |
| `LSModuleManager`          | Module loading                |

### Access Control

| Class | Purpose |
|-----------------------------|------------------------------|
| `OGoAccessManager`         | Access control manager        |
| `OGoAccessHandler`         | Access handler base class     |

### Property & Type Management

| Class | Purpose |
|-----------------------------|------------------------------|
| `SkyObjectPropertyManager` | Extended property management  |
| `OGoObjectLinkManager`     | Object linking                |
| `LSTypeManager`            | Type management               |


## Access Rules

- Root is always allowed to do everything
- If no ACL is set, everyone may read and write
- Once an ACL is set, access is forbidden for everyone
  not listed
- Write access includes the ability to set ACLs
- Own account record can always be read/written


## User Defaults

| Key | Default |
|-----------------------------|------------------------------|
| `LSSessionChannelTimeOut`   | 300 (seconds)                |
| `LSAdaptor`                 | PostgreSQL                   |
| `LSConnectionDictionary`    | (connection parameters)      |
| `LSModelName`               | (model file name)            |
| `LSDebuggingEnabled`        | NO                           |
| `LSAuthLDAPServer`          | (LDAP server for auth)       |
| `LSUseLowercaseLogin`       | NO                           |
| `SkyAccessManagerDebug`     | NO                           |
