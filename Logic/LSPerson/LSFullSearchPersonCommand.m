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

#include <LSSearch/LSFullSearchCommand.h>

@interface LSFullSearchPersonCommand : LSFullSearchCommand
@end

#include "common.h"

@implementation LSFullSearchPersonCommand

+ (int)version {
  return [super version] + 0; /* v3 */
}

/* command methods */

- (EOSQLQualifier *)checkPermissionsFor:(EOSQLQualifier *)qualifier_ 
  context:(id)_ctx 
{
  EOSQLQualifier *isArchivedQualifier, *isTemplateQualifier;
  
  qualifier_ = [super checkPermissionsFor:qualifier_ context:_ctx];
  
  isArchivedQualifier = [[EOSQLQualifier alloc]
                                         initWithEntity:[self entity]
                                         qualifierFormat:
                                           @"dbStatus <> 'archived'"];
  isTemplateQualifier = [[EOSQLQualifier alloc]
                                         initWithEntity:[self entity]
                                         qualifierFormat:
                                           @"(isTemplateUser IS NULL) OR "
                                           @"(isTemplateUser = 0)"]; 
  
  [qualifier_ conjoinWithQualifier:isArchivedQualifier];
  [qualifier_ conjoinWithQualifier:isTemplateQualifier];
  [isArchivedQualifier release]; isArchivedQualifier = nil;
  [isTemplateQualifier release]; isTemplateQualifier = nil;
  return qualifier_;
}

- (void)_executeInContext:(id)_context {
  [super _executeInContext:_context];

#if 0  
  [self setObject:LSRunCommandV(_context, @"person", @"check-permission",
                                @"object", [self object], nil)];
#endif  
  
  // TODO: fix for gid-only fetches
  
  //get extended attributes 
  LSRunCommandV(_context, @"person", @"get-extattrs",
                @"objects", [self object],
                @"relationKey", @"companyValue", nil);

  //get telephones
  LSRunCommandV(_context, @"person", @"get-telephones",
                @"objects", [self object],
                @"relationKey", @"telephones", nil);
}

- (NSString *)entityName {
  return @"Person";
}

@end /* LSFullSearchPersonCommand */
