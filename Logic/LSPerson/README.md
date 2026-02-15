# LSPerson - Person Management

LSPerson manages individual person (contact) records.
Persons can belong to enterprises, be assigned to
projects, have telephone numbers, addresses, and
extended attributes. Persons can be converted to
accounts.

**Built as:** `LSPerson.cmd` (command bundle)


## Dependencies

- LSFoundation
- LSAddress
- LSSearch
- NGiCal


## Registered Commands

| Command | Description |
|-----------------------------------|--------------------|
| `person::new`                     | Create person      |
| `person::set`                     | Update person      |
| `person::get`                     | Fetch persons      |
| `person::delete`                  | Delete person      |
| `person::get-comment`             | Get comment        |
| `person::check-permission`        | Check permissions  |
| `person::enterprises`             | Get enterprises    |
| `person::set-enterprise`          | Set enterprise     |
| `person::get-telephones`          | Get phone numbers  |
| `person::get-extattrs`            | Extended attrs     |
| `person::get-projects`            | Get all projects   |
| `person::get-assigned-projects`   | Assigned projects  |
| `person::assign-projects`         | Assign projects    |
| `person::toaccount`               | Convert to account |
| `person::change-login-status`     | Login status       |
| `person::get-by-globalid`         | Fetch by GID       |
| `person::full-search`             | Full-text search   |
| `person::extended-search`         | Extended search    |
| `person::qsearch`                 | Quick search       |
