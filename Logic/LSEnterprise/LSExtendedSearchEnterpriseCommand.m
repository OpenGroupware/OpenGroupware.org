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

#include <LSSearch/LSExtendedSearchCommand.h>
#include <LSSearch/LSGenericSearchRecord.h>

@interface LSExtendedSearchEnterpriseCommand : LSExtendedSearchCommand
{
  NSArray *attributes;
  /* you can define groups of attributes to fetch, e.g.
       "telephones",
       "extendedAttributes"
  */
  NSString *keyword; // build special qualifiers for keywords
  NSString *keywordComparator;
}
@end

#include "common.h"

@interface NSObject(LSExtendedSearchEnterpriseCommand)
- (NSNumber *)fetchIds;
- (NSString *)operator;
@end

@implementation LSExtendedSearchEnterpriseCommand

+ (int)version {
  return [super version] /* v2 */;
}
+ (void)initialize {
  NSAssert2([super version] == 2,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (void)dealloc {
  [self->attributes release];
  [self->keyword    release];
  [self->keywordComparator release];
  [super dealloc];
}

- (EOSQLQualifier *)extendedSearchQualifier:(void *)_context {
  EOSQLQualifier *qualifier;
  EOSQLQualifier *q;
  NSString       *format;
  NSString       *sqlOperator;
  NSString       *keyw;
  
  qualifier = [super extendedSearchQualifier:_context];
  if (![self->keyword isNotNull])
    return qualifier;
  
  if ([self->keywordComparator isEqualToString:@"EQUAL"])
    sqlOperator = @"=";
  else {
    sqlOperator = [self->keywordComparator length]
      ? self->keywordComparator : @"LIKE";
  }
  keyw = [self->keyword lowercaseString];
  
  /* create keyword qualifier */
  
  format = [[NSString alloc] initWithFormat:
                @"("
                @"lower(%%A) %@ '%%@' OR "
                @"lower(%%A) %@ '%%%%, %%@' OR "
                @"lower(%%A) %@ '%%%%, %%@, %%%%' OR "
                @"lower(%%A) %@ '%%@, %%%%'"
                @")", sqlOperator, sqlOperator, sqlOperator, sqlOperator];
  
  q = [[EOSQLQualifier alloc] initWithEntity:[qualifier entity]
                              qualifierFormat:format,
                                @"keywords", keyw,
                                @"keywords", keyw,
                                @"keywords", keyw,
                                @"keywords", keyw];
  [format release];

  /* join keyword qualifier */
  
  if ([[self operator] isEqualToString:@"OR"])
    [qualifier disjoinWithQualifier:q];
  else
    [qualifier conjoinWithQualifier:q];
  [q release]; q = nil;
  
  return qualifier;
}

/* command methods */

- (void)setKeyword:(NSString *)_keyword {
  ASSIGNCOPY(self->keyword,_keyword);
}
- (void)setKeywordComparator:(NSString *)_cmp {
  ASSIGNCOPY(self->keywordComparator,_cmp);
}

- (void)_checkRecordsForKeywords {
  NSArray               *records;
  LSGenericSearchRecord *record;
  unsigned max, i;

  [self->keyword release]; self->keyword = nil;
  
  records = [self searchRecordList];
  for (i = 0, max = [records count]; i < max; i++) {
    NSString *keyw;
    
    record = [records objectAtIndex:i];
    
    if (![[[record entity] name] isEqualToString:[self entityName]])
      continue;
    
    keyw = [record valueForKey:@"keywords"];
    if ([keyw length] == 0)
      continue;

#if LIB_FOUNDATION_LIBRARY      
    keyw = [keyw stringByReplacingString:@"*" withString:@"%"];
#else
#  warning FIXME: incorrect implementation on this Foundation library
#endif
    [self setKeyword:keyw];
    [self setKeywordComparator:[record comparator]];
    if ([[self operator] isEqualToString:@"OR"])
      [record removeObjectForKey:@"keywords"];
    else
      [record takeValue:@"*" forKey:@"keywords"];
  }
}

- (void)_prepareForExecutionInContext:(id)_context {
  [super _prepareForExecutionInContext:_context];
  [self _checkRecordsForKeywords];
}

- (BOOL)_shouldFetchExtendedAttributes {
  if (self->attributes == nil)
    return YES;
  return [self->attributes containsObject:@"extendedAttributes"];
}
- (BOOL)_shouldFetchPhones {
  if (self->attributes == nil)
    return YES;
  return [self->attributes containsObject:@"telephones"];
}

- (void)_executeInContext:(id)_context {
  [super _executeInContext:_context];

#if 0 /* HH: why is this commented out? */
  [self setObject:LSRunCommandV(_context,
                                @"enterprise", @"check-permission",
                                @"object", [self object], nil)];
#endif

  if ([self fetchGlobalIDs]) return;
  
  if ([[self fetchIds] boolValue])
    return;
  
  if ([self _shouldFetchExtendedAttributes]) {
    LSRunCommandV(_context, @"enterprise", @"get-extattrs",
                  @"objects", [self object],
                  @"relationKey", @"companyValue", nil);
  }
  if ([self _shouldFetchPhones]) {
    LSRunCommandV(_context, @"enterprise", @"get-telephones",
                  @"objects", [self object],
                  @"relationKey", @"telephones", nil);
  }
}

- (NSString *)entityName {
  return @"Enterprise";
}

- (void)setAttributes:(NSArray *)_attributes {
  ASSIGN(self->attributes, _attributes);
}

- (NSArray *)attributes {
  return self->attributes;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"attributes"])
    [self setAttributes:_value ];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"attributes"])
    return [self attributes];
  
  return [super valueForKey:_key];
}

@end /* LSExtendedSearchEnterpriseCommand */
