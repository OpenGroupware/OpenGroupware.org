/*
  Copyright (C) 2000-2004 SKYRIX Software AG

  This file is part of OpenGroupware.org.

  OGo is free software; you can redistribute it and/or modify it under
  the terms of the GNU Lesser General Public License as published by the
  Free Software Foundation; either version 2, or (at your option) any
  later version.

  OGo is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
  License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with OGo; see the file COPYING.  If not, write to the
  Free Software Foundation, 59 Temple Place - Suite 330, Boston, MA
  02111-1307, USA.
*/

#include <OGoFoundation/OGoContentPage.h>

@class SkyCompanyDocument;

@interface SkyAddressesViewer : OGoContentPage
{
@protected
  SkyCompanyDocument *company;
  NSString           *addressType;
  NSString           *columns;
}
@end

#include "common.h"
#include <OGoContacts/SkyCompanyDocument.h>

@implementation SkyAddressesViewer

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->company);
  RELEASE(self->addressType);
  RELEASE(self->columns);
  [super dealloc];
}
#endif

// --- accessors: public

- (void)setCompany:(id)_company {
  ASSIGN(self->company,   _company);
}
- (id)company {
  return self->company;
}

- (void)setColumns:(id)_col {
  ASSIGN(self->columns,_col);
}
- (id)columns {
  return self->columns;
}

- (id)maxColumns {
  if (self->columns == nil)
    return [NSNumber numberWithInt:3];
  return self->columns;
}

- (void)setAddressType:(NSString *)_addr {
  ASSIGN(self->addressType,_addr);
}
- (NSString *)addressType {
  return self->addressType;
}

- (SkyDocument *)addressDocument {
  return [[self company] addressForType:[self addressType]];
}


// --- actions --------------------------------------

- (BOOL)isEditEnabled {
#if 0  
  id   myAccount, accountId, obj;
  BOOL isEnabled, isPrivate, isReadonly;
  
  myAccount  = [[self session] activeAccount];
  accountId  = [myAccount valueForKey:@"companyId"];
  obj        = self->company;
  isEnabled  = NO;
  isPrivate  = [[obj valueForKey:@"isPrivate"] boolValue];
  isReadonly = [[obj valueForKey:@"isReadonly"] boolValue];
  
  isEnabled = ((!isPrivate && !isReadonly) || 
               ([accountId isEqual:[obj valueForKey:@"ownerId"]]) ||
               ([[self session] activeAccountIsRoot]));

  return isEnabled;
#else
  return [[[[self session] valueForKey:@"commandContext"] accessManager]
                  operation:@"w" allowedOnObjectID:
                  [self->company valueForKey:@"globalID"]];
  
#endif
}

@end /* SkyAddressesViewer */
