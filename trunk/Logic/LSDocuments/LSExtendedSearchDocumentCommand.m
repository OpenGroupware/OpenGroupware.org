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

#import <LSSearch/LSExtendedSearchCommand.h>

@interface LSExtendedSearchDocumentCommand : LSExtendedSearchCommand
{
@protected
  id project;
}

@end

#import "common.h"

@implementation LSExtendedSearchDocumentCommand

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->project);
  [super dealloc];
}
#endif

// command methods

- (EOSQLQualifier *)extendedSearchQualifier:(void *)_context {
  EOSQLQualifier *qualifier   = nil;
  EOSQLQualifier *inQualifier = nil;

  qualifier = [super extendedSearchQualifier:_context];

  inQualifier =
    [[EOSQLQualifier alloc]
                     initWithEntity:[self entity]
                     qualifierFormat:@"%A = %@",
                     @"projectId", [self->project valueForKey:@"projectId"], nil];
  [qualifier conjoinWithQualifier:inQualifier];
  RELEASE(inQualifier); inQualifier = nil;
  return qualifier;
}

- (void)_executeInContext:(id)_context {
  [super _executeInContext:(id)_context];
  [self setObject:LSRunCommandV(_context,
                                @"doc",    @"check-get-permission",
                                @"object", [self object], nil)];

  //get attachment name

  LSRunCommandV(_context, @"doc", @"get-attachment-name",
                @"objects", [self object], nil);
}

// record initializer

- (NSString *)entityName {
  return @"Doc";
}

- (void)setProject:(id)_id { ASSIGN(self->project, _id); }

- (id)project { return self->project; }

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"project"]) {
    [self setProject:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"project"]) {
    return [self project];
  }
  return [super valueForKey:_key];
}


@end
