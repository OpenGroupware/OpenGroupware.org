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

#include <OGoFoundation/OGoComponent.h>

@class NSArray;

@interface SkyImapMailPrintViewer : OGoComponent
{
  id      emailContent; // TODO: improve static typing
  id      object;
  NSArray *headers;
  id      header;       // TODO: improve static typing
}

@end /* SkyImapMailPrintViewer */

#include "common.h"
#include <NGMail/NGMimeMessage.h>

@implementation SkyImapMailPrintViewer

- (void)dealloc {
  [self->emailContent release];
  [self->object       release];
  [self->headers      release];
  [self->header       release];
  [super dealloc];  
}

/* accessors */

- (id)emailContent {
  return self->emailContent;
}

- (id)object {
  return self->object;
}

- (NSArray *)headers {
  if (self->headers)
    return self->headers;
  
  self->headers = [[[[self session] userDefaults] 
		     arrayForKey:@"mail_printviewer_headers"] copy];
  return self->headers;
}

- (void)setHeader:(id)_header {
  ASSIGN(self->header,_header);
}
- (id)header {
  return self->header;
}

- (NSString *)printTitle {
  NSString *tmp;
  
  tmp = [self->object valueForKey:@"subject"];
  return [tmp isNotNull] ? [@"OGo Mails: " stringByAppendingString:tmp] : nil;
}

- (id)headerLabel {
  return [[self labels] valueForKey:self->header];
}

- (NSString *)_formatDateValue:(NSCalendarDate *)_date {
  char buf[32];
  
  snprintf(buf, sizeof(buf), "%04i-%02i-%02i %02i:%02i",
           [_date yearOfCommonEra], [_date monthOfYear], [_date dayOfMonth],
           [_date hourOfDay], [_date minuteOfHour]);
  return [NSString stringWithCString:buf];
}

- (id)headerValue { // TODO: can we set typing to return an NSString?
  NSMutableString *ms;
  NSEnumerator    *e;
  id              one;

  ms = [NSMutableString stringWithCapacity:32];
  e  = [self->emailContent valuesOfHeaderFieldWithName:self->header];
  while ((one = [e nextObject]) != nil) {
    if ([one isKindOfClass:[NSCalendarDate class]])
      one = [self _formatDateValue:one];
    else if (![one isKindOfClass:[NSString class]])
      one = [one description];
    
    if ([ms isNotEmpty]) {
      [ms appendString:@", "];
      [ms appendString:[one stringValue]];
    }
    else
      [ms appendString:one];
  }
  return ms;
}

/* KVC */

- (void)takeValue:(id)_val forKey:(NSString *)_key {
  // TODO: is this required? (maybe due to the superclass?)
  if ([_key isEqualToString:@"object"]) {
    ASSIGN(self->object, _val);
  }
  else if ([_key isEqualToString:@"emailContent"]) {
    ASSIGN(self->emailContent,_val);
  }
  else
    [super takeValue:_val forKey:_key];
}

@end /* SkyImapMailPrintViewer */
