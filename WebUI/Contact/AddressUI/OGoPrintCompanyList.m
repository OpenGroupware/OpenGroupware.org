/*
  Copyright (C) 2006 Helge Hess

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

#include <OGoFoundation/OGoListComponent.h>

@interface OGoPrintCompanyList : OGoListComponent
{
  id labels;
}

@end

#include "common.h"
#include <OGoContacts/SkyCompanyDocument.h>

@implementation OGoPrintCompanyList

+ (int)version {
  return [super version] + 0 /* v4 */;
}
+ (void)initialize {
  NSAssert2([super version] == 4,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (void)dealloc {
  [self->labels release];
  [super dealloc];
}

/* notifications */

- (void)sleep {
  [self->labels release]; self->labels = nil;
  [super sleep];
}

/* accessors */

- (void)setLabels:(id)_labels {
  ASSIGN(self->labels, _labels);
}
- (id)labels {
  return self->labels;
}

/* config key */

- (NSString *)defaultConfigKey {
  if ([self->configKey rangeOfString:@"person"].length > 0)
    return @"person_defaultlist";
  if ([self->configKey rangeOfString:@"enterprise"].length > 0)
    return @"enterprise_defaultlist";

  return nil;
}

@end /* OGoPrintCompanyList */
