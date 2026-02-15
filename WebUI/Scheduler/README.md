# Scheduler - Calendar UI

Scheduler provides the web interface for appointments,
calendar views (day, week, month, year), resource
scheduling, and conflict detection.


## Sub-Bundles

### LSWScheduler - Legacy Scheduler (3.x)

**Bundle:** `LSWScheduler.lso` (33 source files)

Legacy appointment components:
- **Editor:** `LSWAppointmentEditor` -
  Full appointment editor
- **Viewer:** `LSWAppointmentViewer`
- **Proposal:** `LSWAppointmentProposal` -
  Meeting time finder
- **Selection:** `SkyParticipantsSelection`,
  `SkyResourceSelection`, `SkyAptDateSelection`,
  `SkyAptTypeSelection`
- **Move:** `LSWAppointmentMove`
- **Preferences:** `LSWSchedulerPreferences`
- **Formatters:** `OGoAppointmentDateFormatter`,
  `OGoRecurrenceFormatter`
- **Cycling:** `OGoCycleSelection`

### OGoScheduler - Modern Scheduler (4.x)

**Bundle:** `OGoScheduler.lso` (13 source files)

Modern scheduler interface:
- **Page:** `SkySchedulerPage` - Main scheduler
- **Resources:** `SkyAptResourceEditor`,
  `SkyAptResourceViewer`
- **Conflicts:** `SkySchedulerConflictPage`,
  `OGoAptConflictsList`
- **Actions:** `OGoAptFormLetter`,
  `OGoAptMailOpener`
- **Delete:** `SkyAptDeletePanel`

### OGoSchedulerViews - Calendar Views

**Bundle:** `OGoSchedulerViews.lso` (26 source files)

Reusable calendar view components:
- **Day:** `SkyInlineDayChart`,
  `SkyInlineDayOverview`
- **Week:** `SkyInlineWeekChart`,
  `SkyInlineWeekOverview`,
  `SkyInlineWeekColumnView`
- **Month:** `SkyInlineMonthOverview`
- **Year:** `SkyInlineYearOverview`
- **Printing:** `SkyPrintWeekOverview`,
  `SkyPrintMonthOverview`
- **Lists:** `SkyAppointmentList`,
  `SkyAptResourceList`
- **Elements:** `SkyWeekRepetition`,
  `SkyMonthRepetition`, `SkyMonthBrowser`

### OGoSchedulerDock - Dock Widget

**Bundle:** `OGoSchedulerDock.lso` (2 source files)

Calendar dock widget:
- `SkySchedulerDockView` - Mini calendar in dock

### OGoResourceScheduler - Resource Scheduling

**Bundle:** `OGoResourceScheduler.lso` (4 source files)

Resource-centric scheduling view:
- `SkyResourceSchedulerPage` - Resource scheduler
- `SkySchedulerResourcePanel` - Resource selection


# README

This directory contains the OpenGroupware.org bundles which implement the
OGo web interface for the scheduler application.

Bundles
=======

LSWScheduler
- originally contained the SKYRiX 3.x scheduling application and is now
  reduced to the components still used in OpenGroupware.org, like the appointment
  editor
  TODO: move everything required to OGoScheduler

OGoScheduler
- the "new" components for the SKYRiX 4.x scheduling application. quite
  a lot of components are still contained in LSWScheduler

OGoResourceScheduler
- this contains the "resource scheduler" application which provides some
  resource centric views on the scheduling database

OGoSchedulerViews
- all the reusable scheduler views/components
- used by both, OGoScheduler and OGoResourceScheduler

OGoSchedulerDock
- contains the component for the scheduler IE drop-area in the dock, you
  can drop person and appointment records on the dock to view/create meetings
