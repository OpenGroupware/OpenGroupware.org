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

/*
  This command returns all possible resource-categories.
  If a category is given, it returns all resources for this category.
*/

@class NSString;

@interface LSResourceCategories : LSDBObjectBaseCommand
{
  NSString *category;
}
@end

#include "common.h"

@implementation LSResourceCategories

- (void)dealloc {
  [self->category release];
  [super dealloc];
}

/* execution */

- (EOSQLQualifier *)_qualifierForCategory:(NSString *)_category 
  entity:(EOEntity *)_entity 
{
  EOSQLQualifier *qualifier = nil;
  
  qualifier = [EOSQLQualifier alloc];
  if (_category == nil) {
    qualifier = [qualifier initWithEntity:_entity
			   qualifierFormat:@"category IS NOT NULL"];
  }
  else {
    qualifier = [qualifier initWithEntity:_entity
			   qualifierFormat:@"category = '%@'", _category];
  }
  [qualifier setUsesDistinct:YES];
  return [qualifier autorelease];
}

- (void)_executeInContext:(id)_ctx {
  EOSQLQualifier   *qualifier = nil;
  EOEntity         *entity    = nil;
  EOAdaptorChannel *channel;
  NSArray          *attrs;
  NSMutableArray   *result;
  NSDictionary     *dict      = nil;
  NSString         *key       = nil;
  
  key = (self->category == nil)
    ? @"category"
    : @"name";
  
  entity    = [[[[_ctx valueForKey:LSDatabaseKey] adaptor] model]
                       entityNamed:@"AppointmentResource"];
  channel   = [[_ctx valueForKey:LSDatabaseChannelKey] adaptorChannel];
  
  qualifier = [self _qualifierForCategory:self->category entity:entity];
  attrs     = [NSArray arrayWithObject:[entity attributeNamed:key]];
  
  if (![channel selectAttributes:attrs describedByQualifier:qualifier
		fetchOrder:nil lock:NO]) {
    [self logWithFormat:
            @"ERROR: database select failed: attributes %@, qualifier %@",
            attrs, qualifier];
    [self setReturnValue:nil];
    return;
  }
  
  result = [NSMutableArray arrayWithCapacity:64];
  while ((dict = [channel fetchAttributes:attrs withZone:NULL]))
    [result addObject:[dict valueForKey:key]];
  
  [self setReturnValue:result];
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"category"])
    ASSIGN(self->category, _value);
  else 
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"category"])
    return self->category;
  
  return [super valueForKey:_key];
}

@end /* LSResourceCategories */
