/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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
// $Id$

#import <LSFoundation/LSDBObjectGetCommand.h>

@interface LSGetPersonCommand : LSDBObjectGetCommand
@end

#include "common.h"
#import <EOControl/EOKeyGlobalID.h>

@implementation LSGetPersonCommand

// command methods

- (void)_prepareForExecutionInContext:(id)_context {
  EOSQLQualifier *isArchivedQualifier;
  EOSQLQualifier *isTemplateQualifier;

  isArchivedQualifier =  [[EOSQLQualifier alloc] initWithEntity:[self entity]
                                     qualifierFormat:@"dbStatus <> 'archived'"];
  isTemplateQualifier =  [[EOSQLQualifier alloc]
                                          initWithEntity:[self entity]
                                          qualifierFormat:
                                            @"(isTemplateUser is NULL) OR "
                                            @"(isTemplateUser = 0)"]; 
  
  [super _prepareForExecutionInContext:_context];
  [self conjoinWithQualifier:isArchivedQualifier];
  [self conjoinWithQualifier:isTemplateQualifier];
  ASSIGN(isArchivedQualifier, nil);
  ASSIGN(isTemplateQualifier, nil);
}

- (void)_executeInContext:(id)_context {
  [super _executeInContext:_context];

  {
    NSArray *a;

    a = [self object];

    if (![a isKindOfClass:[NSArray class]]) {
      a = [NSArray arrayWithObject:a];
    }

    if ([a count] == 0)
      return;
    
    if ([[self checkAccess] boolValue]) {
      if (![[_context accessManager]
                      operation:@"r"
                      allowedOnObjectIDs:[a map:@selector(valueForKey:)
                                            with:@"globalID"]]) {
        NSLog(@"%s: Missing read access for %@", __PRETTY_FUNCTION__, a);
        [self setReturnValue:nil];
        return;
      }
    }
  }
  
  [self setObject:LSRunCommandV(_context,
                                @"person", @"check-permission",
                                @"object", [self object], nil)];

  //get extended attributes 
  LSRunCommandV(_context, @"person", @"get-extattrs",
                @"objects", [self object],
                @"relationKey", @"companyValue", nil);

  //get telephones
  LSRunCommandV(_context, @"person", @"get-telephones",
                @"objects", [self object],
                @"relationKey", @"telephones", nil);
}

// record initializer

- (NSString *)entityName {
  return @"Person";
}

/* KVC */

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"gid"]) {
    _key   = @"companyId";
    _value = [_value keyValues][0];
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  id v;
  
  if ([_key isEqualToString:@"gid"]) {
    v = [super valueForKey:@"companyId"];
    v = [EOKeyGlobalID globalIDWithEntityName:[self entityName]
                       keys:&v keyCount:1
                       zone:NULL];
  }
  else
    v = [super valueForKey:_key];
  
  return v;
}

@end /* LSGetPersonCommand */
