/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#include <OGoDocuments/SkyDocument.h>
#include "common.h"

@interface NSObject(Labels)

- (NSString *)labelForObjectInSession:(id)_sn;

@end

@implementation SkyDocument(OGoSessionLabel)

- (NSString *)labelForObjectInSession:(id)_sn {
  EOGlobalID *gid;
  BOOL       canEntity;

  gid       = [self valueForKey:@"globalID"];
  canEntity = [self respondsToSelector:@selector(entity)] ? YES : NO;
  
  if (canEntity || gid != nil)
    return [super labelForObjectInSession:_sn];
  
  if ([self isNew]) {
    return ([self respondsToSelector:@selector(entityName)])
      ? [self entityName]
      : @"new";
  }
  
  return ([self respondsToSelector:@selector(entityName)])
    ? [self entityName]
    : @"Doc";
}

@end /* SkyDocument(OGoSessionLabel) */
