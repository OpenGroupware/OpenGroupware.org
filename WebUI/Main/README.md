# Main - Application Entry Point

Main is the `ogo-webui` executable that bootstraps the
OGo web application. It loads `OGoFoundation` and
discovers/loads all `.lso` bundles at startup.

**Built as:** `ogo-webui` (GNUstep tool/executable)


## Dependencies

- OGoFoundation
- SOPE (NGObjWeb)


## Key Classes

| Class | Purpose |
|---------------------------|-------------------------------|
| `OpenGroupware`           | SoApplication subclass        |
| `OpenGroupware+CTI`       | CTI integration category      |
| `DirectAction`            | Direct action handler         |
| `WODirectAction+LoginAction`| Login/authentication        |
| `SoOGoAuthenticator`      | SOPE authenticator            |
| `OGoWebBundleLoader`      | Bundle discovery and loading  |


## Key User Defaults

| Default | Purpose |
|-------------------------------------|---------------------------|
| `OGoCoreOnException`                | Core dump on exception    |
| `LSUseBasicAuthentication`          | Use HTTP Basic Auth       |
| `SkyLogoutURL`                      | Custom logout redirect    |
| `LSPageRefreshOnBacktrack`          | Refresh on browser back   |
| `UseRefreshPageForExternalLink`     | External link behavior    |


# README

Main Executable
===============

TODO
====
- make it a tool (ogo-webui-51)
  - change lookup of resources:
    - Defaults.plist => just move to .m

Defaults
========
  OGoCoreOnException            NO
  UseRefreshPageForExternalLink NO
  SkyLogoutURL                  ""
  OGoLogBundleLoading           NO

  LSReloadConfiguration    NO           // TODO: still used?
  LSPageRefreshOnBacktrack YES
  LSUseBasicAuthentication NO

  SkyProjectFileManagerClickTimeout    300
  SkyProjectFileManagerUseSessionCache NO

  SkyLanguages
  SkyScheduler_defaultAppointmentTypes

Configuring Custom Appointment Types
====================================
  // SkyScheduler_customAppointmentTypes = (
  // { type = "mycustomtype0"; label = "my label for this type";
  //   icon = "myCustomIcon.gif";
  // );
  //
