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

#include "SkyAddressConverterDataSource.h"
#include "common.h"

@implementation SkyAddressConverterDataSource

- (id)initWithDataSource:(EODataSource *)_ds
                 context:(id)_ctx
                  labels:(id)_labels
{
  if ((self = [super init])) {
    NSAssert1((_ds  != nil), @"%s: No dataSource set!", __PRETTY_FUNCTION__);
    NSAssert1((_ctx != nil), @"%s: No context set!",    __PRETTY_FUNCTION__);
    ASSIGN(self->source,  _ds);
    ASSIGN(self->context, _ctx);
    ASSIGN(self->labels,  _labels);
    self->fetchSpecification = [[EOFetchSpecification alloc] init];
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->source);
  RELEASE(self->context);
  RELEASE(self->labels);
  RELEASE(self->fetchSpecification);
  [super dealloc];
}

- (void)setFetchSpecification:(EOFetchSpecification *)_fSpec {
  if (![self->fetchSpecification isEqual:_fSpec]) {
    ASSIGNCOPY(self->fetchSpecification, _fSpec);
    [self postDataSourceChangedNotification];
  }
}

- (EOFetchSpecification *)fetchSpecification {
  return AUTORELEASE([self->fetchSpecification copy]);
}

- (NSArray *)fetchObjects {
  EOQualifier          *qual;
  NSArray              *ids;
  EOFetchSpecification *fspec;
  NSDictionary         *hints;
  NSData               *result = nil;
  NSString             *type;
  NSString             *kind;

  qual  = [self->fetchSpecification qualifier];
  hints = [self->fetchSpecification hints];

  if (qual == nil)
    return [NSArray array];

  type = [hints objectForKey:@"type"]; // e.g. 'formLetter' or 'vCard'
  kind = [hints objectForKey:@"kind"]; // e.g. 'winword' or 'excel'

  if (type == nil) type = @"formLetter";
  if (kind == nil) kind = @"";

  /* prepare fspec for source */                          
  fspec = [[self->source fetchSpecification] copy];
  if (fspec == nil)
    fspec = [[EOFetchSpecification alloc] init];
  
  [fspec setQualifier:qual];
  [fspec setFetchLimit:[self->fetchSpecification fetchLimit]];
  [fspec setHints:
         [NSDictionary dictionaryWithObjectsAndKeys:@"YES",
                       ([type isEqualToString:@"vCard"]
                        ? @"fetchGlobalIDs" : @"fetchIds"), nil]];
  [self->source setFetchSpecification:fspec];

  ids = [self->source fetchObjects];
  
  if ([type isEqualToString:@"vCard"]) {
    result = [self->context runCommand:@"company::get-vcard",
                  @"gids",          ids,
                  @"buildResponse", [NSNumber numberWithBool:YES],
                  nil];
  }
  else {
    result = [self->context runCommand:@"address::convert",
                  @"type", type, 
                  @"kind", kind,
                  @"ids", ids,
                  @"forkExport", [NSNumber numberWithBool:YES],
                  @"labels",  self->labels , nil];
  }

  RELEASE(fspec);
  return [NSArray arrayWithObject:result];
}

@end /* SkyAddressConverterDataSource */
