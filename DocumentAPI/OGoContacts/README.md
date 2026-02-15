# OGoContacts - Person and Enterprise Documents

OGoContacts provides document abstractions for contact
records (persons and enterprises) from the company table.
Includes extensive datasource support for related records
like addresses, enterprises, and projects.

**Built as:** `libOGoContacts` (shared library) and
`OGoContacts.ds` (datasource bundle)


## Dependencies

- OGoDocuments
- OGoBase
- LSFoundation (Logic layer)


## Key Classes

### Documents

| Class | Purpose |
|-------------------------------|-------------------------------|
| `SkyCompanyDocument`          | Base class for contacts       |
| `SkyPersonDocument`           | Person record document        |
| `SkyEnterpriseDocument`       | Enterprise/org document       |
| `SkyAddressDocument`          | Address information           |

### DataSources

| Class | Purpose |
|-------------------------------|-------------------------------|
| `SkyCompanyDataSource`        | Base contact datasource       |
| `SkyPersonDataSource`         | Person datasource             |
| `SkyEnterpriseDataSource`     | Enterprise datasource         |
| `SkyCompanyProjectDataSource` | Company's projects            |
| `SkyPersonEnterpriseDataSource`| Person's enterprises         |
| `SkyEnterprisePersonDataSource`| Enterprise's persons         |
| `SkyContactAddressDataSource` | Contact addresses             |
| `SkyAddressConverterDataSource`| Address type conversion      |
| `SkyContactsBundleManager`    | Bundle principal class        |


## SkyPersonDocument

Represents a person contact with properties:

- `firstname`, `middlename`, `name`, `nickname`
- `number`, `salutation`, `degree`, `url`
- `gender`, `birthday`, `birthPlace`
- `login`, `isAccount`, `isPerson`
- Outlook compatibility: `partnerName`,
  `assistantName`, `occupation`, `imAddress`

Provides datasources for related records:
`enterpriseDataSource`, `projectDataSource`,
`jobDataSource`.


## SkyEnterpriseDocument

Represents an enterprise/organization with properties:

- `number`, `name`, `priority`, `salutation`
- `url`, `bank`, `bankCode`, `account`
- `login`, `email`, `isEnterprise`

Provides: `personDataSource`, `projectDataSource`,
`allProjectsDataSource`.


# README

OGoContacts
===========

Document abstractions for Contact records. Contact records are stored in the
"company" table in the database and are mapped to the Company EOEntity, which
is why all the stuff is named "SkyCompanyXXX".


SkyPersonDocument
=================
addresses            -> array of addresses
phones               -> array of telephones
addressTypes         -> array of addressTypes (strings) [address.type]
phoneTypes           -> array of phoneTypes (strings)   [phone.type]
address.type+"Phone" -> address
phone.type+"Address" -> telephone


## Class Hierarchy

- *NSObject*
  - *SkyDocument*
    - `SkyAddressDocument`
    - `SkyCompanyDocument`
      - `SkyEnterpriseDocument`
      - `SkyPersonDocument`
  - *SkyDocumentType*
    - `SkyAddressDocumentType`
    - `SkyEnterpriseDocumentType`
    - `SkyPersonDocumentType`
  - *EODataSource*
    - `SkyAddressConverterDataSource`
      - `SkyEnterpriseAddressConverterDataSource`
      - `SkyPersonAddressConverterDataSource`
    - `SkyCompanyCompanyDataSource`
      - `SkyEnterprisePersonDataSource`
      - `SkyPersonEnterpriseDataSource`
    - `SkyCompanyDataSource`
      - `SkyEnterpriseDataSource`
      - `SkyPersonDataSource`
    - `SkyCompanyProjectDataSource`
      - `SkyEnterpriseProjectDataSource`
      - `SkyPersonProjectDataSource`
    - `SkyContactAddressDataSource`
    - `SkyEnterpriseAllProjectsDataSource`
  - *SkyAccessHandler*
    - `SkyContactsAccessHandler`
  - `SkyEnterpriseDocumentGlobalIDResolver`
  - `SkyPersonDocumentGlobalIDResolver`
