/*
  Copyright (C) 2000-2005 SKYRIX Software AG

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

#include "LSSort+TableView.h"
#include "common.h"

// DEPRECATED!

@implementation LSSort(TableViewSorting)

- (NSArray *)sortArray:(NSArray *)_array
  key:(NSString *)_key
  isDescending:(BOOL)_flag
{
  static Class StrClass           = Nil;
  static Class EnterpriseClass    = Nil;
  static Class PersonClass        = Nil;
  static Class InvoiceActionClass = Nil;
  static Class InvoiceClass       = Nil;
  id           singleObject;
  NSDictionary *dkey = nil;
  
  if (EnterpriseClass == Nil)
    EnterpriseClass = NSClassFromString(@"LSEnterprise");
  if (PersonClass == Nil)
    PersonClass = NSClassFromString(@"LSPerson");
  if (InvoiceActionClass == Nil)
    InvoiceActionClass = NSClassFromString(@"LSInvoiceAction");
  if (InvoiceClass == Nil)
    InvoiceClass = NSClassFromString(@"LSInvoice");
  if (StrClass == Nil)
    StrClass = [NSString class];
  
  singleObject = [[_array lastObject] valueForKey:_key];
  if (singleObject != nil) {
    BOOL      found;
    NSString *skey = nil;

    found = NO;
    if ([singleObject isKindOfClass:EnterpriseClass]) {
      skey = @"description";
      found = YES;
    }
    else if ([singleObject isKindOfClass:InvoiceActionClass]) {
      skey = @"actionDate";
      found = YES;
    }
    else if ([singleObject isKindOfClass:InvoiceClass]) {
      skey = @"invoiceNr";
      found = YES;
    }
    else if ([singleObject isKindOfClass:PersonClass]) {
      skey = @"login";
      found = YES;
    }
    else if (![singleObject isKindOfClass:StrClass]) {
      EOKeyGlobalID *gid;
      
      gid = [singleObject valueForKey:@"globalID"];
      if ([[gid entityName] isEqualToString:@"Person"]) {
	skey = @"login";
	found = YES;
      }
    }
    
    if (found) {
      id keys[2];
      id values[2];

      keys[0] = @"relKey"; values[0] = skey;
      keys[1] = @"key";    values[1] = _key;

      dkey = [NSDictionary dictionaryWithObjects:values forKeys:keys count:2];
    }
    if (found) {
      return [self sortArrayWithRelKey: _array
		   inContext:dkey
		   ordering:_flag ? LSDescendingOrder : LSAscendingOrder];
    }
  }

  return [self sortArray:_array
	       inContext:_key
	       ordering:_flag ? LSDescendingOrder : LSAscendingOrder];
}

@end /* LSSort(TableViewSorting) */

void __link_LSSort_TableView(void) {
  __link_LSSort_TableView();
}
