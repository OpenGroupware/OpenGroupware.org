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

#import "common.h"
#import "LSGetCompanyCommand.h"

@implementation LSGetCompanyCommand

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->companyId);
  [super dealloc];
}
#endif

- (void)_executeInContext:(id)_context {
  NSMutableArray *resultList    = [NSMutableArray array];
  id teamCmd       = LSLookupCommand(@"team", @"get");
  id personCmd     = LSLookupCommand(@"person", @"get");
  id enterpriseCmd = LSLookupCommand(@"enterprise", @"get");

  [teamCmd       takeValue:self->companyId forKey:@"companyId"];
  [personCmd     takeValue:self->companyId forKey:@"companyId"];
  [enterpriseCmd takeValue:self->companyId forKey:@"companyId"];
  
  [resultList addObjectsFromArray:[teamCmd       runInContext:_context]];
  [resultList addObjectsFromArray:[personCmd     runInContext:_context]];
  [resultList addObjectsFromArray:[enterpriseCmd runInContext:_context]];


  if (![[_context accessManager]
                  operation:@"r"
                  allowedOnObjectIDs:[resultList map:@selector(valueForKey:)
                                                 with:@"globalID"]]) {
    NSLog(@"%s: Missing read access for %@", __PRETTY_FUNCTION__, resultList);
    [self setReturnValue:nil];
    return;
  }
  [self setReturnValue:resultList];
}

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"companyId"]) {
    ASSIGN(self->companyId, _value);
    return;
  }
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"companyId"])
    return self->companyId;
  else
    return [super valueForKey:_key];
}
@end
