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
