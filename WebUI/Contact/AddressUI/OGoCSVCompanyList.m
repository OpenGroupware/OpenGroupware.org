/*
  Copyright (C) 2026 Helge Hess

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

@interface OGoCSVCompanyList : OGoListComponent
{
  id                  labels;
  NSMutableDictionary *_companyCache;
}

@end

#include "common.h"
#include <OGoContacts/SkyCompanyDocument.h>
#include <OGoContacts/SkyPersonDocument.h>
#include <OGoContacts/SkyEnterpriseDocument.h>

@implementation OGoCSVCompanyList

+ (int)version {
  return [super version] + 0 /* v4 */;
}
+ (void)initialize {
  NSAssert2([super version] == 4,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (void)dealloc {
  [self->_companyCache release];
  [self->labels release];
  [super dealloc];
}

/* notifications */

- (void)sleep {
  [self->_companyCache release];
  self->_companyCache = nil;
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
  if ([self->configKey rangeOfString:@"person"]
        .length > 0)
    return @"person_defaultlist";
  if ([self->configKey rangeOfString:@"enterprise"]
        .length > 0)
    return @"enterprise_defaultlist";

  return nil;
}

/* company column support */

- (NSArray *)_enterprisesForCurrentItem {
  NSNumber *pid;
  NSArray  *cached;

  pid = [[self item] companyId];
  if (pid == nil) return nil;

  if (self->_companyCache == nil) {
    self->_companyCache =
      [[NSMutableDictionary alloc]
          initWithCapacity:32];
  }

  cached = [self->_companyCache objectForKey:pid];
  if (cached == nil) {
    NSArray        *all;
    NSMutableArray *filtered;
    unsigned       i, count;

    all = [[[self item] enterpriseDataSource]
              fetchObjects];
    count    = [all count];
    filtered = [NSMutableArray arrayWithCapacity:count];
    for (i = 0; i < count; i++) {
      SkyEnterpriseDocument *ent;
      ent = [all objectAtIndex:i];
      if ([ent isEnterprise])
        [filtered addObject:ent];
    }
    [self->_companyCache setObject:filtered forKey:pid];
    cached = filtered;
  }
  return cached;
}

/* column values */

- (id)currentColumnValue {
  NSString *col = [self currentColumn];

  if ([col hasPrefix:@"company."]) {
    NSArray        *ents;
    NSMutableArray *values;
    NSString       *attr;
    unsigned       i, count;

    attr  = [col substringFromIndex:8];
    ents  = [self _enterprisesForCurrentItem];
    count = [ents count];
    if (count == 0) return @"";

    values = [NSMutableArray arrayWithCapacity:count];
    for (i = 0; i < count; i++) {
      NSString *v;
      v = [[ents objectAtIndex:i] valueForKey:attr];
      if ([v isNotEmpty]) [values addObject:v];
    }
    [values sortUsingSelector:
        @selector(caseInsensitiveCompare:)];
    return [values componentsJoinedByString:@", "];
  }
  return [super currentColumnValue];
}

/* CSV helpers */

- (void)appendCSVEscaped:(NSString *)_s toResponse:(WOResponse *)_r {
  NSRange commaRange, quoteRange, nlRange;

  if (_s == nil) _s = @"";

  commaRange = [_s rangeOfString:@","];
  quoteRange = [_s rangeOfString:@"\""];
  nlRange    = [_s rangeOfString:@"\n"];

  if (commaRange.length == 0
      && quoteRange.length == 0
      && nlRange.length == 0)
  {
    [_r appendContentString:_s];
    return;
  }

  /* needs quoting */
  [_r appendContentString:@"\""];
  if (quoteRange.length > 0) {
    _s = [_s stringByReplacingString:@"\"" withString:@"\"\""];
  }
  [_r appendContentString:_s];
  [_r appendContentString:@"\""];
}

/* response generation */

- (WOResponse *)generateResponse {
  WOResponse *r;
  NSArray    *items, *columns;
  unsigned   i, j, iCount, jCount;

  r = [WOResponse responseWithRequest:[[self context] request]];
  [r setHeader:@"text/csv; charset=utf-8" forKey:@"content-type"];
  [r setHeader:@"attachment; filename=\"contacts.csv\""
        forKey:@"content-disposition"];

  items   = [[self dataSource] fetchObjects];
  columns = [self configList];
  iCount  = [items count];
  jCount  = [columns count];

  /* header row */
  [self appendCSVEscaped:@"Name" toResponse:r];
  for (j = 0; j < jCount; j++) {
    [self setCurrentColumn:[columns objectAtIndex:j]];
    [r appendContentString:@","];
    [self appendCSVEscaped:[self currentColumnLabel] toResponse:r];
  }
  [r appendContentString:@"\r\n"];

  /* data rows */
  for (i = 0; i < iCount; i++) {
    id obj, val;

    obj = [items objectAtIndex:i];
    [self setItem:obj];

    val = [obj valueForKey:@"name"];
    [self appendCSVEscaped:(val ? [val description] : @"") toResponse:r];

    for (j = 0; j < jCount; j++) {
      NSString *s;

      [self setCurrentColumn:[columns objectAtIndex:j]];
      [r appendContentString:@","];

      val = [self currentColumnValue];
      s   = val ? [val description] : @"";
      [self appendCSVEscaped:s toResponse:r];
    }
    [r appendContentString:@"\r\n"];
  }

  return r;
}

@end /* OGoCSVCompanyList */
