# Common - Shared UI Components

Common contains reusable UI components used across the
OGo web interface. Components are split between legacy
3.x (BaseUI) and modern 4.x (OGoUIElements) bundles.


## Sub-Bundles

### BaseUI (Legacy 3.x)

**Bundle:** `BaseUI.lso` (62 source files)

Core UI framework components:
- **Tables:** `LSWTableView`, `LSWTableViewHeader`,
  `LSWTableViewFooter`
- **Editors:** `LSWObjectEditor`, `LSWObjectViewer`
- **Dock:** `SkyDock`, `SkyFavorites`, `SkyNavigation`
- **Panels:** `SkySearchPanel`, `SkyWarningPanel`
- **Fields:** `SkyAttribute`, `SkyObjectField`,
  `SkyTimeZonePopUp`
- **Lists:** `SkyListView`, `SkyListSorter`
- **Frame:** `LSWSkyrixFrame`, `OGoWindowFrame`
- **Wizards:** `SkyWizardChoicePage`,
  `SkyWizardResultList`

### OGoUIElements (Modern 4.x)

**Bundle:** `OGoUIElements.lso` (40+ source files)

Modern reusable elements:
- **Tabs:** `SkyTabView`, `SkySimpleTabItem`
- **Trees:** `SkyTreeView`, `SkyFileManagerTreeView`
- **Content:** `SkyCollapsibleContent`
- **Text:** `SkyTextEditor`, `SkyRichString`
- **Fields:** `SkyDateField`, `SkyDialNumber`
- **Access:** `SkyAccessList` (ACL editor)
- **Calendar:** `SkyCalendarPopUp`
- **Form:** `OGoFieldSet`, `OGoField`,
  `OGoPageButton`

### PropertiesUI

**Bundle:** `PropertiesUI.lso` (5 source files)

Object property viewer/editor:
- `SkyObjectPropertyViewer`
- `SkyObjectPropertyEditor`
- `OGoObjPropInlineEditor`

### RelatedLinksUI

**Bundle:** `RelatedLinksUI.lso` (3 source files)

Object link management:
- `OGoObjectLinkList` - Display and manage related
  object links
