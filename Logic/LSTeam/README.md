# LSTeam - Team/Group Management

LSTeam manages teams (groups of accounts). Teams can
have members, be assigned permissions, and be expanded
to resolve all contained accounts.

**Built as:** `LSTeam.cmd` (command bundle)


## Dependencies

- LSFoundation
- LSAddress


## Registered Commands

| Command | Description |
|-------------------------------|--------------------------|
| `team::new`                   | Create team              |
| `team::set`                   | Update team              |
| `team::get`                   | Fetch teams              |
| `team::delete`                | Delete team              |
| `team::get-by-globalid`       | Fetch by global ID       |
| `team::get-all`               | Get all teams            |
| `team::get-by-login`          | Find team by login       |
| `team::check-permission`      | Check permissions        |
| `team::members`               | Get team members         |
| `team::setmembers`            | Set team members         |
| `team::expand`                | Expand to accounts       |
| `team::resolveaccounts`       | Resolve member accounts  |
| `team::extended-search`       | Extended search          |
