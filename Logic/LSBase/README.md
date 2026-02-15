# LSBase - Generic Base Commands

LSBase provides generic commands shared across modules,
including object logging, commenting, property management,
object linking, and RSS feed generation.

**Built as:** `libLSBase` (shared library) and
`LSBase.cmd` (command bundle)


## Dependencies

- LSFoundation


## Registered Commands

| Command | Description |
|-----------------------------------|-----------------------|
| `object::get-by-globalid`         | Fetch by global IDs   |
| `object::add-log`                 | Add log entry         |
| `object::get-logs`                | Get log entries       |
| `object::delete-log`              | Delete log entry      |
| `object::get-all-logs`            | Get all logs          |
| `object::set-comment`             | Set object comment    |
| `object::get-comment`             | Get object comment    |
| `object::get-rss-of-type`         | Get RSS feed          |
| `object::get-links`               | Get object links      |
| `object::create-link`             | Create object link    |
| `object::delete-link`             | Delete object link    |
| `object::get-link-targets`        | Get link targets      |
| `object::get-by-url`              | Find object by URL    |
| `session::log`                    | Session logging       |
