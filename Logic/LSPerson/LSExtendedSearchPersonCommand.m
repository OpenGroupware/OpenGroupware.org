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

  Note: you may only subclass this command with commands using the same entity,
        otherwise qualifier caches might be broken.
  
  Eg called by SkyPersonDataSource.
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
  id keyword; // build special qualifiers for keywords
}
@end

#include "common.h"
#include <LSSearch/LSGenericSearchRecord.h>
#include <LSFoundation/EOSQLQualifier+LS.h>
#include <NGExtensions/NSString+Ext.h>

@interface NSObject(LSExtendedSearchPersonCommand)
- (NSNumber *)fetchIds;
- (NSString *)operator;
@end

@implementation LSExtendedSearchPersonCommand

static BOOL debugOn = NO;

+ (int)version {
  return [super version] /* v2 */;
}
+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSAssert2([super version] == 2,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
  
  if ((debugOn = [ud boolForKey:@"LSDebugExtSearch"]))
    NSLog(@"Note: LSDebugExtSearch is enabled for %@",NSStringFromClass(self));
}

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    self->withoutAccounts = NO;
  }
  return self;
}

- (void)dealloc {
  [self->searchAttributes release];
  [self->attributes       release];
  [self->keyword          release];
  [super dealloc];
}

/* generate searchRecords */

/**
 * Returns a map from some extended key to the entity name storing such a key.
 * 
 * E.g.:
 *   { "01_tel": "Telephone", "02_tel": "Telephone",
 *     "private": "Address", "mailing": "Address", "location": "Address",
 *     "email1": "CompanyValue", ...
 *   }
 */
- (NSDictionary *)_typesInContext:(id)_context {
  // hh(2024-11-20): This is a little ambiguous and requires that there is
  //                 no overlap between keys in phone, address and companyValue.
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
    entity        = (entity != nil) ? entity : (NSString *)@"Person";
    
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

- (EOSQLQualifier *)isNotTemplateUserQualifier {
  static EOSQLQualifier *q = nil;
  
  if (q != nil) return q;
  q = [[EOSQLQualifier alloc] initWithEntity:[self entity]
			      qualifierFormat:
                              @"(isTemplateUser IS NULL) OR "
                              @"(isTemplateUser = 0)"];
  return q;
}
- (EOSQLQualifier *)notArchivedQualifier {
  static EOSQLQualifier *q = nil;
  
  if (q != nil) return q;
  q = [[EOSQLQualifier alloc] initWithEntity:[self entity]
			      qualifierFormat:@"dbStatus <> 'archived'"];
  return q;
}

- (EOSQLQualifier *)extendedSearchQualifier:(void *)_context {
  EOSQLQualifier *qualifier;
  
  qualifier = [super extendedSearchQualifier:_context];
  if (debugOn) {
    [self logWithFormat:@"super qualifier: %@",
	  [qualifier expressionValueForContext:nil]];
  }
  
  if ([self->keyword isNotNull]) {
    EOSQLQualifier *q;
    
    if (debugOn) {
      [self logWithFormat:@"  keyword: '%@'(%@)", 
	      self->keyword, NSStringFromClass([self->keyword class])];
    }
    if ([self->keyword rangeOfString:@", "].length > 0) {
      q = [[[EOSQLQualifier alloc] 
             initWithEntity:[qualifier entity]
             csvAttribute:@"keywords"
             containingValues:
               [self->keyword componentsSeparatedByString:@", "]
             conjoin:![[self operator] isEqualToString:@"OR"]] autorelease];
    }
    else {
      q = [[[EOSQLQualifier alloc] initWithEntity:[qualifier entity]
                                   csvAttribute:@"keywords"
                                   containingValue:self->keyword] autorelease];
    }
    
    if (q != nil && ([self isNoMatchSQLQualifier:qualifier] || qualifier==nil))
      qualifier = q;
    else {
      if ([[self operator] isEqualToString:@"OR"])
	[qualifier disjoinWithQualifier:q];
      else
	[qualifier conjoinWithQualifier:q];
    }
  }
  else if ([self isNoMatchSQLQualifier:qualifier]) {
    /* Note: all Qs below are conjoins */
    if (debugOn) [self logWithFormat:@"  no match qualifier ..."];
    return qualifier;
  }
  
  /* Note: do not use disjoins below! */
  
  if (self->withoutAccounts) {
    EOSQLQualifier *q;

    if (debugOn) [self logWithFormat:@"  withoutAccounts turned on."];

    q = [[EOSQLQualifier alloc] initWithEntity:[qualifier entity]
                                qualifierFormat:@"(%A = 0) OR (%A IS NULL)",
                                @"isAccount", @"isAccount"];
    [qualifier conjoinWithQualifier:q];
    [q release];
  }
  
  [qualifier conjoinWithQualifier:[self notArchivedQualifier]];
  [qualifier conjoinWithQualifier:[self isNotTemplateUserQualifier]];
  
  if (debugOn) {
    [self logWithFormat:@"  FINAL: %@", 
	  [qualifier expressionValueForContext:nil]];
  }
  return qualifier;
}

/* accessors */

- (void)setKeyword:(id)_keyword {
  ASSIGNCOPY(self->keyword, _keyword);
}

/* command methods */

- (void)_prepareForExecutionInContext:(id)_context {
  if (self->searchAttributes != nil) {
    [self takeValue:[self _searchRecordsInContext:_context]
	  forKey:@"searchRecords"];
  }
  [super _prepareForExecutionInContext:_context];
  
  // TODO: what does this do?
  [self setKeyword:[self _checkRecordsForCSVAttribute:@"keywords"]];
}


- (void)_executeInContext:(id)_context {
  [super _executeInContext:_context];

  if ([self fetchGlobalIDs] || [[self fetchIds] boolValue]) {
    if (debugOn) 
      [self logWithFormat:@"  fetching gids/ids, no post-processing .."];
    return;
  }
  
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

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"withoutAccounts"])
    [self setWithoutAccounts:[_value boolValue]];
  else if ([_key isEqualToString:@"searchAttributes"])
    [self setSearchAttributes:_value ];
  else if ([_key isEqualToString:@"attributes"])
    [self setAttributes:_value ];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"withoutAccounts"])
    return [NSNumber numberWithBool:[self withoutAccounts]];

  if ([_key isEqualToString:@"searchAttributes"])
    return [self searchAttributes];

  if ([_key isEqualToString:@"attributes"])
    return [self attributes];
  
  return [super valueForKey:_key];
}

@end /* LSExtendedSearchPersonCommand */
