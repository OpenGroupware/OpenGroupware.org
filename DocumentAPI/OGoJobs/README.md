# OGoJobs - Task/Job Documents

OGoJobs provides the document API for the OGo task
(job/todolist) module. It wraps job-related Logic
commands into document and datasource abstractions.

**Built as:** `libOGoJobs` (shared library) and
`OGoJobs.ds` (datasource bundle)


## Dependencies

- OGoDocuments
- OGoBase
- LSFoundation (Logic layer, LSTasks)


## Key Classes

| Class | Purpose |
|-------------------------------|-------------------------------|
| `SkyJobDocument`              | Task/job document             |
| `SkyJobHistoryDocument`       | Job history entry             |
| `SkyProjectJobDataSource`     | Jobs for a project            |
| `SkyPersonJobDataSource`      | Jobs for a person             |
| `SkySchedulerJobDataSource`   | Jobs for scheduler views      |
| `SkyJobHistoryDataSource`     | Job history datasource        |


## SkyJobDocument

Represents a task/job with properties:

- `name`, `startDate`, `endDate`
- `keywords`, `category`, `jobStatus`
- `priority`, `type`, `sensitivity`
- `comment`, `completionDate`, `percentComplete`
- `actualWork`, `totalWork`, `kilometers`
- `accountingInfo`, `associatedCompanies`,
  `associatedContacts`
- `creator`, `executor` (SkyDocuments)
- `isTeamJob` - Whether assigned to a team

Status tracking: `isEdited`, `isValid`, `isComplete`,
`isNew`.

Methods: `save`, `delete`, `reload`, `invalidate`,
`historyDataSource`.
