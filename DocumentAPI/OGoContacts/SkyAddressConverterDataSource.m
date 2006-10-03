/*
  Copyright (C) 2000-2006 SKYRIX Software AG
  Copyright (C) 2006      Helge Hess

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
  context:(LSCommandContext *)_ctx
  labels:(id)_labels
{
  if ((self = [super init]) != nil) {
    NSAssert1((_ds  != nil), @"%s: No dataSource set!", __PRETTY_FUNCTION__);
    NSAssert1((_ctx != nil), @"%s: No context set!",    __PRETTY_FUNCTION__);
    
    self->source  = [_ds     retain];
    self->context = [_ctx    retain];
    self->labels  = [_labels retain];
    self->fetchSpecification = [[EOFetchSpecification alloc] init];
  }
  return self;
}

- (void)dealloc {
  [self->source             release];
  [self->context            release];
  [self->labels             release];
  [self->fetchSpecification release];
  [super dealloc];
}

- (void)setFetchSpecification:(EOFetchSpecification *)_fSpec {
  if ([self->fetchSpecification isEqual:_fSpec])
    return;

  ASSIGNCOPY(self->fetchSpecification, _fSpec);
  [self postDataSourceChangedNotification];
}

- (EOFetchSpecification *)fetchSpecification {
  return [[self->fetchSpecification copy] autorelease];
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
  [fspec release]; fspec = nil;

  ids = [self->source fetchObjects];
  
  if ([type isEqualToString:@"vCard"]) {
    result = [self->context runCommand:@"company::get-vcard",
                  @"gids",          ids,
                  @"buildResponse", [NSNumber numberWithBool:YES],
                  nil];
  }
  else {
    /* Note: the 'forkExport' is apparently ignored in address::convert */
    result = [self->context runCommand:@"address::convert",
                  @"type", type, 
                  @"kind", kind,
                  @"ids", ids,
                  @"forkExport", [NSNumber numberWithBool:YES],
                  @"labels",  self->labels , nil];
  }
  
  return [NSArray arrayWithObject:result];
}

@end /* SkyAddressConverterDataSource */
