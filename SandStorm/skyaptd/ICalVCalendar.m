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

#include "ICalVCalendar.h"
#include "common.h"

@implementation ICalVCalendar

- (id)initWithMethod:(ICalVCalendarMethod)_method
  productId:(NSString *)_pid
  version:(int)_major:(int)_minor
  subComponents:(NSArray *)_subcomponents
{
  if ((self = [super init])) {
    self->method = _method;
    
    if (_method > 0) {
      /* is method required for VCalendar ??, then release and return nil */
      const char *cstr;
      cstr = icalenum_method_to_string(_method);
      self->methodString = [[NSString alloc] initWithCString:cstr];
    }
    
    self->productId     = [_pid copy];
    self->majorVersion  = _major;
    self->minorVersion  = _minor;
    self->subComponents = [_subcomponents shallowCopy];
  }
  return self;
}
- (id)init {
  return [self initWithMethod:-1
               productId:nil
               version:0:0
               subComponents:nil];
}

- (void)dealloc {
  RELEASE(self->productId);
  RELEASE(self->subComponents);
  [super dealloc];
}

/* accessors */

- (int)majorVersion {
  return self->majorVersion;
}
- (int)minorVersion {
  return self->minorVersion;
}

- (NSString *)productId {
  return self->productId;
}
- (BOOL)isOutlook {
  return [self->productId indexOfString:@"//Microsoft Corporation//Outlook"]
    != NSNotFound ? YES : NO;
}
- (BOOL)isGnomeCalendar {
  return [self->productId indexOfString:@"-//GNOME//NONSGML GnomeCalendar"]
    != NSNotFound ? YES : NO;
}

- (BOOL)isAppleiCal {
  if ([self->productId indexOfString:@"-//Apple Computer"] == NSNotFound)
    return NO;
  return [self->productId indexOfString:@"iCal"] != NSNotFound ? YES : NO;
}

- (NSString *)externalName {
  return @"VCALENDAR";
}

- (NSArray *)subComponents {
  return self->subComponents;
}

/* description */

- (NSString *)icalStringForProperties {
  NSMutableString *ms;

  ms = [NSMutableString stringWithCapacity:64];

  if (self->productId) {
    [ms appendString:@"PRODID:"];
    [ms appendString:self->productId];
    [ms appendString:@"\r\n"];
  }
  if (self->majorVersion >= 0) {
    [ms appendFormat:@"VERSION:%i.%i\r\n",
          self->majorVersion, self->minorVersion];
  }
  if (self->methodString) {
    [ms appendString:@"METHOD:"];
    [ms appendString:self->methodString];
    [ms appendString:@"\r\n"];
  }
  
  return ms;
}

@end /* ICalVCalendar */
