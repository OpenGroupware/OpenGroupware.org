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


# README

LSFoundation
============

LSFoundation is the very core library for accessing OpenGroupware.org
business logic.

Defaults
========

LSSessionChannelTimeOut  300 (s)
SkyCommandProfileEnabled YES|NO
SkyCommandProfileName    /tmp/cmd-log
LSProfileCommands        YES|NO
LSDebuggingEnabled       YES|NO
LSAskAtTxBegin           YES|NO   (for debugging, prompts/blocks on the shell!)
LSDBFetchRelationCommand_MAX_SEARCH_COUNT 200

MinutesBetweenFailedLogins     15
HandleFailedAuthorizations     NO
FailedLoginCount               5
FailedLoginLockInfoMailAddress root

LSAuthLDAPServer
LSAuthLDAPServerRoot
LSAuthLDAPServerPort           389

LSUseLowercaseLogin            NO
AllowSpacesInLogin             NO

LSAdaptor                      PostgreSQL
LSConnectionDictionary
LSModelName

UseSkyrixLoginForImap          NO

SkyAccessManagerDebug          NO
SkyObjectPropertyManagerDebug  NO


Access Rules
============
(by JR)

access permissions for persons / accounts / companies


- root is always allowed to do everything

- if nothing is set, everyone may read and write. As soon as an ACL is
  set on an object, access is forbidden for everyone who is not listed

- everyone who has write access may set the ACL.
- you cannot remove permissions from the owner.

When read permissions are lacked the objects won't be fetched. This way it can
happen that there are appointments without participants.

The permissions are checked in the command objects, due to this it can happen
that edit forms can be reached (due to still available buttons) but that a
save fails due to missing permissions.
=> TODO: this would be a bug

IsReadOnly/IsPrivate are overridden in case an ACL is set.

The own account record can always be read/written.
