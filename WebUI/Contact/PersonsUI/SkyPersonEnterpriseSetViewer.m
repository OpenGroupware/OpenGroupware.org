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

#include <OGoFoundation/LSWContentPage.h>

@class NSArray, WOComponent, NSDictionary;

@interface SkyPersonEnterpriseSetViewer : LSWContentPage
{
  id       person;
  id       enterprise;
  unsigned enterpriseIndex;
}
- (void)setEnterprise:(id)_enterprise;
@end

#include "common.h"
#include <OGoContacts/SkyEnterpriseDocument.h>
#include <OGoContacts/SkyPersonDocument.h>

@implementation SkyPersonEnterpriseSetViewer

- (void)dealloc {
  [self->person     release];
  [self->enterprise release];
  [super dealloc];
}

/* accessors */

- (void)setPerson:(id)_person {
  ASSIGN(self->person, _person);
}
- (id)person {
  return self->person;
}

- (void)setEnterpriseIndex:(unsigned)_enterpriseIndex {
  self->enterpriseIndex = _enterpriseIndex;
}
- (unsigned)enterpriseIndex {
  return self->enterpriseIndex;    
}

- (void)setEnterprise:(id)_enterprise {
  ASSIGN(self->enterprise, _enterprise);
}

- (NSArray *)enterprises {
  return [[[self person] enterpriseDataSource] fetchObjects];
}

- (id)enterprise {
  NSArray *e = [self enterprises];

  if ([e count] > self->enterpriseIndex) {
    return [e objectAtIndex:self->enterpriseIndex];
  }
  return nil;
}


/* conditionals */

- (BOOL)hasMoreEnterprises {
  return [[self enterprises] count] > 1;
}

- (BOOL)isNotFirstEnterprise {
  return self->enterpriseIndex > 0;
}

- (BOOL)isNotLastEnterprise {
  return self->enterpriseIndex < [[self enterprises] count] - 1;
}

- (BOOL)isInEnterprise {
  return [[self enterprises] count] > 0;
}

/* accessors */

- (NSString *)epInfo {
  unsigned char buf[32];
  sprintf(buf, "(%d/%d)", (self->enterpriseIndex + 1), 
	  [[self enterprises] count]);
  return [NSString stringWithCString:buf];
}

- (NSString *)enterpriseViewerTitle {
  NSMutableString *str = nil;

  str = [NSMutableString stringWithCapacity:128];
  [str appendString:
	 [[(SkyEnterpriseDocument *)[self enterprise] name] stringValue]];

  if ([self hasMoreEnterprises]) {
    [str appendString:@" "];
    [str appendString:[self epInfo]];
  }
  return str;
}

/* actions */

- (id)firstEnterprise {
  self->enterpriseIndex = 0;
  return nil;
} 

- (id)lastEnterprise {
  self->enterpriseIndex = [[self enterprises] count] - 1;
  return nil;
} 

- (id)nextEnterprise {
  if ([self isNotLastEnterprise])
    self->enterpriseIndex++;
  
  return nil;
} 
- (id)previousEnterprise {
  if ([self isNotFirstEnterprise])
    self->enterpriseIndex--;
  
  return nil;
}

- (id)separatePerson {
  [[[self enterprise] personDataSource] deleteObject:[self person]];
  return nil;
}

- (id)viewEnterprise {
  return [self activateObject:self->enterprise withVerb:@"view"];
}

@end /* SkyPersonEnterpriseSetViewer */
