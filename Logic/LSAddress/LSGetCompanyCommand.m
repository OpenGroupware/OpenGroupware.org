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

#include "LSGetCompanyCommand.h"
#include "common.h"

@implementation LSGetCompanyCommand

- (void)dealloc {
  [self->companyId release];
  [super dealloc];
}

/* run */

- (void)_executeInContext:(id)_context {
  NSMutableArray *resultList;
  id teamCmd, personCmd, enterpriseCmd;

  /* 
     Note: we cannot cache the commands since the content is modified and not
           resetted.
  */
  teamCmd       = LSLookupCommand(@"team", @"get");
  personCmd     = LSLookupCommand(@"person", @"get");
  enterpriseCmd = LSLookupCommand(@"enterprise", @"get");
  
  [teamCmd       takeValue:self->companyId forKey:@"companyId"];
  [personCmd     takeValue:self->companyId forKey:@"companyId"];
  [enterpriseCmd takeValue:self->companyId forKey:@"companyId"];
  
  resultList = [NSMutableArray arrayWithCapacity:16];
  [resultList addObjectsFromArray:[teamCmd       runInContext:_context]];
  [resultList addObjectsFromArray:[personCmd     runInContext:_context]];
  [resultList addObjectsFromArray:[enterpriseCmd runInContext:_context]];
  
  
  if (![[_context accessManager]
                  operation:@"r"
                  allowedOnObjectIDs:[resultList map:@selector(valueForKey:)
                                                 with:@"globalID"]]) {
    [self logWithFormat:@"Missing read access on objects: %@", resultList];
    [self setReturnValue:nil];
    return;
  }
  
  [self setReturnValue:resultList];
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"companyId"]) {
    ASSIGNCOPY(self->companyId, _value);
    return;
  }
  
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"companyId"])
    return self->companyId;

  return [super valueForKey:_key];
}

@end /* LSGetCompanyCommand */
