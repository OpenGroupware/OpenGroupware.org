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

#include "LSGetObjectForGlobalIDs.h"
#include "SkyAccessManager.h"
#include "LSCommandContext.h"
#include "common.h"
#include <LSFoundation/LSCommandKeys.h>
#include <GDLAccess/GDLAccess.h>
#include <NGExtensions/NSNull+misc.h>

#if NeXT_Foundation_LIBRARY || COCOA_Foundation_LIBRARY
#  include <NGExtensions/NGObjectMacros.h>
#  include <NGExtensions/NGExtensions.h>
#endif

#if !ENABLE_PROFILING
#define TIME_START(_timeDescription) ;
#define TIME_END() ;

#else
#define TIME_START(_timeDescription) { struct timeval tv; double ti; NSString *timeDescription = nil; *(&ti) = 0; *(&timeDescription) = nil;timeDescription = [_timeDescription copy]; gettimeofday(&tv, NULL); ti =  (double)tv.tv_sec + ((double)tv.tv_usec / 1000000.0);

#define TIME_END() gettimeofday(&tv, NULL); ti = (double)tv.tv_sec + ((double)tv.tv_usec / 1000000.0) - ti; printf("[%s] <%s> : time needed: %4.4fs\n", __PRETTY_FUNCTION__, [timeDescription cString], ti < 0.0 ? -1.0 : ti); [timeDescription release]; timeDescription = nil;  } 

#endif

@implementation LSGetObjectForGlobalIDs

static BOOL doCacheGIDs = YES;

+ (int)version {
  return [super version] + 0; /* version 1 */
}

- (void)dealloc {
  [self->groupBy       release];
  [self->sortOrderings release];
  [self->attributes    release];
  [self->gids          release];
  [self->noAccessCheck release];
  [super dealloc];
}

/* execution */

- (EOSQLQualifier *)validateQualifier:(EOSQLQualifier *)_qual {
  return _qual;
}

- (BOOL)_containsInvalidGIDs {
  NSEnumerator  *e;
  EOKeyGlobalID *gid;
  BOOL          modifyArray;
  NSString      *validEntityName;

  validEntityName = [self entityName];
  modifyArray     = NO;
  
  e = [self->gids objectEnumerator];
  while (!modifyArray && (gid = [e nextObject])) {
    NSString *eName;
    
    if (![gid isNotNull]) {
      modifyArray = YES;
      break;
    }
    
    eName = [(EOKeyGlobalID *)gid entityName];
    if (eName != nil && ![eName isEqualToString:validEntityName]) {
      [self warnWithFormat:
              @"called command with invalid global-id, "
              @"entity '%@' expected, got '%@': %@",
              validEntityName, eName, gid];
      modifyArray = YES;
      break;
    }
  }
  return modifyArray;
}

- (void)_removeGIDsFromDifferentEntity {
  NSMutableArray *array;
  NSEnumerator   *e;
  EOKeyGlobalID  *gid;
  NSString *validEntityName;
  
  e     = [self->gids objectEnumerator];
  array = [[NSMutableArray alloc] initWithCapacity:[self->gids count]];
  validEntityName = [self entityName];
  
  while ((gid = [e nextObject])) {
    NSString *eName;
    
    if (![gid isNotNull])
      continue;
    
    eName = [gid entityName];
    if (validEntityName != nil && ![eName isEqualToString:validEntityName])
      // Note: might be problematic if caller relies on ordering (it should 
      //       not)
      continue;
    
    [array addObject:gid];
  }
  
  [self->gids release]; self->gids = nil;
  self->gids = [array shallowCopy];
  [array release]; array = nil;
}

- (void)_prepareForExecutionInContext:(id)_context {
  if ([self _containsInvalidGIDs])
    [self _removeGIDsFromDifferentEntity];
  
  [super _prepareForExecutionInContext:_context];
}

- (NSException *)handleEOSortException:(NSException *)_ex {
  [self errorWithFormat:@"catched exception during sort: %@", _ex];
  return nil;
}
- (id)_fetchEOsInContext:(id)_context gids:(NSArray *)_gids {
  id                results;
  EODatabaseChannel *dbCh;
  unsigned gidCount, batchSize;
  unsigned i;
  
  if ((gidCount = [_gids count]) == 0) {
    return self->groupBy
      ? [NSDictionary dictionary]
      : [NSArray array];
  }
  
  dbCh = [_context valueForKey:LSDatabaseChannelKey];
  [self assert:(dbCh != nil) reason:@"missing database channel"];
  
  batchSize = gidCount > 200 ? 200 : gidCount;
  
  results = nil;
  for (i = 0; i < gidCount; i += batchSize) {
    /* fetch in IN batches */
    EOSQLQualifier  *q;
    NSMutableString *in;
    NSString *pkeyName;
    unsigned j;
    BOOL     ok;
    id       eo;
    
    /* build qualifier */

    /* build batch */
    
    in = [[NSMutableString alloc] initWithCapacity:batchSize * 4];
    [in appendString:@"%@ IN ("];
    
    for (j = i; (j < (i + batchSize)) && (j < gidCount); j++) {
      EOKeyGlobalID *gid;
      
      gid = [_gids objectAtIndex:j];

#if DEBUG
      if (![gid isNotNull]) {
        [self errorWithFormat:
                @"missing gid at index %d in gid-array: %@", 
                j, _gids];
        continue;
      }
#endif
      
      if (i != j)
        [in appendString:@","];
      
      [in appendString:[[gid keyValues][0] stringValue]];
    }
    [in appendString:@")"];

    /* check for single key fetch */
    
    if ([in rangeOfString:@","].length == 0) {
      /* optimize to use "=" if there is only one pkey */
      EOKeyGlobalID *gid;
      
      gid = [_gids objectAtIndex:i];
      [in setString:@"%@ = "];
      [in appendString:[[gid keyValues][0] stringValue]];
    }
    
    /* build qualifier */
    
    pkeyName = [[[self entity] primaryKeyAttributeNames] objectAtIndex:0];
    q = [[EOSQLQualifier alloc] initWithEntity:[self entity]
                                qualifierFormat:in, pkeyName];
    [in release]; in = nil;

    /* select objects */
    
    ok = [dbCh selectObjectsDescribedByQualifier:[self validateQualifier:q]
               fetchOrder:nil];
    [q release]; q = nil;
    
    [self assert:ok format:@"couldn't select objects by gid"];

    if (results == nil) {
      results = self->groupBy
        ? [NSMutableDictionary dictionaryWithCapacity:gidCount]
        : [NSMutableArray arrayWithCapacity:gidCount];
    }
    
    /* fetch objects */
    
    while ((eo = [dbCh fetchWithZone:NULL])) {
      if (self->groupBy) {
        [(NSMutableDictionary *)results
                                setObject:eo 
                                forKey:[eo valueForKey:self->groupBy]];
      }
      else
        [results addObject:eo];
    }
  }
  
  /* sort result */
  
  if (([self->sortOrderings count] > 0) && (self->groupBy == nil)) {
    NS_DURING {
      results = (id)
        [results sortedArrayUsingKeyOrderArray:self->sortOrderings];
    }
    NS_HANDLER
      [[self handleEOSortException:localException] raise];
    NS_ENDHANDLER;
  }
  else {
    results = [[results copy] autorelease];
  }
  
  /* fetch additional info */
  
  [self fetchAdditionalInfosForObjects:
	  (self->groupBy != nil) ? [results allValues] : results
        context:_context];
  
  return results;
}

- (void)fetchAdditionalInfosForObjects:(NSArray *)_obj context:(id)_context {
  /* TODO: document! is this for subclasses to override? */
}

- (id)_fetchAttributesInContext:(id)_context gids:(NSArray *)_gids {
  /* TODO: split up in smaller methods */
  id               results;
  EOAdaptorChannel *adCh;
  NSString         *pkeyAttrName;
  NSMutableArray   *attrs, *additionalKeys;
  EOEntity         *entity;
  unsigned gidCount, batchSize;
  unsigned i;
  BOOL     addGids;

  if ((gidCount = [_gids count]) == 0) {
    return self->groupBy
      ? [NSDictionary dictionary]
      : [NSArray array];
  }
  
#if DEBUG
  NSAssert(_gids, @"missing gids array ..");
  NSAssert([_gids count] > 0, @"gids array is empty ..");
#endif
  
  entity       = [self entity];
  pkeyAttrName = [[entity primaryKeyAttributeNames] objectAtIndex:0];
  
  adCh = [[_context valueForKey:LSDatabaseChannelKey] adaptorChannel];
  [self assert:(adCh != nil) reason:@"missing adaptor channel"];
  
  /* setup attributes array */
  {
    unsigned i, count;
    BOOL foundGroupBy;

    addGids        = NO;
    additionalKeys = nil;
    foundGroupBy   = NO;
    
    attrs = [NSMutableArray array];
    for (i = 0, count = [self->attributes count]; i < count; i++) {
      NSString    *attrName;
      EOAttribute *attr;
      
      attrName = [self->attributes objectAtIndex:i];
      attr     = [entity attributeNamed:attrName];
      
      if (attr) {
        if ((self->groupBy != nil) && !foundGroupBy) {
          foundGroupBy = [self->groupBy isEqualToString:attrName];
        }
        [attrs addObject:attr];
      }
      else if ([attrName isEqualToString:@"globalID"]) {
        if (!foundGroupBy) {
          if ([self->groupBy isEqualToString:@"globalID"])
            foundGroupBy = YES;
        }
        addGids = YES;
      }
      else {
        if (additionalKeys == nil)
          additionalKeys = [NSMutableArray arrayWithCapacity:16];
        [additionalKeys addObject:attrName];
      }
    }

    if (!foundGroupBy && (self->groupBy != nil)) {
      if (![self->groupBy isEqualToString:@"globalID"]) {
        EOAttribute *attr;
        
        attr = [entity attributeNamed:self->groupBy];
        [self assert:(attr != nil)
              format:@"did not find group attribute: %@", self->groupBy];
        [attrs addObject:attr];
      }
      else
        /* globalID is group-by attribute */
        addGids = YES;
    }
  }
  
  /* if (addGids) */ {
    /* ensure that the pkey is fetched */
    EOAttribute *attr        = nil;

    attr = [[[self entity] primaryKeyAttributes] lastObject];

    if (![self->attributes containsObject:[attr name]])
      [attrs addObject:attr];
  }

#if 0
  [self assert:([additionalKeys count] == 0)
        format:@"cannot fetch keys %@", additionalKeys];
#endif
  
  batchSize = gidCount > 200 ? 200 : gidCount;
  
  results = nil;

  TIME_START(@"fetch zeugs");
  for (i = 0; i < gidCount; i += batchSize) {
    /* fetch in IN batches */
    NSException     *error;
    EOSQLQualifier  *q;
    NSMutableString *in;
    unsigned     j;
    BOOL         isFirst;
    NSDictionary *values;

    TIME_START(@"prepare fetch ");
#if DEBUG
    NSAssert(_gids, @"missing gids array ..");
#endif
    
    /* build qualifier */

    // TODO: optimize to use "=" if there is only one pkey!
    
    in = [[NSMutableString alloc] initWithCapacity:(batchSize * 4)];
    [in appendString:@"%@ IN ("];
    
    isFirst = YES;
    for (j = i; (j < (i + batchSize)) && (j < gidCount); j++) {
      EOKeyGlobalID *gid = nil;
      NSString      *s   = nil;
      
      gid = [_gids objectAtIndex:j];
      
      if ([gid isNotNull]) {
#if DEBUG
        NSAssert(_gids, @"missing gids array ..");
        NSAssert5(gid,
                  @"missing gid at index %d(i=%d) in gid-array %@ of class %@"
                  @", count %d", j, i, _gids, NSStringFromClass([_gids class]),
                  [_gids count]);
#endif
      
        if ([(s = [[gid keyValues][0] stringValue]) length] == 0)
	  continue;
	
	if (isFirst) isFirst = NO;
	else [in appendString:@","];          
	[in appendString:s];
      }
    }
    
    [in appendString:@")"];

    /* check for single key fetch */
    
    if ([in rangeOfString:@","].length == 0) {
      // TODO: this is DUP code
      /* optimize to use "=" if there is only one pkey */
      EOKeyGlobalID *gid;
      
      gid = [_gids objectAtIndex:i];
      [in setString:@"%@ = "];
      [in appendString:[[gid keyValues][0] stringValue]];
    }
    
    /* build qualifier */
    
    q = [[EOSQLQualifier alloc] initWithEntity:[self entity]
                                qualifierFormat:in, pkeyAttrName];
    [in release]; in = nil;
    
    /* select objects */
    
    error = [adCh selectAttributesX:attrs
		  describedByQualifier:[self validateQualifier:q]
		  fetchOrder:nil
		  lock:NO];
    [q release]; q = nil;
    
    if (error != nil) {
      [self logWithFormat:@"could not select objects by gid: %@", error];
      [error raise];
    }
    
    if (results == nil) {
      results = self->groupBy
        ? [NSMutableDictionary dictionaryWithCapacity:gidCount]
        : [NSMutableArray      arrayWithCapacity:gidCount];
    }
    
    /* fetch ??? rows */

    TIME_END();
    {
      NSString *attrName, *eName;
      NSZone   *zone;
      id       key;
      BOOL     groupByGid = NO;
      
      static Class EOKeyGlobalIDClass = Nil;

      if (EOKeyGlobalIDClass == Nil)
        EOKeyGlobalIDClass = [EOKeyGlobalID class];

      key = nil;
#if DEBUG & 0
      NSAssert([[entity primaryKeyAttributes] count] == 1);
#endif
      attrName = [(EOAttribute *)[[entity primaryKeyAttributes] 
				          lastObject] name];
      eName    = [entity name];
      zone     = [self zone];

      if (doCacheGIDs)
        groupByGid = [self->groupBy isEqualToString:@"globalID"] && addGids;
      
      values = [adCh fetchAttributes:attrs withZone:NULL];

      while ((values)) {

        key = nil;
        
        //        TIME_START(@"fetch overhead add addGids");
        if (addGids) {
          EOKeyGlobalID       *gid;
          NSMutableDictionary *tmp;

          key = [values objectForKey:attrName];

#if DEBUG & 1
          NSAssert(key, @"misssing key");
#endif
          tmp = [values mutableCopy];

          gid = [EOKeyGlobalID globalIDWithEntityName:eName
                               keys:&key  keyCount:1 zone:zone];
          [tmp setObject:gid forKey:@"globalID"];
          values = [tmp autorelease];
          
          if (doCacheGIDs) {
            if (groupByGid)
              key = gid;
          }
        }
#if 0
        TIME_END();

        TIME_START(@"fetch overhead setObject");
#endif
        if (self->groupBy) {
          if (doCacheGIDs && groupByGid && key != nil) {
            [(NSMutableDictionary *)results setObject:values forKey:key];
          }
          else {
            [(NSMutableDictionary *)results 
                     setObject:values
                     forKey:[values objectForKey:self->groupBy]];
          }
        }
        else
          [results addObject:values];

#if 0
        TIME_END();
#endif
        
        values = [adCh fetchAttributes:attrs withZone:NULL];
      }
    }
  }
  TIME_END();

  TIME_START(@"fetchAdditionalInfosForObjects ");
  [self fetchAdditionalInfosForObjects:(self->groupBy != nil)
                                       ? [results allValues]
                                       : results
        context:_context];

  TIME_END();
  return results;
}

- (void)_executeInContext:(id)_context {
  NSAutoreleasePool *pool;
  id results;

  if (![self->noAccessCheck boolValue]) {
    /* check read access */
    NSArray *tmp;
    
    TIME_START(@"access check");
    tmp = [[_context accessManager] objects:self->gids forOperation:@"r"];
    TIME_END();
    ASSIGN(self->gids, tmp);
  }

  if (self->gids == nil || [self->gids count] == 0) {
    [self setReturnValue:nil];
    return;
  }

  
  pool = [[NSAutoreleasePool alloc] init];

  TIME_START(@"fetch");
  results = (self->attributes == nil)
    ? [self _fetchEOsInContext:_context        gids:self->gids]
    : [self _fetchAttributesInContext:_context gids:self->gids];
  TIME_END();
  
  [self setReturnValue:results];

  [pool release];
}

/* accessors */

- (void)setGlobalIDs:(NSArray *)_gids {
  id tmp;
  
  if (self->gids == _gids)
    return;
  
  tmp = self->gids;
  self->gids = [_gids isKindOfClass:[NSSet class]]
    ? [[(NSSet *)_gids allObjects] copy]
    : [_gids copy];
    
  [tmp release];
}
- (NSArray *)globalIDs {
  return self->gids;
}

- (void)setGlobalID:(EOGlobalID *)_gid {
  [self setGlobalIDs:([_gid isNotNull]?[NSArray arrayWithObject:_gid] : nil)];
}
- (EOGlobalID *)globalID {
  return [self->gids lastObject];
}

- (void)setAttributes:(NSArray *)_attributes {
  ASSIGN(self->attributes, _attributes);
}
- (NSArray *)attributes {
  return self->attributes;
}

- (void)setSortOrderings:(NSArray *)_orderings {
  ASSIGN(self->sortOrderings, _orderings);
}
- (NSArray *)sortOrderings {
  return self->sortOrderings;
}

- (void)setNoAccessCheck:(NSNumber *)_access { // TODO: why an NSNumber?
  ASSIGN(self->noAccessCheck, _access);
}
- (NSNumber *)noAccessCheck {
  return self->noAccessCheck;
}

/* key-value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"gid"])
    [self setGlobalID:_value];
  else if ([_key isEqualToString:@"gids"])
    [self setGlobalIDs:_value];
  else if ([_key isEqualToString:@"groupBy"]) {
    ASSIGNCOPY(self->groupBy, _value);
  }
  else if ([_key isEqualToString:@"attributes"])
    [self setAttributes:_value];
  else if ([_key isEqualToString:@"sortOrderings"])
    [self setSortOrderings:_value];
  else if ([_key isEqualToString:@"sortOrdering"])
    [self setSortOrderings:[NSArray arrayWithObject:_value]];
  else if ([_key isEqualToString:@"noAccessCheck"])
    [self setNoAccessCheck:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  id v;
  
  if ([_key isEqualToString:@"gid"])
    v = [self globalID];
  else if ([_key isEqualToString:@"gids"])
    v = [self globalIDs];
  else if ([_key isEqualToString:@"groupBy"])
    v = self->groupBy;
  else if ([_key isEqualToString:@"attributes"])
    v = [self attributes];
  else if ([_key isEqualToString:@"sortOrderings"])
    v = [self sortOrderings];
  else if ([_key isEqualToString:@"noAccessCheck"])
    v = [self noAccessCheck];
  else if ([_key isEqualToString:@"sortOrdering"]) {
    v = [self sortOrderings];
    v = [v objectAtIndex:0];
  }
  else
    v = [super valueForKey:_key];
  
  return v;
}

@end /* LSGetObjectForGlobalIDs */
