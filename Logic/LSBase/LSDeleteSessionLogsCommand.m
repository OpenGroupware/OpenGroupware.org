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

#include <LSFoundation/LSDBObjectBaseCommand.h>

@class NSCalendarDate;

@interface LSDeleteSessionLogsCommand : LSDBObjectBaseCommand
{
  NSCalendarDate *fromDate;
}
@end

#import "common.h"

@implementation LSDeleteSessionLogsCommand

- (void)dealloc {
  RELEASE(self->fromDate);
  [super dealloc];
}

- (void)_executeInContext:(id)_context {
  NSString         *eName;
  EOEntity         *entity;
  NSString         *pkeyName;
  EOAdaptorChannel *adCh;
  EOSQLQualifier   *q;
  
  eName    = [[_context typeManager] entityNameForObject:[self object]];
  entity   = [[_context valueForKey:LSDatabaseKey] entityNamed:eName];
  pkeyName = [[entity primaryKeyAttributeNames] lastObject];
  
  adCh = [[_context valueForKey:LSDatabaseChannelKey] adaptorChannel];
  [self assert:(adCh != nil) reason:@"missing adaptor channel .."];

  q = [[EOSQLQualifier alloc] initWithEntity:
                                [[_context valueForKey:LSDatabaseKey]
                                           entityNamed:@"Log"]
                              qualifierFormat:@"%A=%@",
                                @"objectId",
                                [[self object] valueForKey:pkeyName]];
  AUTORELEASE(q);

  [self assert:[adCh deleteRowsDescribedByQualifier:q]
        reason:@"Couldn't delete log rows for object .."];
}

/* key-value coding */

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"fromDate"]) {
    ASSIGN(self->fromDate, _value);
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  id v = nil;
  
  if ([_key isEqualToString:@"fromDate"])
    v = self->fromDate;
  
  return v;
}

@end
