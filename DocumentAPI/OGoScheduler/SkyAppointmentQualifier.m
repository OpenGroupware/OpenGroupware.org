/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#include "SkyAppointmentQualifier.h"
#include "common.h"

@implementation SkyAppointmentQualifier

- (id)initWithDictionary:(NSDictionary *)_dict {
  if ((self = [super init])) {
    NSMutableDictionary *md;
    id tmp;
    
    md = [[NSMutableDictionary alloc] initWithDictionary:_dict];
    
    if ((tmp = [md objectForKey:@"startDate"])) {
      [self setStartDate:tmp];
      [md removeObjectForKey:@"startDate"];
    }
    if ((tmp = [md objectForKey:@"endDate"])) {
      [self setEndDate:tmp];
      [md removeObjectForKey:@"endDate"];
    }
    if ((tmp = [md objectForKey:@"resources"])) {
      [self setResources:tmp];
      [md removeObjectForKey:@"resources"];
    }
    if ((tmp = [md objectForKey:@"companies"])) {
      [self setCompanies:tmp];
      [md removeObjectForKey:@"companies"];
    }
    if ((tmp = [md objectForKey:@"personIds"])) {
      [self setPersonIds:tmp];
      [md removeObjectForKey:@"personIds"];
    }
    if ((tmp = [md objectForKey:@"timeZone"])) {
      [self setTimeZone:tmp];
      [md removeObjectForKey:@"timeZone"];
    }
    
    if ([md count] > 0) {
      [self logWithFormat:
              @"WARNING: could not set keys in appointment qualifier: %@",
              [[md allKeys] componentsJoinedByString:@","]];
    }
    [md release];
  }
  return self;
}

- (id)initWithArray:(NSArray *)_array {
  if ((self = [super init])) {
    [self logWithFormat:
            @"NOT IMPLEMENTED: cannot init appointment qualifier "
            @"with array: '%@'", _array];
    [self release];
    return nil;
  }
  return self;
}

- (id)initWithString:(NSString *)_str {
  if ((self = [super init])) {
    id tmp;

    [self logWithFormat:
            @"NOT IMPLEMENTED: cannot init appointment qualifier "
            @"with string: '%@'", _str];
    [self release];
    return nil;
    
    // TODO: implement
    
    tmp = [EOQualifier qualifierWithQualifierFormat:_str];
    
    if ([tmp respondsToSelector:@selector(qualifiers)]) {
      // get all key - value - pairs and set it
    }
    else if ([tmp isKindOfClass:[EOKeyValueQualifier class]]) {
      // get the key - value pair and set it
    }
  }
  return self;
}

- (void)dealloc {
  [self->startDate release];
  [self->endDate   release];
  [self->timeZone  release];
  [self->companies release];
  [self->resources release];
  [self->aptTypes  release];
  [super dealloc];
}

/* accessors */

- (void)setStartDate:(NSCalendarDate *)_startDate {
  ASSIGN(self->startDate,_startDate);
}
- (NSCalendarDate *)startDate {
  return self->startDate;
}

- (void)setEndDate:(NSCalendarDate *)_endDate {
  ASSIGN(self->endDate,_endDate);
}
- (NSCalendarDate *)endDate {
  return self->endDate;
}

- (void)setTimeZone:(NSTimeZone *)_tz {
  ASSIGN(self->timeZone,_tz);
}
- (NSTimeZone *)timeZone {
  return self->timeZone;
}

- (void)setCompanies:(NSArray *)_companies {
  ASSIGN(self->companies, _companies);
}
- (NSArray *)companies {
  return self->companies;
}

- (void)setPersonIds:(NSArray *)_p {
  ASSIGN(self->personIds, _p);
}
- (NSArray *)personIds {
  return self->personIds;
}
- (NSArray *)personGIDs {
  NSEnumerator   *enumerator;
  NSMutableArray *result;
  id              obj;

  if ([self->personIds count] == 0)
    return nil;
  
  result     = [NSMutableArray arrayWithCapacity:[self->personIds count]];
  enumerator = [self->personIds objectEnumerator];
  
  while ((obj = [enumerator nextObject])) {
    EOKeyGlobalID *gid;
    
    gid = [EOKeyGlobalID globalIDWithEntityName:@"Person"
			 keys:&obj keyCount:1 zone:NULL];
    [result addObject:gid];
  }
  return result;
}

- (void)setResources:(NSArray *)_resources {
  ASSIGN(self->resources,_resources);
}
- (NSArray *)resources {
  return self->resources;
}

- (void)setOnlyNotified:(BOOL)_flag {
  self->onlyNotified = _flag;
}
- (BOOL)onlyNotified {
  return self->onlyNotified;
}

- (void)setOnlyResourceApts:(BOOL)_flag {
  self->onlyResourceApts = _flag;
}
- (BOOL)onlyResourceApts {
  return self->onlyResourceApts;
}

- (void)setAptTypes:(NSArray *)_aptTypes {
  ASSIGN(self->aptTypes,_aptTypes);
}
- (NSArray *)aptTypes {
  return self->aptTypes;
}

/* comparison */

- (BOOL)isEqualToAppointmentQualifier:(SkyAppointmentQualifier *)_other {
  if (self == _other)
    return YES;
  
  if (![self->startDate isEqual:[_other startDate]]) return NO;
  if (![self->endDate   isEqual:[_other endDate]])   return NO;
  if (![self->timeZone  isEqual:[_other timeZone]])  return NO;
  if (![self->resources isEqual:[_other resources]]) return NO;
  if (![self->companies isEqual:[_other companies]]) return NO;
  if (![self->personIds isEqual:[_other personIds]]) return NO;
  
  if (self->onlyNotified     != [_other onlyNotified])     return NO;
  if (self->onlyResourceApts != [_other onlyResourceApts]) return NO;
  
  if (!(((self->aptTypes == nil) && ([_other aptTypes] == nil)) ||
        [self->aptTypes isEqual:[_other aptTypes]])) return NO;
  
  return YES;
}

- (BOOL)isEqualToQualifier:(EOQualifier *)_other {
  if (self == (SkyAppointmentQualifier *)_other) 
    return YES;
  if (_other == nil)
    return NO;
  if (![_other isKindOfClass:[SkyAppointmentQualifier class]])
    return NO;

  return [self isEqualToAppointmentQualifier:
                 (SkyAppointmentQualifier *)_other];
}

@end /* SkyAppointmentQualifier */
