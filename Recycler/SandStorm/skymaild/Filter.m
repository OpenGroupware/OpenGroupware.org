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

#include "Filter.h"
#include "common.h"

@implementation Filter

+ (Filter *)filter {
  return AUTORELEASE([[Filter alloc] init]);
}

+ (Filter *)filterWithDictionary:(NSDictionary *)_dict {
  Filter         *filter = nil;
  NSEnumerator   *enu    = nil;
  NSDictionary   *obj    = nil;
  NSMutableArray *ma     = nil;
  FilterEntry    *entry  = nil;

  filter = [[Filter alloc] init];

  [filter setFilterName:[_dict objectForKey:@"name"]];
  [filter setFilterPos:[[_dict objectForKey:@"filterPos"] intValue]];
  [filter setFolder:[_dict objectForKey:@"folder"]];
  [filter setMatch:[_dict objectForKey:@"match"]];

  ma = [NSMutableArray arrayWithCapacity:1];

  enu = [[_dict objectForKey:@"entries"] objectEnumerator];
  while ((obj = [enu nextObject])) {
    entry = [FilterEntry filterEntryWithString:[obj objectForKey:@"string"]
                         headerField:[obj objectForKey:@"headerField"]
                         filterKind:[obj objectForKey:@"filterKind"]];
    [ma addObject:entry];
  }

  [filter setEntries:ma];

  return AUTORELEASE(filter);
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->filterName);
  RELEASE(self->folder);
  RELEASE(self->match);
  RELEASE(self->entries);

  [super dealloc];
}
#endif

- (NSDictionary *)dictionaryRepresentation {
  NSMutableDictionary *dict  = nil;
  NSMutableArray      *ma    = nil;
  FilterEntry         *entry = nil;
  NSEnumerator        *enu   = nil;

  dict = [NSMutableDictionary dictionaryWithCapacity:5];
  ma = [NSMutableArray array];

  enu = [[self entries] objectEnumerator];
  while ((entry = [enu nextObject])) {
    NSMutableDictionary *entryDict = nil;

    entryDict = [NSMutableDictionary dictionaryWithCapacity:3];

    [entryDict setObject:[entry filterKind]  forKey:@"filterKind"];
    [entryDict setObject:[entry headerField] forKey:@"headerField"];
    [entryDict setObject:[entry string]      forKey:@"string"];

    [ma addObject:entryDict];
  }

  [dict setObject:ma forKey:@"entries"];
  [dict setObject:[NSNumber numberWithInt:[self filterPos]]
        forKey:@"filterPos"];
  [dict setObject:[self folder]     forKey:@"folder"];
  [dict setObject:[self match]      forKey:@"match"];
  [dict setObject:[self filterName] forKey:@"name"];

  return AUTORELEASE([dict copy]);
}

- (void)setFilterName:(NSString *)_filterName {
  ASSIGN(self->filterName, _filterName);
}
- (NSString *)filterName {
  return self->filterName;
}

- (void)setFilterPos:(int)_filterPos {
  self->filterPos = _filterPos;
}
- (int)filterPos {
  return self->filterPos;
}

- (void)setFolder:(NSString *)_folder {
  ASSIGN(self->folder, _folder);
}
- (NSString *)folder {
  return self->folder;
}

- (void)setActive:(BOOL)_active {
  self->active = _active;
}
- (BOOL)active {
  return self->active;
}

- (void)setAction:(NSString *)_action {
  if ([_action isNotNull]) {
    if ([_action isEqualToString:@"copy"] ||
        [_action isEqualToString:@"move"] ||
        [_action isEqualToString:@"delete"] ||
        [_action isEqualToString:@"forward"])
      ASSIGN(self->action, _action);
  } else {
    NSLog(@"%s unknown action %@", __PRETTY_FUNCTION__, _action);
  }
}
- (NSString *)action {
  return self->action;
}

- (void)setMatch:(NSString *)_match {
  ASSIGN(self->match, _match);
}
- (NSString *)match {
  return self->match;
}

- (void)setEntries:(NSArray *)_entries {
  ASSIGN(self->entries, _entries);
}
- (NSArray *)entries {
  return self->entries;
}

- (BOOL)isEqualToFilter:(Filter *)_filter {
  NSString *a, *b;

  a = [[self dictionaryRepresentation] descriptionInStringsFileFormat];
  b = [[_filter dictionaryRepresentation] descriptionInStringsFileFormat];
  if ([a isEqualTo:b])
    return YES;

  return NO;
}

- (BOOL)isEqual:(id)_obj {
  if (! [_obj isKindOfClass:[self class]])
    return NO;

  return [self isEqualToFilter:_obj];
}

- (NSString *)description {
  return [NSString stringWithFormat:
                   @"<%@> filterPos=%d, filterName=%@, entries=%@, match=%@, "
                   @"folder=%@",
                   NSStringFromClass([self class]),
                   [self filterPos], [self filterName], [self entries],
                   [self match], [self folder]];
}

@end // Filter
