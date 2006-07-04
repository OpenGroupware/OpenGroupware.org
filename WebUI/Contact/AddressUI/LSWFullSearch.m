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

@class NSString;
@class EOQualifier;

/*
  LSWFullSearch
  
  Eg this is used by the LSWPersons and LSWEnterprises components.
*/

@interface LSWFullSearch : OGoComponent
{
@private
  NSString    *searchString;
  NSString    *limitedString;
  NSString    *joinMode;
  BOOL        isSearchLimited;
  EOQualifier *qualifier;
}

- (EOQualifier *)qualifierForFulltextSearchString:(NSString *)_string;

@end

#include <NGExtensions/NSString+Ext.h>
#include "common.h"

@implementation LSWFullSearch

static EOQualifier *matchAllQualifier = nil;
static EOQualifier *matchNilQualifier = nil;
static BOOL enableMultiSearch = YES;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  enableMultiSearch = ![ud boolForKey:@"DisableOGoFullTextMultiSearch"];
  if (!enableMultiSearch)
    NSLog(@"Note: fulltext multisearch disabled.");

  if (matchAllQualifier == nil) {
    matchAllQualifier = 
      [[EOKeyValueQualifier alloc] initWithKey:@"fullSearchString"
                                   operatorSelector:EOQualifierOperatorLike
                                   value:@""];
  }
  if (matchNilQualifier == nil) {
    matchNilQualifier = 
      [[EOKeyValueQualifier alloc] initWithKey:@"fullSearchString"
                                   operatorSelector:EOQualifierOperatorLike
                                   value:nil];
  }
}

- (void)dealloc {
  [self->qualifier     release];
  [self->joinMode      release];
  [self->limitedString release];
  [self->searchString  release];
  [super dealloc];
}

/* constructing the qualifier */

- (BOOL)isMultiSearchEnabled {
  return enableMultiSearch;
}
- (Class)multiSearchJoinClass {
  if ([self->joinMode isEqualToString:@"or"])
    return [EOOrQualifier class];
  
  return [EOAndQualifier class];
}

- (EOQualifier *)qualifierForFulltextSearchStrings:(NSArray *)_strings {
  NSMutableArray *qualifiers;
  EOQualifier    *q;
  unsigned i, count;
  
  if ((count = [_strings count]) == 0)
    return nil;
  if (count == 1)
    return [self qualifierForFulltextSearchString:[_strings objectAtIndex:0]];
  
  qualifiers = [NSMutableArray arrayWithCapacity:(count + 1)];
  for (i = 0; i < count; i++) {
    EOQualifier *q;
    NSString *s;
    
    s = [_strings objectAtIndex:i];
    if ([s length] == 0) 
      continue;
    
    if ((q = [self qualifierForFulltextSearchString:s]) == nil)
      continue;
    
    [qualifiers addObject:q];
  }
  
  if ((count = [qualifiers count]) == 0)
    return nil;
  if (count == 1)
    return [qualifiers objectAtIndex:0];
  
  q = [[[self multiSearchJoinClass] alloc] initWithQualifierArray:qualifiers];
  return [q autorelease];
}

- (EOQualifier *)qualifierForFulltextSearchString:(NSString *)_string {
  if ((_string = [_string stringByTrimmingSpaces]) == nil)
    return matchNilQualifier;
  
  if ([self isMultiSearchEnabled]) {
    if ([_string length] > 1 && [_string rangeOfString:@" "].length > 0) {
      NSArray *strings;
      
      strings = [_string componentsSeparatedByString:@" "];
      [self debugWithFormat:@"multisearch strings: %@", strings];
      return [self qualifierForFulltextSearchStrings:strings];
    }
  }
  
  if ([_string length] == 0 || [_string isEqualToString:@"%"]
      || [_string isEqualToString:@"*"])
    return matchAllQualifier;
  
  return [[EOKeyValueQualifier alloc] initWithKey:@"fullSearchString"
                                      operatorSelector:EOQualifierOperatorLike
                                      value:_string];
}

/* accessors */

- (void)setSearchString:(NSString *)_searchString {
  if ([self->searchString isEqualToString:_searchString])
    return;
  
  ASSIGNCOPY(self->searchString, _searchString);
  [self->qualifier release]; self->qualifier = nil;
}
- (id)searchString {
  return self->searchString;
}

- (void)setJoinMode:(NSString *)_str {
  if ([self->joinMode isEqualToString:_str]) return;
  
  ASSIGNCOPY(self->joinMode, _str);
  [self->qualifier release]; self->qualifier = nil;
}
- (id)joinMode {
  return [self->joinMode isNotEmpty] ? self->joinMode : (NSString *)@"and";
}

- (void)setLimitedString:(NSString *)_limitedString {
  ASSIGNCOPY(self->limitedString, _limitedString);
}
- (id)limitedString {
  return self->limitedString;
}

- (void)setIsSearchLimited:(BOOL)_isSearchLimited {
  self->isSearchLimited = _isSearchLimited;
}
- (BOOL)isSearchLimited {
  return self->isSearchLimited;
}

- (void)setQualifier:(EOQualifier *)_q {
  /* Note: do nothing, intentional, calculated accessors */
}
- (EOQualifier *)qualifier {
  /* Note: there is a difference between empty string and nil string! */
  if (self->qualifier)
    return self->qualifier;
  
  self->qualifier = 
    [[self qualifierForFulltextSearchString:[self searchString]] retain];
  return self->qualifier;
}

/* actions */

- (id)search {
  [self debugWithFormat:@"invoke 'fullSearch' in parent .."];
  return [self performParentAction:@"fullSearch"];
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return NO;
}

@end /* LSWFullSearch */
