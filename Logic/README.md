# Logic - OGo Business Logic

[STABLE]

This directory contains the OpenGroupware.org business
logic. All operations are expressed as "command" objects,
packaged in "command bundles" (`.cmd` extension), and
installed into `$GNUSTEP_ROOT/Library/OpenGroupware.org/`.

Commands enforce permissions and data integrity. Using
Logic commands instead of direct SQL ensures that access
control is properly applied.


## Dependencies

Requires SOPE and GDL (GNUstep Database Library).


## Build Order

1. **LSFoundation** - Core library, all others depend on it
2. **LSBase**       - Generic base commands (library + bundle)
3. **LSSearch**     - Search infrastructure (library + bundle)
4. **LSAddress**    - Contact base classes (library + bundle)
5. **LSAccount**    - Account management
6. **LSEnterprise** - Enterprise/organization management
7. **LSPerson**     - Person/individual management
8. **LSTeam**       - Team/group management
9. **LSDocuments**  - Document versioning
10. **LSProject**   - Project and note management
11. **LSScheduler** - Calendar/appointments
12. **LSTasks**     - Task/job management
13. **LSNews**      - Newsboard articles
14. **LSMail**      - Email delivery (mostly deprecated)


## Command Invocation

Commands are invoked via the factory pattern:

```objc
LSRunCommandV(ctx, @"person", @"get", @"companyId", personId, nil);
```

Or via the command context:

```objc
[ctx runCommand:@"person::get",  @"companyId", personId, nil];
```


## Module Types

- **Libraries** (`lib*.so`): LSFoundation, LSBase,
  LSAddress, LSSearch provide reusable classes
- **Bundles** (`*.cmd`): All modules except LSFoundation
  install command bundles that are loaded at runtime
