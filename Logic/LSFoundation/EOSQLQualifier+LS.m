/*
  Copyright (C) 2005 Helge Hess

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

#include "EOSQLQualifier+LS.h"
#include "common.h"

@implementation EOSQLQualifier(LS)

- (id)initWithEntity:(EOEntity *)_entity
  csvAttribute:(NSString *)_attrName
  containingValue:(NSString *)_value
{
  NSMutableString *format;
  
  format = [[NSMutableString alloc] initWithCapacity:256];
  [format appendString:@"("];
  
  /* exact */
  // TODO: change this to LIKE if we want to support prefix-patterns, but be
  //       aware of the issues!
  [format appendString:@"(%A = '%@') OR "];
    
  /* suffix */
  [format appendString:@"(%A LIKE "];
  [format appendString:@" '%%, %@') OR "];

  /* middle */
  [format appendString:@"(%A LIKE "];
  [format appendString:@" '%%, %@, %%') OR "];
    
  /* prefix */
  [format appendString:@"(%A LIKE "];
  [format appendString:@" '%@, %%')"];
  [format appendString:@")"];
  
  self = [self initWithEntity:_entity
	       qualifierFormat:format,
	         _attrName, _value, _attrName, _value,
	         _attrName, _value, _attrName, _value];
  [format release]; format = nil;
  
  return self;
}

- (id)initWithEntity:(EOEntity *)_entity
  csvAttribute:(NSString *)_attrName
  containingValues:(NSArray *)_values
  conjoin:(BOOL)_conjoin
{
  unsigned i, count;
  
  if ((count = [_values count]) == 0) {
    // TODO: should return a boolean true/false qualifier? (1=0 or 1=1)
    [self release];
    return nil;
  }
  
  self = [self initWithEntity:_entity csvAttribute:_attrName 
	       containingValue:[_values objectAtIndex:0]];
  for (i = 1; i < count; i++) {
    EOSQLQualifier *q;
    
    q = [[EOSQLQualifier alloc] initWithEntity:_entity csvAttribute:_attrName 
				containingValue:[_values objectAtIndex:i]];
    if (_conjoin) /* AND */
      [self conjoinWithQualifier:q];
    else
      [self disjoinWithQualifier:q];
    [q release]; q = nil;
  }
  return self;
}

@end /* EOSQLQualifier(LS) */
