# LSAddress - Contact Base Functionality

LSAddress provides the base classes for all "company"
objects: persons, enterprises, teams. It handles
addresses, telephone numbers, user defaults, vCard
import/export, company assignments, categories, and
extended attributes.

**Built as:** `libLSAddress` (shared library) and
`LSAddress.cmd` (command bundle)


## Dependencies

- LSFoundation


## Registered Commands

### Company
| Command | Description |
|-------------------------------|--------------------------|
| `company::get`                | Fetch company records    |
| `company::get-vcard`          | Export as vCard           |
| `company::set-vcard`          | Import from vCard        |

### Login
| Command | Description |
|-------------------------------|--------------------------|
| `login::check-login`          | Validate login           |

### Address & Telephone
| Command | Description |
|-------------------------------|--------------------------|
| `address::new/set/get/delete` | Address CRUD             |
| `address::fetchAttributes`    | Fetch address attributes |
| `address::convert`            | Address conversion       |
| `telephone::new/set/get/delete` | Telephone CRUD         |

### Staff
| Command | Description |
|-------------------------------|--------------------------|
| `staff::get-by-globalid`      | Fetch staff by GID       |
| `staff::get/delete`           | Staff operations         |

### User Defaults
| Command | Description |
|-------------------------------|--------------------------|
| `userdefaults::get`           | Get user defaults        |
| `userdefaults::write`         | Write user defaults      |
| `userdefaults::register`      | Register defaults        |
| `userdefaults::delete`        | Delete defaults          |

### Categories & Values (internal)
| Command | Description |
|-------------------------------|--------------------------|
| `companycategory::set-all`    | Set all categories       |
| `companyvalue::query`         | Query company values     |


## Key Classes

| Class | Purpose |
|-------------------------------|--------------------------|
| `LSGetCompanyCommand`         | Base company fetch       |
| `LSSetCompanyCommand`         | Base company update      |
| `LSNewCompanyCommand`         | Base company create      |
| `LSDeleteCompanyCommand`      | Base company delete      |
| `LSUserDefaults`              | User defaults wrapper    |
| `LSVCardNameFormatter`        | vCard name formatting    |
| `LSVCardAddressFormatter`     | vCard address formatting |
| `OGoCompanyAccessHandler`     | Company access control   |


## vCard Notes

Supports import/export for Evolution, Kontact, and
Outlook clients. See class headers for format details.
