// $Id$

#include <OGoFoundation/OGoContentPage.h>

@class EODataSource;
@class LdapPersonDocument;

@interface AddressList: OGoContentPage 
{
@protected
  EODataSource       *dataSource;
  LdapPersonDocument *address;
}

@end

#include "common.h"
#include "LdapPersonDocument.h"
#include "LdapPersonViewer.h"

@implementation AddressList

- (void)dealloc {
  RELEASE(self->dataSource);
  RELEASE(self->address);
  [super dealloc];
}

/* Accessors */

- (void)setDataSource:(EODataSource *)_dataSource {
  ASSIGN(self->dataSource, _dataSource);
}
- (EODataSource *)dataSource {
  return self->dataSource;
}

- (void)setAddress:(LdapPersonDocument *)_address {
  ASSIGN(self->address, _address);
}
- (LdapPersonDocument *)address {
  return self->address;
}

- (id)openAddressAction {
  LdapPersonViewer *page = (id)[self pageWithName:@"LdapPersonViewer"];

  [page setPerson:self->address];

  return page;
}

@end /* AddressList */
