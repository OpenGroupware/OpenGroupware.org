/*
  Copyright (C) 2000-2006 SKYRIX Software AG
  Copyright (C) 2006      Helge Hess

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

#include <OGoFoundation/SkyEditorPage.h>

@class NSString, NSArray;

@interface SkyPersonAttributesEditor : SkyEditorPage
{
  NSString *patternName;
  NSArray  *attributes;
}

@end

#include "common.h"
#include <NGMime/NGMimeType.h>
#include <GDLAccess/EONull.h>
#include <OGoContacts/SkyPersonDocument.h>

@interface SkyPersonAttributesEditor(PrivateMethodes)
- (NSString *)_violatedUniqueKeyName;
@end

@implementation SkyPersonAttributesEditor

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cfg
{
  BOOL r;

  r = [super prepareForActivationCommand:_command
	     type:_type configuration:_cfg];
  if (!r) return NO;
  
  if (![[self object] isKindOfClass:[SkyDocument class]]) {
    id obj = [[self object] globalID];
    
    [self warnWithFormat:@"got no doc, fetch object by global-id: %@", obj];
    obj = [self runCommand:@"object::get-by-globalid", @"gid", obj, nil];
    obj = [obj lastObject];
    [self setObject:obj];
    // TODO: hm, this is still not a document? (commands do not return docs?!)
  }

  {
    id obj = [self object];
    
    if ([obj respondsToSelector:@selector(setBirthday:)] &&
        ![[obj valueForKey:@"birthday"] isNotNull]) {
      [obj setBirthday:(id)[EONull null]];
    }
  }

#if 0
#warning DEBUG LOG, REMOVE ME
  [self logWithFormat:@"WORK ON: %@", [self object]];
#endif

  return YES;
}

- (void)dealloc {
  [self->patternName release];
  [self->attributes  release];
  [super dealloc];
}

/* accessors */

- (id)person {
  return [self object];
}

- (void)setPatternName:(NSString *)_pattern {
  NSUserDefaults *ud;
  NSMutableArray *pats;
  NSEnumerator   *patEnum;
  NSString       *pat;
  
  if (_pattern == nil) return;
  
  ASSIGNCOPY(self->patternName, _pattern);
  
  ud      = [[self session] userDefaults];
  patEnum = [[[ud dictionaryForKey:@"persons_view_attributes"]
                  objectForKey:_pattern] objectEnumerator];
  pats    = [NSMutableArray arrayWithCapacity:32];
  while ((pat = [patEnum nextObject]) != nil) {
    if ([pat isEqualToString:@"description"])
      pat = @"nickname";
    [pats addObject:pat];
  }
  
  ASSIGNCOPY(self->attributes, pats);
}
- (NSString *)patternName {
  return self->patternName;
}

- (NSArray *)attributes {
  return self->attributes;
}

- (NSArray *)addressTypes {
  NSArray        *types;
  NSMutableArray *result;
  unsigned       i, count;
  
  types  = [[self person] addressTypes];
  result = [NSMutableArray arrayWithCapacity:4];
  
  for (i = 0, count  = [types count]; i < count; i++) {
    NSString *type = [types objectAtIndex:i];
    
    if ([self->attributes containsObject:type])
      [result addObject:type];
  }
  return result;
}

- (SkyDocument *)addressDocument {
  return [[self person] addressForType:[self valueForKey:@"addressType"]];
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

/* callback for LSWObjectEditor */

- (id)couldNotFormatBirthday {
  [[self person] setBirthday:nil];
  return nil;
}

- (BOOL)checkConstraintsForSave {
  if ([[self person] birthday] == nil) {// should be an EONull, if not set
    [self setErrorString:@"Birthday format is incorrect!"];
    return NO;
  }

  [self setErrorString:nil];
  return [super checkConstraintsForSave];
}

/* operations */

- (id)_handleUniqueKeyError:(NSString *)_key {
  NSMutableString *str;
  
  str = [[NSMutableString alloc] initWithCapacity:128];
  [str appendString:[[self labels] valueForKey:@"couldNotSavePerson"]];
  [str appendString:@". "];
  [str appendString:[[self labels] valueForKey:@"fieldMustBeUnique"]];
  [str appendString:@": "];
  [str appendString:[[self labels] valueForKey:_key]];
  [self setErrorString:str];
  [str release];
  return nil;
}

- (id)save {
  NSString *key;
  id       result;

#if 0
#warning DEBUG LOG, REMOVE ME
  [self logWithFormat:@"SAVE: %@", [self object]];
  [self logWithFormat:@"  PAT: %@: %@", [self patternName], [self attributes]];
#endif

  result = [super save];
  
  if (result != nil)
    return result;
  if ((key = [self _violatedUniqueKeyName]) != nil)
    return [self _handleUniqueKeyError:key];

#if 0
#warning DEBUG LOG, REMOVE ME
  [self logWithFormat:@"DID SAVE: %@", [self object]];

  [[self object] reload];
#endif
  
  return nil;
}

/* PrivateMethodes */

- (BOOL)_isKeyViolated:(NSString *)_key {
  static id searchRec = nil;  
  NSArray   *list;
  unsigned  maxCount;

  maxCount = ([self isInNewMode]) ? 0 : 1;

  // TODO: explain what this does
  if (searchRec == nil) {
    searchRec = [[self runCommand:@"search::newrecord",
		         @"entity", @"Person", nil] retain];
    [searchRec setComparator:@"EQUAL"];
  }
  
  [searchRec takeValue:[[self object] valueForKey:_key] forKey:_key];
  list = [self runCommand:@"person::extended-search",
               @"operator",       @"OR",
               @"searchRecords",  [NSArray arrayWithObject:searchRec],
               @"fetchIds",       [NSNumber numberWithBool:YES],
               @"maxSearchCount", [NSNumber numberWithInt:2],
               nil];
  
  return ([list count] > maxCount) ? YES : NO;
}

- (NSString *)_violatedUniqueKeyName {
  if ([self _isKeyViolated:@"number"])
    return @"number";
  if ([self _isKeyViolated:@"login"])
    return @"login";
  
  return nil;
}

@end /* SkyPersonAttributesEditor */
