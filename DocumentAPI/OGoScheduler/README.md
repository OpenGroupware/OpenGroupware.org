# OGoScheduler - Appointment Documents

OGoScheduler provides the document API for the OGo
scheduling/calendar module. It wraps appointment-related
Logic commands into document and datasource abstractions,
including support for recurring appointments, conflicts,
and holiday calculations.

**Built as:** `libOGoScheduler` (shared library) and
`OGoScheduler.ds` (datasource bundle)


## Dependencies

- OGoDocuments
- OGoBase
- LSFoundation (Logic layer, LSScheduler)


## Key Classes

| Class | Purpose |
|--------------------------------------|------------------------|
| `SkyAppointmentDocument`             | Appointment document   |
| `SkyAppointmentDataSource`           | Appointment datasource |
| `SkyAppointmentQualifier`            | Appointment qualifier  |
| `SkyAptDataSource`                   | Base apt datasource    |
| `SkyAptCompoundDataSource`           | Compound datasource    |
| `SkySchedulerConflictDataSource`     | Conflict datasource    |
| `SkyHolidayCalculator`               | Holiday calculation    |
| `SkySchedulerBundleManager`          | Bundle principal class |


## SkyAppointmentDocument

Represents a calendar appointment with properties:

- `startDate`, `endDate`, `cycleEndDate`
- `title`, `location`, `aptType`
- `type` (repetition type for recurring)
- `comment`, `notificationTime`, `objectVersion`
- `participants` (array), `resourceNames`
- `writeAccessList`, `writeAccessMembers`,
  `accessTeamId`, `permissions`
- `owner` (SkyDocument),
  `parentDate` (for recurring series)
- `saveCycles` (BOOL, default YES)

Status: `isEdited`, `isValid`, `isComplete`, `isNew`.


## SkyAppointmentQualifier

Specialized qualifier for appointment queries with
timezone support and date-based filtering. Used with
`SkyAppointmentDataSource` via `EOFetchSpecification`.


## Resources

- `Holidays.plist` - Holiday definitions used by
  `SkyHolidayCalculator`
- `Defaults.plist` - Default configuration
