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

#include <LSSearch/LSExtendedSearchCommand.h>

/*
  person::extended-search
  
  TODO: document parameters
*/

@class NSString, NSArray, NSDictionary;

@interface LSExtendedSearchPersonCommand : LSExtendedSearchCommand
{
  NSDictionary *searchAttributes;
  BOOL         withoutAccounts;
  NSArray      *attributes;
  /* you can define groups of attributes to fetch, e.g.
       "telephones" and
       "extendedAttributes"
  */
  NSString     *keyword; // build special qualifiers for keywords
  NSString     *keywordComparator;
}
@end

#include "common.h"
#include <LSSearch/LSGenericSearchRecord.h>

@interface NSObject(LSExtendedSearchPersonCommand)
- (NSNumber *)fetchIds;
- (NSString *)operator;
@end

@implementation LSExtendedSearchPersonCommand

+ (int)version {
  return [super version] /* v2 */;
}
+ (void)initialize {
  NSAssert2([super version] == 2,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    self->withoutAccounts = NO;
  }
  return self;
}

- (void)dealloc {
  [self->searchAttributes  release];
  [self->attributes        release];
  [self->keyword           release];
  [self->keywordComparator release];
  [super dealloc];
}

/* generate searchRecords */

- (NSDictionary *)_typesInContext:(id)_context {
  NSEnumerator        *nameEnum;
  NSString            *name;
  NSMutableDictionary *result;
  NSUserDefaults      *ud;

  // TODO: can't we replace the macro with a proper method?
#define AssignType(_type_, _array_)                                       \
                            nameEnum = [_array_ objectEnumerator];        \
                            while ((name = [nameEnum nextObject])) {      \
                              [result setObject:_type_ forKey:name];      \
                            }
  
  ud     = [_context valueForKey:LSUserDefaultsKey];
  result = [NSMutableDictionary dictionaryWithCapacity:8];

  AssignType(@"Telephone",
             [[ud dictionaryForKey:@"LSTeleType"] objectForKey:@"Person"]);

  AssignType(@"Address",
             [[ud dictionaryForKey:@"LSAddressType"] objectForKey:@"Person"]);       
  AssignType(@"CompanyValue",
             [[ud dictionaryForKey:@"SkyPublicExtendedPersonAttributes"]
                  objectForKey:@"key"]);
  AssignType(@"CompanyValue",
             [[ud dictionaryForKey:@"SkyPrivateExtendedPersonAttributes"]
                  objectForKey:@"key"]);

#undef AssignType

  return result;
}

- (NSArray *)_searchRecordsInContext:(id)_context {
  NSDictionary          *types;
  NSArray               *allKeys;
  NSEnumerator          *keyEnum;
  NSMutableArray        *result;
  NSString              *key;
  NSString              *oldEntity = nil;
  LSGenericSearchRecord *record    = nil;

  result  = [NSMutableArray arrayWithCapacity:8];
  types   = [self _typesInContext:_context];
  allKeys = [self->searchAttributes allKeys];
  allKeys = [allKeys sortedArrayUsingSelector:@selector(isEqualToString:)];
  keyEnum = [allKeys objectEnumerator];

  while ((key = [keyEnum nextObject]) != nil) {
    NSArray  *keyComponents; // i.e. "01_tel.info" -> ("01_tel", "info")
    NSString *entity;

    keyComponents = [key componentsSeparatedByString:@"."];
    entity        = [types objectForKey:[keyComponents objectAtIndex:0]];
    entity        = (entity) ? entity : @"Person";
    
    if ((![oldEntity isEqualToString:entity]) ||
        [entity isEqualToString:@"CompanyValue"]) {
      if (record)
        [result addObject:record];
      
      record = LSRunCommandV(_context, @"search", @"newrecord",
                             @"entity", entity,
                             nil);
      ASSIGN(oldEntity, entity);
    }
    if ([entity isEqualToString:@"CompanyValue"]) {
      [record takeValue:key forKey:@"attribute"];
      [record takeValue:[self->searchAttributes objectForKey:key]
                 forKey:@"value"];
    }
    else {
      [record takeValue:[self->searchAttributes objectForKey:key]
                 forKey:[keyComponents lastObject]];
    }
  }
  [result addObject:record];
  [oldEntity release];
  return result;
}

/* search attributes */

- (void)setSearchAttributes:(NSDictionary *)_searchAttributes {
  // TODO: array of XXX, what is XXX?
  ASSIGN(self->searchAttributes, _searchAttributes);
}
- (NSDictionary *)searchAttributes {
  return self->searchAttributes;
}

- (void)setAttributes:(NSArray *)_attributes {
  // TODO: array of XXX, what is XXX?
  ASSIGN(self->attributes, _attributes);
}
- (NSArray *)attributes {
  return self->attributes;
}

/* qualifier construction */

- (EOSQLQualifier *)extendedSearchQualifier:(void *)_context {
  EOSQLQualifier *qualifier, *isArchivedQualifier, *isTemplateQualifier;
  
  qualifier           = [super extendedSearchQualifier:_context];
  isArchivedQualifier = 
    [[EOSQLQualifier alloc] initWithEntity:[self entity]
                            qualifierFormat:@"dbStatus <> 'archived'"];
  isTemplateQualifier =  
    [[EOSQLQualifier alloc] initWithEntity:[self entity]
                            qualifierFormat:
                              @"(isTemplateUser IS NULL) OR "
                              @"(isTemplateUser = 0)"]; 
 
  if ([self->keyword isNotNull]) {
    EOSQLQualifier  *q;
    NSMutableString *format;
    NSString        *comp;
    NSString        *keyw;
    
    comp = [self->keywordComparator isEqualToString:@"EQUAL"]
      ? (id)@"="
      : ([self->keywordComparator length] > 0
         ? self->keywordComparator 
         : (id)@"LIKE" );
    keyw = [self->keyword lowercaseString];
    
    format = [[NSMutableString alloc] initWithCapacity:256];
    [format appendString:@"("];
    /* exact */
    [format appendString:@"(LOWER(%A) "];
    [format appendString:comp];
    [format appendString:@" '%@') OR "];
    
    /* suffix */
    [format appendString:@"(LOWER(%A) "];
    [format appendString:comp];
    [format appendString:@" '%%, %@') OR "];

    /* middle */
    [format appendString:@"(LOWER(%A) "];
    [format appendString:comp];
    [format appendString:@" '%%, %@, %%') OR "];
    
    /* prefix */
    [format appendString:@"(LOWER(%A) "];
    [format appendString:comp];
    [format appendString:@" '%@, %%')"];
    [format appendString:@")"];
    
    q = [[EOSQLQualifier alloc] initWithEntity:[qualifier entity]
                                qualifierFormat:format,
                                @"keywords", keyw,
                                @"keywords", keyw,
                                @"keywords", keyw,
                                @"keywords", keyw];
    [format release]; format = nil;
    
    if ([[self operator] isEqualToString:@"OR"])
      [qualifier disjoinWithQualifier:q];
    else
      [qualifier conjoinWithQualifier:q];
    [q release]; q = nil;
  }
  
  if (self->withoutAccounts == YES) {
    EOSQLQualifier *q;

    q = [[EOSQLQualifier alloc] initWithEntity:[qualifier entity]
                                qualifierFormat:@"(%A = 0) OR (%A IS NULL)",
                                @"isAccount", @"isAccount"];
    [qualifier conjoinWithQualifier:q];
    [q release];
  }

  [qualifier conjoinWithQualifier:isArchivedQualifier];
  [qualifier conjoinWithQualifier:isTemplateQualifier];
  [isArchivedQualifier release];
  [isTemplateQualifier release];
  return qualifier;
}

/* command methods */

- (void)setKeyword:(NSString *)_keyword {
  ASSIGN(self->keyword,_keyword);
}
- (void)setKeywordComparator:(NSString *)_cmp {
  ASSIGN(self->keywordComparator,_cmp);
}

- (void)_checkRecordsForKeywords {
  NSArray               *records;
  LSGenericSearchRecord *record;
  unsigned max, i;

  records = [self searchRecordList];
  [self->keyword release]; self->keyword = nil;
  max = [records count];
  for (i = 0; i < max; i++) {
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
#  warning FIXME: incorrect implementation with this Foundation library
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
  if (self->searchAttributes) {
    [self takeValue:[self _searchRecordsInContext:_context]
             forKey:@"searchRecords"];
  }
  [super _prepareForExecutionInContext:_context];
  [self _checkRecordsForKeywords];
}


- (void)_executeInContext:(id)_context {
  [super _executeInContext:_context];

  if ([self fetchGlobalIDs]) return;
  
  if ([[self fetchIds] boolValue])
    return;
  
  /* get extended attributes */
  if (self->attributes == nil ||
      [self->attributes containsObject:@"extendedAttributes"]) {
    LSRunCommandV(_context, @"person", @"get-extattrs",
                  @"objects", [self object],
                  @"relationKey", @"companyValue", nil);
  }
  
  /* get telephones */
  if (self->attributes == nil ||
        [self->attributes containsObject:@"telephones"]) {
    LSRunCommandV(_context, @"person", @"get-telephones",
                  @"objects", [self object],
                  @"relationKey", @"telephones", nil);
  }
}

- (NSString *)entityName {
  return @"Person";
}

- (void)setWithoutAccounts:(BOOL)_b {
  self->withoutAccounts = _b;
}
- (BOOL)withoutAccounts {
  return self->withoutAccounts;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"withoutAccounts"])
    [self setWithoutAccounts:[_value boolValue]];
  else if ([_key isEqualToString:@"searchAttributes"])
    [self setSearchAttributes:_value ];
  else if ([_key isEqualToString:@"attributes"])
    [self setAttributes:_value ];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"withoutAccounts"])
    return [NSNumber numberWithBool:[self withoutAccounts]];

  if ([_key isEqualToString:@"searchAttributes"])
    return [self searchAttributes];

  if ([_key isEqualToString:@"attributes"])
    return [self attributes];
  
  return [super valueForKey:_key];
}

@end /* LSExtendedSearchPersonCommand */
