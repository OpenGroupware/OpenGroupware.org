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

#include "AutostartInstance+Logic.h"
#include "SkyMasterApplication.h"
#include "DefaultEntry.h"
#include "common.h"
#include <XmlSchema/NSObject+XmlSchema.h>

@implementation AutostartInstance(Logic)

- (id)initWithContentsOfFile:(NSString *)_file {
  if ((self = [super initWithContentsOfFile:_file])) {
    SkyMasterApplication *app;

    app = (SkyMasterApplication *)[WOApplication application];

    if (self->priority == 0)
      [self setPriority:[NSNumber numberWithInt:[app priority]]];
  }
  return self;
}

- (NSDictionary *)parametersAsDictionary {
  NSMutableDictionary *result;
  NSEnumerator        *defaultEnum;
  DefaultEntry        *defaultEntry;

  result = [NSMutableDictionary dictionaryWithCapacity:
                                [self->parameters count]];
  defaultEnum = [self->parameters objectEnumerator];
  while((defaultEntry = [defaultEnum nextObject])) {
    [result setObject:[defaultEntry value] forKey:[defaultEntry name]];
  }

  return result;
}

- (NSString *)instanceName {
  NSString *iName;
  
  if ((iName = [self uid]) == nil) {
    iName = [self templateclass];
  }
  return iName;
}

@end /* AutostartInstance(Logic) */
