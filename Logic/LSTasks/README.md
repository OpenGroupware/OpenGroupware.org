# LSTasks - Task/Job Management

LSTasks manages tasks (called "jobs" internally) with
hierarchical structures, delegation, status tracking,
and project associations. Tasks can be assigned to persons
or teams, have a lifecycle with defined status transitions,
and support job history for audit trails.

**Built as:** `LSTasks.cmd` (command bundle)


## Dependencies

- LSFoundation
- LSSearch


## Registered Commands

### `job` Domain

#### CRUD and Lifecycle

| Command | Description |
|-------------------------------|---------------------------|
| `job::new`                    | Create task               |
| `job::set`                    | Update task               |
| `job::get`                    | Fetch tasks               |
| `job::delete`                 | Delete task               |
| `job::jobaction`              | Execute status transition |
| `job::import`                 | Import tasks (CSV)        |
| `job::resume`                 | Resume archived task      |
| `job::get-by-globalid`        | Fetch by global ID        |

#### Relationship Queries

| Command | Description |
|-------------------------------|---------------------------|
| `job::setcreator`             | Fetch creator (Person)    |
| `job::setexecutant`           | Fetch executant (Person)  |
| `job::setexecutantteam`       | Fetch executant (Team)    |
| `job::setactor`               | Fetch last actor (Person) |
| `job::get-job-executants`     | Get all executants        |
| `job::get-job-history`        | Get history entries       |
| `job::get-job-history-info`   | Get history info          |
| `job::get-project`            | Fetch associated project  |
| `job::getparentjobs`          | Get parent jobs in tree   |
| `job::get-jobid-tree`         | Get full job ID tree      |

#### Filtered Fetch Commands

| Command | Description |
|-------------------------------|---------------------------|
| `job::get-todo-jobs`          | Fetch TODO items          |
| `job::get-private-jobs`       | Fetch private tasks       |
| `job::get-archived-jobs`      | Fetch archived tasks      |
| `job::get-delegated-jobs`     | Fetch delegated tasks     |
| `job::get-executant-jobs`     | Fetch by executant        |
| `job::get-project-jobs`       | Fetch by project          |
| `job::filter-todolist`        | Filter TODO list          |
| `job::filter-delegatedjobs`   | Filter delegated tasks    |
| `job::filter-archivedjobs`    | Filter archived tasks     |

#### Project Association

| Command | Description |
|-------------------------------|---------------------------|
| `job::assign-to-project`      | Link task to project      |
| `job::detach-from-project`    | Unlink from project       |
| `job::remove-waste-jobs`      | Remove orphaned tasks     |

#### Search

| Command | Description |
|-------------------------------|---------------------------|
| `job::extended-search`        | Extended search           |
| `job::qsearch`                | Qualifier search          |
| `job::criteria-search`        | Criteria-based search     |

#### RSS Feeds

| Command | Description |
|-------------------------------|---------------------------|
| `job::get-delegated-rss`      | Delegated actions RSS     |
| `job::get-delegated-tasks-rss`| Delegated tasks RSS       |
| `job::get-todo-rss`           | TODO actions RSS          |
| `job::get-todo-tasks-rss`     | TODO tasks RSS            |
| `job::get-project-rss`        | Project task actions RSS  |

### `jobhistory` Domain (Private)

| Command | Description |
|-------------------------------|---------------------------|
| `jobhistory::new`             | Create history entry      |
| `jobhistory::set`             | Update history entry      |
| `jobhistory::get`             | Fetch history entries     |
| `jobhistory::delete`          | Delete history entry      |

### `jobresourceassignment` / `jobassignment` Domains

Standard CRUD for task resource and assignment join records.


## Task Status Lifecycle

Tasks follow a defined status progression managed by
`LSJobActionCommand`:

```
00_created → 05_accepted → 20_processing → 25_done
                                             ↓
    02_rejected ←                      30_archived
                                             ↓
                                       27_reactivated
```

Additional statuses: `10_commented`, `15_divided`.


## Key Classes

| Class | Purpose |
|---------------------------------------|---------------------------|
| `LSNewJobCommand`                     | Create task               |
| `LSSetJobCommand`                     | Update task               |
| `LSDeleteJobCommand`                  | Delete task               |
| `LSJobActionCommand`                  | Status transitions        |
| `LSImportJobCommand`                  | CSV import                |
| `LSGetParentJobsCommand`             | Hierarchy navigation      |
| `LSFetchJobIdTreeCommand`            | Full tree fetching        |
| `LSAllSubJobsDoneJobCommand`         | Check sub-task completion |
| `OGoJobAccessHandler`                | Access control handler    |
| `LSCriteriaSearchTaskCommand`        | Criteria search           |
| `LSQualifierSearchTaskCommand`       | Qualifier search          |
