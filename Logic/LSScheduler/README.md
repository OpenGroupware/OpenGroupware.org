# LSScheduler - Appointment and Calendar Management

LSScheduler manages appointments (dates), calendar
operations, resource allocation, participant management,
conflict detection, and cyclic (recurring) appointments.
It includes iCalendar/vEvent integration for interop with
external calendar clients.

**Built as:** `LSScheduler.cmd` (command bundle) and
`libOGoSchedulerTools` (shared library for cyclic date
calculations)


## Dependencies

- LSFoundation
- NGiCal (iCalendar support)


## Registered Commands

### `appointment` Domain

| Command | Description |
|---------------------------------------|---------------------------|
| `appointment::new`                    | Create appointment        |
| `appointment::set`                    | Update appointment        |
| `appointment::get`                    | Fetch appointments        |
| `appointment::delete`                 | Delete appointment        |
| `appointment::get-by-globalid`        | Fetch by global ID        |
| `appointment::access`                 | Check access rights       |
| `appointment::query`                  | Query appointments        |
| `appointment::get-appointments`       | Get account appointments  |
| `appointment::conflicts`              | Detect conflicts          |
| `appointment::proposal`               | Find free time slots      |
| `appointment::move`                   | Move appointment          |
| `appointment::set-participants`       | Set participants          |
| `appointment::list-participants`      | List participants         |
| `appointment::get-participants`       | Get participant details   |
| `appointment::intersection`           | Participant intersection  |
| `appointment::new-cyclic`             | Create recurring series   |
| `appointment::get-cyclic`             | Fetch cyclic appointments |
| `appointment::get-access-team-info`   | Get access team info      |
| `appointment::get-comments`           | Get appointment comments  |
| `appointment::get-comment`            | Get single comment        |
| `appointment::change-attendee-status` | Change attendee status    |
| `appointment::add-me`                 | Add self as participant   |
| `appointment::remove-me`             | Remove self               |
| `appointment::used-resources`         | Get used resources        |

#### iCalendar Integration

| Command | Description |
|---------------------------------------|---------------------------|
| `appointment::get-ical`               | Export as iCalendar       |
| `appointment::new-with-vevent`        | Create from vEvent        |
| `appointment::update-with-vevent`     | Update from vEvent        |
| `appointment::get-by-sourceurl`       | Fetch by source URL       |

#### Filter Commands

| Command | Description |
|---------------------------------------|---------------------------|
| `appointment::converttimezone`        | Convert time zones        |
| `appointment::filter-amdates`         | Filter AM appointments    |
| `appointment::filter-pmdates`         | Filter PM appointments    |
| `appointment::filter-dates`           | Filter weekday dates      |
| `appointment::filter-several-days`    | Filter multi-day dates    |
| `appointment::filter-absence`         | Filter absences           |
| `appointment::filter-staff`           | Filter by staff           |
| `appointment::filter-attendance`      | Filter by attendance      |
| `appointment::mondaysofyear`          | Get Mondays of year       |
| `appointment::months`                 | Get month boundaries      |

### `appointmentresource` Domain

| Command | Description |
|---------------------------------------|---------------------------|
| `appointmentresource::new`            | Create resource           |
| `appointmentresource::set`            | Update resource           |
| `appointmentresource::get`            | Fetch resources           |
| `appointmentresource::delete`         | Delete resource           |
| `appointmentresource::set-all`        | Set all resources         |
| `appointmentresource::extended-search`| Search resources          |
| `appointmentresource::get-by-globalid`| Fetch by global ID        |
| `appointmentresource::categories`     | Get resource categories   |

### `datecompanyassignment` Domain (Private)

Standard CRUD for participant assignment join records.


## Key Classes

| Class | Purpose |
|----------------------------------------------|---------------------------|
| `LSNewAppointmentCommand`                    | Create appointment        |
| `LSSetAppointmentCommand`                    | Update appointment        |
| `LSGetAppointmentCommand`                    | Fetch appointments        |
| `LSDeleteAppointmentCommand`                 | Delete appointment        |
| `LSQueryAppointments`                        | Date-range queries        |
| `LSGetDateWithConflictCommand`               | Conflict detection        |
| `LSAppointmentProposalCommand`               | Free-time proposal        |
| `LSDateAssignmentCommand`                    | Participant assignment    |
| `LSCyclicAppointmentsCommand`                | Create recurring series   |
| `LSGetICalForAppointmentsCommand`            | iCalendar export         |
| `LSNewAppointmentFromVEventCommand`          | Import from vEvent        |
| `LSUpdateAppointmentWithVEventCommand`       | Update from vEvent        |
| `OGoAptAccessHandler`                        | Access control handler    |
| `OGoCycleDateCalculator`                     | Recurrence calculation    |
| `OGoCycleDateDelegate`                       | Recurrence delegate       |


## Shared Library: libOGoSchedulerTools

The `OGoCycleDateCalculator` and `OGoCycleDateDelegate`
classes are built as a separate shared library
(`libOGoSchedulerTools`) so that other modules (e.g.
ZideStore/CalDAV) can calculate recurrence dates without
loading the full scheduler command bundle.
