# LSEnterprise - Enterprise Management

LSEnterprise manages enterprise (organization/company)
records. Enterprises can have members (persons), be
associated with projects, and have telephone numbers,
addresses, and extended attributes.

**Built as:** `LSEnterprise.cmd` (command bundle)


## Dependencies

- LSFoundation
- LSAddress
- LSSearch


## Registered Commands

| Command | Description |
|-----------------------------------|--------------------|
| `enterprise::new`                 | Create enterprise  |
| `enterprise::set`                 | Update enterprise  |
| `enterprise::get`                 | Fetch enterprises  |
| `enterprise::delete`              | Delete enterprise  |
| `enterprise::get-comment`         | Get comment        |
| `enterprise::check-permission`    | Check permissions  |
| `enterprise::members`             | Get members        |
| `enterprise::setmembers`          | Set members        |
| `enterprise::get-telephones`      | Get phone numbers  |
| `enterprise::get-extattrs`        | Extended attrs     |
| `enterprise::get-projects`        | Get projects       |
| `enterprise::assign-projects`     | Assign projects    |
| `enterprise::get-by-globalid`     | Fetch by GID       |
| `enterprise::full-search`         | Full-text search   |
| `enterprise::extended-search`     | Extended search    |
| `enterprise::qsearch`             | Quick search       |
