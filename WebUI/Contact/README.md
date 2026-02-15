# Contact - Contact Management UI

Contact provides the web interface for managing persons,
enterprises (companies), and their addresses, phone
numbers, and extended attributes.


## Sub-Bundles

### AddressUI - Shared Contact Components

**Bundle:** `AddressUI.lso` (39 source files)

Shared components used by both PersonsUI and
EnterprisesUI:
- **Address:** `LSWAddressEditor`, `LSWAddressViewer`,
  `SkyAddressEditor`
- **Phone:** `SkyTelephoneViewer`,
  `SkyTelephoneEditor`
- **Search:** `LSWFullSearch`,
  `SkyCompanySavedSearchPopUp`
- **Attributes:** `SkyCompanyAttributesViewer`,
  `SkyExtendedAttrsSubEditor`,
  `SkyCommentSubEditor`
- **Import:** `SkyContactImportPage`,
  `SkyBusinessCardGathering`
- **Printing:** `OGoPrintCompanyList`
- **Actions:** `OGoFormLetterAction`,
  `OGoCompanyBulkOpPanel`

### PersonsUI - Person Management

**Bundle:** `PersonsUI.lso` (29 source files)

Person/employee contact management:
- **Main:** `LSWPersons` - Person listing
- **Editor:** `SkyPersonEditor`
- **Viewer:** `SkyPersonViewer`
- **List:** `SkyPersonList`
- **Search:** `SkyPersonSearchPanel`,
  `LSWPersonAdvancedSearch`
- **Wizard:** `SkyPersonWizard`
- **Quick Create:** `OGoPersonQCreatePanel`
- **LDAP:** `SkyPersonLDAPViewer`

### EnterprisesUI - Enterprise Management

**Bundle:** `EnterprisesUI.lso` (16 source files)

Enterprise/company management:
- **Main:** `LSWEnterprises` - Enterprise listing
- **Editor:** `SkyEnterpriseEditor`
- **Viewer:** `SkyEnterpriseViewer`
- **List:** `SkyEnterpriseList`
- **Search:** `LSWEnterpriseAdvancedSearch`
- **Assignment:** `SkyAssignPersonEditor`

### LDAPAccounts - LDAP Integration

**Bundle:** `LDAPAccounts.lso` (5 source files)

LDAP-aware account components:
- `SkyGenericLDAPViewer` - Display LDAP data
- `WelcomeNewLDAPAccount` - LDAP account welcome


# README

Contact
=======

Contact: AddressUI / EnterprisesUI / PersonsUI / LDAPAccounts
- components to edit/view/search contact information
- since both enterprises and persons are "company" objects
  (objects stored in the company table), common components
  are placed in LSWAddress

LDAPAccounts
- this bundle contains components for displaying person information
  coming out of LDAP
- should be extended to become a full LDAP client for editing inetOrgPerson
  information
