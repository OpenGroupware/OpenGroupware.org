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

#include <LSFoundation/LSDBFetchRelationCommand.h>

@class NSArray;

@interface LSFetchTelsForPersonCommand : LSDBFetchRelationCommand
@end

#import "common.h"

@implementation LSFetchTelsForPersonCommand

- (void)_setTels {
  int i, cnt = [[self object] count];

  for (i = 0; i < cnt; i++) {
    id  obj         = [[self object] objectAtIndex:i];
    NSArray *tels   = [obj valueForKey:@"telephones"];
    int     j, cnt2 = [tels count];

    for (j = 0; j < cnt2; j++) {
      id tel = [tels objectAtIndex:j];

      [obj takeValue:[tel valueForKey:@"number"]
           forKey:[tel valueForKey:@"type"]];
    }
  }
}

- (void)_executeInContext:(id)_context {
  [super _executeInContext:_context];
  [self _setTels];
}

- (NSString *)entityName {
  return @"Person";
}

- (EOEntity *)destinationEntity {
  return [[self databaseModel] entityNamed:@"Telephone"];
}
 
- (BOOL)isToMany {
  return YES; 
}
 
- (NSString *)sourceKey {
  return @"companyId";
}

- (NSString *)destinationKey {
  return @"companyId";
}

@end /* LSFetchTelsForPersonCommand */
