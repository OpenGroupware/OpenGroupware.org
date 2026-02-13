# AdminUI - Administration Interface

AdminUI provides the system administration interface
for managing user accounts, teams, passwords, and
system defaults.

**Bundle:** `AdminUI.lso` (13 source files)


## Dependencies

- OGoFoundation
- LSFoundation


## Key Components

| Component | Purpose |
|---------------------------|-------------------------------|
| `LSWStaff`                | User/team overview            |
| `LSWAccountViewer`        | View account details          |
| `LSWTeamViewer`           | View team details             |
| `LSWTeamEditor`           | Edit team membership          |
| `LSWPasswordEditor`       | Change passwords              |
| `SkyDefaultsViewer`       | View system defaults          |
| `SkyDefaultsEditor`       | Edit system defaults          |
| `SkyDefaultsDomain`       | Defaults domain selector      |
| `SkyDefaultsElement`      | Individual default element    |


## Resources

Configuration plist files for the defaults editor:

- `MTA.plist` - Mail transfer agent settings
- `Skyrix.plist` - Core OGo settings
- `NSGlobalDomain.plist` - Global settings
- `skyxmlrpcd.plist` - XML-RPC server settings
- `skyaptnotify.plist` - Notification settings


# README

User Manager Application
========================

Note: in case you wonder that there is no LSWAccountEditor - this is the
      LSWPreferencesEditor in PreferencesUI ...

Note: apparently the LSWAccountViewer is not the viewer for accounts?
      => apparently LSWPreferencesViewer is used for that?
TODO: is the LSWAccountViewer actually used somewhere?

Note: the 'nickname' is stored in the 'description' field in the database
