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
// $Id: SxMailFolder.m 1 2004-08-20 11:17:52Z znek $

#include "SxMailFolder.h"
#include "common.h"

@implementation SxMailFolder

- (SEL)fetchSelectorForQuery:(EOFetchSpecification *)_fs
  onAttributeSet:(NSSet *)propNames
  inContext:(id)_ctx
{
  SEL handler = NULL;

  handler = [super fetchSelectorForQuery:_fs onAttributeSet:propNames
                   inContext:_ctx];
  if (handler) return handler;

  /* ZideLook */
  if ([propNames isSubsetOfSet:[self propertySetNamed:@"ZideLookMailQuery"]])
    handler = @selector(performZideLookMailQuery:inContext:);
  
  return handler;
}

/* queries */

- (id)performZideLookMailQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  if ([self doExplainQueries]) {
    [self logWithFormat:@"perform ZideLook mail query: %@",
            [[_fs selectedWebDAVPropertyNames] componentsJoinedByString:@","]];
  }
  /* currently we only have empty mail folders ;-) */
  return [NSArray array];
}

@end /* SxMailFolder */
