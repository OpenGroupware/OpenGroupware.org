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

#include <LSFoundation/LSDBObjectBaseCommand.h>

@class NSArray, NSTimeZone;

@interface LSGetAppointmentsForSourceUrls : LSDBObjectBaseCommand
{
  NSArray    *sourceUrls;
  NSArray    *attributes;
  NSTimeZone *timeZone;
  NSArray    *sortOrderings;
  NSString   *groupBy;
}

@end /* LSGetAppointmentsForSourceUrls */

#import <Foundation/Foundation.h>
#include <LSFoundation/LSCommandKeys.h>
#include <EOControl/EOControl.h>
#include <GDLAccess/GDLAccess.h>
#include "common.h"

@implementation LSGetAppointmentsForSourceUrls

- (NSString *)entityName {
  return @"Date";
}

- (void)dealloc {
  [self->groupBy       release];
  [self->sortOrderings release];
  [self->timeZone      release];
  [self->attributes    release];
  [self->sourceUrls    release];
  [super dealloc];
}

- (NSArray *)_fetchGIDsForUrls:(NSArray *)_urls inContext:(id)_context {
  // TODO: split up method
  NSMutableArray    *gids;
  unsigned          urlCount, batchSize, i;
  EOAdaptorChannel  *adCh;
  NSArray           *attrs;
  NSString          *pKeyName;
  EOAttribute       *sourceUrlAttr;
  EOEntity          *entity;

  if ((urlCount = [_urls count]) == 0)
    return [NSArray array];

  if ((adCh = [[_context valueForKey:LSDatabaseChannelKey] adaptorChannel])
      == nil)
    [self assert:(adCh != nil) reason:@"missing database channel"];

  entity        = [self entity];
  pKeyName      = [[entity primaryKeyAttributeNames] objectAtIndex:0];
  sourceUrlAttr = [entity attributeNamed:@"sourceUrl"];
  attrs =
    [NSArray arrayWithObjects:[entity attributeNamed:pKeyName],
             sourceUrlAttr, nil];

  batchSize = urlCount > 200 ? 200 : urlCount;
  gids      = nil;
  for (i = 0; i < urlCount; i += batchSize) {
    /* building qualifier */
    NSMutableString   *in;
    EOSQLQualifier    *q;
    unsigned        j, addCount;
    BOOL            ok;
    id              record;

    in = [[NSMutableString alloc] initWithCapacity:batchSize*4];
    [in appendString:@"sourceUrl IN ("];
    for (j = i, addCount = 0; (j < (i + batchSize)) && (j < urlCount); j++) {
      NSString *s;
      
      s = [_urls objectAtIndex:j];
      
      if ([s length] == 0) {
        [self logWithFormat:@"got weird sourceUrl: %@", s];
        continue;
      }
      
#if LIB_FOUNDATION_LIBRARY
      if ([s rangeOfString:@"'"].length > 0)
        // TODO: improve that
        s = [s stringByReplacingString:@"'" withString:@"\\'"];
#else
#  warning FIXME: incorrect implementation on this Foundation library!
#endif
      
      if (addCount != 0)
        [in appendString:@","];
      [in appendString:@"'"];
      [in appendString:s];
      [in appendString:@"'"];
      addCount++;
    }
    [in appendString:@")"];

    if (addCount == 0)
      [self logWithFormat:@"did not add any sourceUrl to IN query !"];

    q = [[EOSQLQualifier alloc] initWithEntity:[self entity]
                                qualifierFormat:in];
    [in release]; in = nil;

    ok = [adCh selectAttributes:attrs
               describedByQualifier:q
               fetchOrder:nil
               lock:NO];
    [q release]; q = nil;
    
    if (!ok) [self assert:ok format:@"couldn't select objects by sourceUrl"];

    if (gids == nil)
      gids = [NSMutableArray arrayWithCapacity:urlCount];

    while ((record = [adCh fetchAttributes:attrs withZone:NULL])) {
      NSString   *pKey;
      EOGlobalID *gid;
      
      pKey = [record valueForKey:pKeyName];
      gid  = [EOKeyGlobalID globalIDWithEntityName:[self entityName]
                            keys:&pKey keyCount:1 zone:NULL];
      
      [gids addObject:gid];
    }
  }

  return gids;
}

- (void)_executeInContext:(id)_context {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSArray *result;

  result = [self _fetchGIDsForUrls:self->sourceUrls inContext:_context];
  result = LSRunCommandV(_context,
                         @"appointment",   @"get-by-globalid",
                         @"gids",          result,
                         @"attributes",    self->attributes,
                         @"timeZone",      self->timeZone,
                         @"sortOrderings", self->sortOrderings,
                         @"groupBy",       self->groupBy,
                         nil);
  [self setReturnValue:result];
  [pool release]; pool = nil;
}

/* accessors */

- (void)setSourceUrls:(NSArray *)_urls {
  if (self->sourceUrls != _urls) {
    id tmp = self->sourceUrls;
    self->sourceUrls = [_urls copy];
    [tmp release]; tmp = nil;
  }
}
- (NSArray *)sourceUrls {
  return self->sourceUrls;
}

- (void)setSourceUrl:(NSString *)_url {
  [self setSourceUrls:[NSArray arrayWithObject:_url]];
}
- (NSString *)sourceUrl {
  return [self->sourceUrls lastObject];
}

- (void)setAttributes:(NSArray *)_attributes {
  ASSIGN(self->attributes, _attributes);
}
- (NSArray *)attributes {
  return self->attributes;
}

- (void)setTimeZone:(NSTimeZone *)_tz {
  ASSIGN(self->timeZone, _tz);
}
- (NSTimeZone *)timeZone {
  return self->timeZone;
}

- (void)setSortOrderings:(NSArray *)_orderings {
  ASSIGN(self->sortOrderings, _orderings);
}
- (NSArray *)sortOrderings {
  return self->sortOrderings;
}

/* key-value coding */

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"sourceUrl"])
    [self setSourceUrl:_value];
  else if ([_key isEqualToString:@"sourceUrls"])
    [self setSourceUrls:_value];
  else if ([_key isEqualToString:@"attributes"])
    [self setAttributes:_value];
  else if ([_key isEqualToString:@"groupBy"]) {
    ASSIGN(self->groupBy, _value);
  }
  else if ([_key isEqualToString:@"sortOrderings"])
    [self setSortOrderings:_value];
  else if ([_key isEqualToString:@"sortOrdering"])
    [self setSortOrderings:[NSArray arrayWithObject:_value]];
  else if ([_key isEqualToString:@"timeZone"])
    [self setTimeZone:_value];
  else if ([_key isEqualToString:@"timeZoneName"]) {
    id tz;
    tz = _value ? [NSTimeZone timeZoneWithAbbreviation:_value] : nil;
    [self setTimeZone:tz];
  }
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  id v;
  
  if ([_key isEqualToString:@"sourceUrl"])
    v = [self sourceUrl];
  else if ([_key isEqualToString:@"sourceUrls"])
    v = [self sourceUrls];
  else if ([_key isEqualToString:@"attributes"])
    v = [self attributes];
  else if ([_key isEqualToString:@"groupBy"])
    v = self->groupBy;
  else if ([_key isEqualToString:@"sortOrderings"])
    v = [self sortOrderings];
  else if ([_key isEqualToString:@"sortOrdering"]) {
    v = [self sortOrderings];
    v = [v objectAtIndex:0];
  }
  else if ([_key isEqualToString:@"timeZone"])
    v = [self timeZone];
  else if ([_key isEqualToString:@"timeZoneName"])
    v = [[self timeZone] abbreviation];
  else 
    v = [super valueForKey:_key];
  
  return v;
}

@end /* LSGetAppointmentsForSourceUrls */
