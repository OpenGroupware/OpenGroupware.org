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

#include "LSFullSearch.h"
#include "common.h"
#include <GDLAccess/EOSQLQualifier.h>

@implementation LSFullSearch

+ (int)version {
  return [super version] + 0 /* v1 */;
}
+ (void)initialize {
  NSAssert2([super version] == 1,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (id)initWithEntity:(EOEntity *)_entity
  andEntities:(NSArray *)_relatedEntities
{
  if ((self = [super init])) {
    NSAssert(self->entity == nil, @"object already initialized");

    self->includesOwnAttributes = YES;
    self->entity          = [_entity          retain];
    self->relatedEntities = [_relatedEntities retain];
#if 0
    [self _computeSearchAttributes];
#endif
  }
  return self;
}
- (id)init {
  return [self initWithEntity:nil andEntities:nil];
}

- (void)dealloc {
  RELEASE(self->entity);            
  RELEASE(self->searchString);      
  RELEASE(self->relatedEntities);   
  RELEASE(self->furtherSearches);   
  RELEASE(self->searchAttributes);  
  RELEASE(self->foreignAttributes); 
  [super dealloc];
}

/* processing */

- (NSArray *)_nonKeyAttributesForEntity:(EOEntity *)_entity {
  NSMutableArray *nonKeyAttrs = nil;
  NSEnumerator   *listEnum    = nil;
  id             attr         = nil;

  listEnum    = [[_entity attributes] objectEnumerator];
  nonKeyAttrs = [NSMutableArray arrayWithCapacity:32];
  
  while ((attr = [listEnum nextObject])) {
    NSString *column;
    
    column = [attr columnName];
    if ([column hasSuffix:@"_id"])
      continue;
    if ([column hasPrefix:@"is_"])
      continue;

    if ([column isEqualToString:@"db_status"])
      continue;
    
    if ([column isEqualToString:@"password"])
      continue;
    
    if ([[attr valueClassName] isEqualToString:@"NSCalendarDate"])
      continue;
    
    [nonKeyAttrs addObject:attr];
  }
  return nonKeyAttrs;
}

- (void)_computeSearchAttributes {
  NSEnumerator *listEnum = nil;
  id           relEntity = nil;

  if (self->didCompute) return;

  [self->foreignAttributes release]; self->foreignAttributes = nil;
  [self->searchAttributes  release]; self->searchAttributes  = nil;
  
  self->foreignAttributes = [[NSMutableArray alloc] initWithCapacity:8];
  self->searchAttributes  = [[NSMutableArray alloc] initWithCapacity:8];
  
  if (self->includesOwnAttributes) {
    [self->searchAttributes addObjectsFromArray:
         [self _nonKeyAttributesForEntity:self->entity]];
  }
  
  listEnum = [self->relatedEntities objectEnumerator];
  while ((relEntity = [listEnum nextObject])) {
    NSArray *attrs;

    attrs = [self _nonKeyAttributesForEntity:relEntity];
    [self->searchAttributes  addObjectsFromArray:attrs];
    [self->foreignAttributes addObjectsFromArray:attrs];
  }

  self->didCompute = YES;
}

/* accessors */

- (void)setGoodSearchString:(NSString *)_searchString {
  // TODO: explain! improve assert
  NSAssert(self->furtherSearches == nil,
           @"No FurtherSearches in a furtherSearch");
  ASSIGN(self->searchString, _searchString);
}

- (void)setSearchString:(NSString *)_searchString {
  /* TODO: clean up this mess! */
  NSEnumerator  *listEnum = nil;
  id            search    = nil;
  const char    *cString  = NULL;
  int           i, mutableCPos;
  int           cLength = [_searchString cStringLength];  
  unsigned char mutableCString[cLength * 2 + 2];
  
  cString        = [_searchString cString];
  mutableCPos = 0;
  for (i = 0; i < cLength; i++) {
    if (cString[i] == '*') {
      mutableCString[mutableCPos] = '%'; mutableCPos++;
      mutableCString[mutableCPos] = '%'; mutableCPos++;
      continue;
    }
    
    mutableCString[mutableCPos] = cString[i];
    mutableCPos++;
  }
  [self->searchString release]; self->searchString = nil;
  
  self->searchString = [[NSString alloc] initWithCString:(char*)mutableCString
                                         length:mutableCPos];

  listEnum = [self->furtherSearches objectEnumerator];  
  while ((search = [listEnum nextObject]) != nil)
    [search setGoodSearchString:self->searchString];
}

- (NSString *)searchString {
  return self->searchString;
}

- (EOEntity *)entity {
  return self->entity;
}

- (void)setIncludesOwnAttributes:(BOOL)_flag {
  self->includesOwnAttributes = _flag;
}
- (BOOL)includesOwnAttributes {
  return self->includesOwnAttributes;
}

- (void)setFurtherSearches:(NSArray *)_furtherSearches {
  ASSIGN(self->furtherSearches, _furtherSearches);
}

/* calculating SQL qualifiers */

- (NSString *)_qualifierFormatForAttributes:(NSArray *)_attributes
  entity:(EOEntity *)_entity
{
  NSMutableString *format;
  NSEnumerator    *listEnum;
  id              attr;

  format   = [NSMutableString stringWithCapacity:256];

  listEnum = [_attributes objectEnumerator];
  while ((attr = [listEnum nextObject])) {
    NSString *valueClassName, *part, *extType;

    valueClassName = [attr valueClassName];
    part           = nil;
    extType        = [[attr externalType] lowercaseString];
    
    if ([format length] > 0)
      [format appendString:@" OR "];
    
    if ([valueClassName isEqualToString:@"NSNumber"] ||
        [valueClassName isEqualToString:@"NSCalendarDate"]) {
      part = [self _formatForNumberAttribute:attr
                   andValue:self->searchString
                   entity:_entity];
    }
    else if ([valueClassName isEqualToString:@"NSString"]) {
      if ([extType hasSuffix:@"text"]) {
        part = [self _formatForTextAttribute:attr
                     andValue:self->searchString
                     entity:_entity];
      }
      else {
        part = [self _formatForStringAttribute:attr
                     andValue:self->searchString
                     entity:_entity];
      }
    }
    
    if (part) [format appendString:part];
  }
  return format;
}

- (NSString *)_qualifierFormatForAttributes:(NSArray *)_attributes {
  return [self _qualifierFormatForAttributes:_attributes entity:nil];
}

- (NSString *)_qualifierFormat {
  NSMutableString *format;
  NSEnumerator    *listEnum;
  NSString        *s;
  id              search;
  
  [self _computeSearchAttributes];
  
  format = [NSMutableString stringWithCapacity:256];
  [format appendString:@"("];
  
  s = [self _qualifierFormatForAttributes:self->searchAttributes];
  [format appendString:s];
  
  listEnum = [self->furtherSearches objectEnumerator];
  while ((search = [listEnum nextObject])) {
    if ([format length] > 0) 
      [format appendString:@" OR "];
    
    s = [self _qualifierFormatForAttributes:[search foreignAttributes]
              entity:[search entity]];
    [format appendString:s];
  }
  [format appendString:@")"];
  return format;
}

- (NSArray *)foreignAttributes {
  return self->foreignAttributes;
}

- (EOSQLQualifier *)qualifier {
  EOSQLQualifier *qualifier = nil;

  qualifier = [[EOSQLQualifier alloc]
                               initWithEntity:[self entity]
                               qualifierFormat:[self _qualifierFormat]];
  [qualifier setUsesDistinct:YES];

  return [qualifier autorelease];
}

/* description */

- (NSString *)description {
  NSMutableString *ms;
  
  ms = [NSMutableString stringWithCapacity:128];
  [ms appendFormat:@"<0x%p[%@]:", self, NSStringFromClass([self class])];
  
  [ms appendFormat:@" text='%@'", self->searchString];
  
  if (self->entity)
    [ms appendFormat:@" entity=%@", [self->entity name]];
  if ([self->relatedEntities isNotEmpty]) {
    id tmp;
    
    tmp = [self->relatedEntities valueForKey:@"name"];
    tmp = [tmp componentsJoinedByString:@","];
    [ms appendFormat:@" related-entities=%@", tmp];
  }
  
  if ([self->furtherSearches isNotEmpty])
    [ms appendFormat:@" further-searches=%d", [self->furtherSearches count]];
  
  if (self->includesOwnAttributes) 
    [ms appendString:@" includes-own-attrs"];
  if (self->didCompute) [ms appendString:@" did-compute"];
  
  [ms appendString:@">"];
  return ms;
}

@end /* LSFullSearch */
