# LSSearch - Search Infrastructure

LSSearch provides the generic search infrastructure used
across OGo. It defines base classes for extended search,
full-text search, and qualifier-based search that entity
modules (LSPerson, LSEnterprise, etc.) extend with their
own search implementations.

**Built as:** `libLSSearch` (shared library) and
`LSSearch.cmd` (command bundle)


## Dependencies

- LSFoundation


## Registered Commands

| Command | Description |
|-----------------------------|------------------------------|
| `search::newrecord`         | Create search record         |
| `search::extendedsearch`    | Extended/structured search   |
| `search::fullsearch`        | Full-text search             |
| `search::qsearch`           | Quick qualifier search       |


## Key Classes

| Class | Purpose |
|-----------------------------|------------------------------|
| `LSExtendedSearchCommand`   | Extended search command       |
| `LSFullSearchCommand`       | Full-text search command      |
| `LSQualifierSearchCommand`  | Qualifier-based search        |
| `LSBaseSearch`              | Base search helper            |
| `LSExtendedSearch`          | Extended search implementation|
| `LSFullSearch`              | Full search implementation    |
| `LSGenericSearchRecord`     | Search record data holder     |
| `OGoSQLGenerator`           | SQL query generation          |
