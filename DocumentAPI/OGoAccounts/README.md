# OGoAccounts - Account and Team Documents

OGoAccounts provides document wrappers around account
and team records from the Logic layer.

**Built as:** `libOGoAccounts` (shared library) and
`OGoAccounts.ds` (datasource bundle)


## Dependencies

- OGoDocuments
- OGoBase
- LSFoundation (Logic layer)


## Key Classes

| Class | Purpose |
|-------------------------------|-------------------------------|
| `SkyAccountDocument`          | Document for an account       |
| `SkyTeamDocument`             | Document for a team           |
| `SkyAccountDataSource`        | DataSource for accounts       |
| `SkyTeamDataSource`           | DataSource for teams          |
| `SkyMemberDataSource`         | DataSource for team members   |
| `SkyAccountTeamsDataSource`   | DataSource for account teams  |
| `SkyAccountsBundleManager`    | Bundle principal class        |


## SkyAccountDocument

Represents a login account with properties:

- `firstname`, `middlename`, `name`, `nickname`
- `login`, `password`, `number`, `objectVersion`
- `isLocked`, `isExtraAccount`

Provides `teamsDataSource` for fetching account's teams.


## SkyTeamDocument

Represents a team/group with membership tracking and
team-specific properties.
