# Mailer - Email UI

Mailer provides the IMAP4-based webmail interface
including mail viewing, composition, filtering,
and mailing list management.


## Sub-Bundles

### OGoWebMail - IMAP4 Webmail

**Bundle:** `OGoWebMail.lso` (54 source files)

Main webmail interface:
- **Mail List:** `LSWImapMails`, `SkyImapMailList`
- **Folders:** `LSWImapMailFolderTree`,
  `LSWImapMailFolderEditor`
- **Viewing:** `LSWImapMailViewer`
- **Search:** `LSWImapMailSearch`
- **Movement:** `LSWImapMailMove`
- **Login:** `LSWImapMailLogin`
- **Integration:** `LSWImapMail2Project` -
  Link mail to project
- **Printing:** `SkyImapMailPrintViewer`
- **Preferences:** `LSWMailPreferences`

### OGoMailViewers - MIME Part Display

**Bundle:** `OGoMailViewers.lso` (22 source files)

MIME type handlers for mail content:
- `LSWTextPlainBodyViewer` - Plain text
- `LSWImageBodyViewer` - Images
- `LSWMultipartBodyViewer` - Container types
- `LSWMessageRfc822BodyViewer` - Forwarded msgs
- `LSWAppOctetBodyViewer` - Binary downloads
- `LSWMimePartViewer` - Generic MIME parts

### OGoMailEditor - Mail Composition

**Bundle:** `OGoMailEditor.lso` (14 source files)

Mail compose interface:
- `LSWImapMailEditor` - Mail editor
- `OGoMailAddressSearch` - Recipient search
- `OGoComplexMailAddressSearch` - Advanced search

### OGoMailInfo - Mail Dock Widget

**Bundle:** `OGoMailInfo.lso` (6 source files)

Dock integration:
- `LSWMailsDockView`, `LSWImapDockView`
- `SkyImapMailPopUp` - Mail selection popup

### OGoMailFilter - Mail Filtering

**Bundle:** `OGoMailFilter.lso` (10 source files)

Mail filter/rule management:
- `OGoMailFilterManager` - Filter orchestration
- `LSWImapMailFilterEditor` - Filter editor
- `SkyVacationEditor` - Out-of-office auto-reply

### OGoRecipientLists - Mailing Lists

**Bundle:** `OGoRecipientLists.lso` (8 source files)

Mailing list management:
- `SkyMailingListManager` - List management
- `SkyMailingListEditor` - Edit lists
- `SkyMailingListViewer` - View lists

### LSWMail - Legacy Mail (Deprecated)

**Bundle:** `LSWMail.lso` (26 source files)

Legacy RDBMS-based mail components. Some still used
by OGoWebMail for shared functionality.


# README

Mailer
======

This directory contains the packages which form the OpenGroupware.org
IMAP4 based webmail application.

OGoWebMail
==========
- IMAP4 based web mailer, uses the NGMime library from SOPE/skyrix-core

OGoMailViewers
==============
- OGoWebMail uses a component based system to display MIME mails, the
  OGoMailViewers bundle contains the basic ones for displaying MIME
  parts, text-parts etc

OGoMailInfo
===========
- separate bundle for the mail dock-icon (so that we don't need to load
  the full mailer if it isn't used)

LSWMail
=======
- this contained the old RDBMS based application, OGoWebMail still uses
  some components from this
=> TODO: move all required things to OGoWebMail (or a new bundle)
