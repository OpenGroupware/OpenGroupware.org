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

#import "common.h"
#include <OGoFoundation/SkyEditorPage.h>
#include <OGoContacts/SkyEnterpriseDocument.h>

@interface SkyEnterpriseAttributesEditor : SkyEditorPage
{
  id patternName;
  NSArray *attributes;
}

@end /* SkyEnterpriseAttributesEditor */

@interface SkyEnterpriseAttributesEditor(PrivateMethodes)
- (NSString *)_violatedUniqueKeyName;
@end

@implementation SkyEnterpriseAttributesEditor

- (void)dealloc {
  [self->patternName release];
  [self->attributes release];
  [super dealloc];
}

- (id)enterprise {
  return [self object];
}

- (BOOL)checkConstraintsForSave {
  NSMutableString *error;
  NSString        *name;

  error = [NSMutableString stringWithCapacity:128];
  name = [[self enterprise] valueForKey:@"name"];
  
  if (name == nil || ![name isNotNull] || [name length] == 0)
    [error appendString:@" No name set."];

  if ([error length] > 0) {
    [self setErrorString:error];
    return NO;
  }
  else {
    [self setErrorString:nil];
    return [super checkConstraintsForSave];
  }
}

- (void)setPatternName:(id)_pattern {
  NSUserDefaults *ud;
  NSMutableArray *pats;
  NSEnumerator   *patEnum;
  NSString       *pat;

  if (_pattern == nil) return;

  ASSIGN(self->patternName, _pattern);

  ud  = [[self session] userDefaults];

  patEnum = [[[ud dictionaryForKey:@"enterprises_view_attributes"]
                  objectForKey:_pattern] objectEnumerator];

  pats    = [NSMutableArray arrayWithCapacity:32];

  while ((pat = [patEnum nextObject])) {
    if ([pat isEqualToString:@"description"])
      pat = @"name";
    [pats addObject:pat];
  }

  ASSIGN(self->attributes, pats);
}
- (id)patternName {
  return self->patternName;
}

- (NSArray *)attributes {
  return self->attributes;
}

- (NSArray *)addressTypes {
  NSArray        *types;
  NSMutableArray *result;
  int            i, count;

  types = [[self enterprise] valueForKey:@"addressTypes"];
  count = [types count];
  result = [NSMutableArray arrayWithCapacity:8];
  
  for (i = 0; i < count; i++) {
    NSString *type = [types objectAtIndex:i];

    if ([self->attributes containsObject:type]) {
      [result addObject:type];
    }
  }
  return result;
}

- (SkyDocument *)addressDocument {
  return [[self enterprise] addressForType:[self valueForKey:@"addressType"]];
}

- (BOOL)showComment {
  return [self->attributes containsObject:@"comment"];
}

- (BOOL)showContact {
  return [self->attributes containsObject:@"contact"];
}

- (BOOL)showCategory {
  return [self->attributes containsObject:@"keywords"];
}

- (id)save {
  NSString *key   = nil;
  id       result = nil;

  result = [super save];

  if (result)
    return result;
  else if ((key = [self _violatedUniqueKeyName])) {
    NSMutableString *str;
    id l;

    str = [[NSMutableString alloc] initWithCapacity:128];
    l = [self labels];

    [str appendString:[l valueForKey:@"couldNotSaveEnterprise"]];
    [str appendString:@". "];
    [str appendString:[l valueForKey:@"fieldMustBeUnique"]];
    [str appendString:@": "];
    [str appendString:[l valueForKey:key]];
    
    [self setErrorString:str];
  }
  return nil;
}

@end /* SkyEnterpriseAttributesEditor */

@implementation SkyEnterpriseAttributesEditor(PrivateMethodes)

- (BOOL)_isKeyViolated:(NSString *)_key {
  static id searchRec = nil;  
  NSArray   *list     = nil;
  unsigned  maxCount;

  maxCount = ([self isInNewMode]) ? 0 : 1;

  if (searchRec == nil) {
    searchRec = [self runCommand:@"search::newrecord",
                                  @"entity", @"Enterprise", nil];
    [searchRec setComparator:@"EQUAL"];
    [searchRec retain];
  }
  
  [searchRec takeValue:[[self object] valueForKey:_key] forKey:_key];
  list = [self runCommand:@"enterprise::extended-search",
               @"operator",       @"OR",
               @"searchRecords",  [NSArray arrayWithObject:searchRec],
               @"fetchIds",       [NSNumber numberWithBool:YES],
               @"maxSearchCount", [NSNumber numberWithInt:2],
               nil];
  
  return ([list count] > maxCount);
}

- (NSString *)_violatedUniqueKeyName {
  if ([self _isKeyViolated:@"number"])
    return @"number";
  
  return nil;
}

@end /* SkyEnterpriseAttributesEditor(PrivateMethodes) */
