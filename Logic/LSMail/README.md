# LSMail - Email Delivery (Mostly Deprecated)

LSMail provides the `email::deliver` command for sending
email. The bundle is mostly deprecated; it was originally
used for database-based mail storage which has been
replaced with IMAP4 mail servers since SKYRiX 4.x.

**Built as:** `LSMail.cmd` (command bundle)


## Dependencies

- LSFoundation
- LSSearch
- NGMime (MIME message handling)
- NGMail (mail utilities)


## Registered Commands

| Command | Class | Description |
|-------------------|--------------------------|-----------------|
| `email::deliver`  | `LSMailDeliverCommand`   | Send email      |


## Key Classes

| Class | Purpose |
|--------------------------|------------------------------|
| `LSMailDeliverCommand`   | Email delivery via SMTP      |
| `LSMailFunctions`        | Mail utility functions       |


## Source Structure

A minimal module with 3 source files:

- `LSMailCommands.m` - Command bundle registration
- `LSMailDeliverCommand.m` - SMTP delivery command
- `LSMailFunctions.m` - Shared mail utility functions
