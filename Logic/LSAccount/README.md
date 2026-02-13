# LSAccount - Account Management

LSAccount manages login accounts (users who can
authenticate to the system). Accounts are a subset of
person records with additional login credentials.

**Built as:** `LSAccount.cmd` (command bundle)


## Dependencies

- LSFoundation
- LSAddress


## Registered Commands

| Command | Description |
|---------------------------------|------------------------|
| `account::new`                  | Create account         |
| `account::set`                  | Update account         |
| `account::get`                  | Fetch accounts         |
| `account::delete`               | Delete account         |
| `account::login`                | Authenticate           |
| `account::check-login`          | Validate credentials   |
| `account::get-by-globalid`      | Fetch by global ID     |
| `account::teams`                | Get account's teams    |
| `account::setgroups`            | Assign to groups       |
| `account::check-permission`     | Check permissions      |
| `account::get-comment`          | Get account comment    |
| `account::change-login-status`  | Enable/disable login   |
| `account::full-search`          | Full-text search       |
| `account::extended-search`      | Extended search        |
| `account::qsearch`              | Quick search           |
