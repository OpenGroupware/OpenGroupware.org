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

#if 1 // TODO: hh asks: whats that?

// TODO: is this actually used somewhere - looks broken!

#include <LSFoundation/LSGetObjectForGlobalIDs.h>

/*
  This command fetches account-objects based on a list of EOGlobalIDs.
*/

@interface LSGetAccountsForGlobalIDsCommand : LSGetObjectForGlobalIDs
{
@protected  
  BOOL     fetchArchivedAccounts;
}
@end

#include <LSFoundation/LSCommandKeys.h>
#import <EOControl/EOControl.h>
#import <GDLAccess/GDLAccess.h>
#include "common.h"

@implementation LSGetAccountsForGlobalIDsCommand

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    self->fetchArchivedAccounts = NO;
  }
  return self;
}

- (NSString *)entityName {
  // TODO: this looks weird? There is no entity "Account"?!
  return @"Account";
}

/* execution */

- (EOSQLQualifier *)validateQualifier:(EOSQLQualifier *)_qual {
  EOSQLQualifier *isArchivedQualifier;
  
  if (self->fetchArchivedAccounts) 
    return _qual;
  
  isArchivedQualifier = [[EOSQLQualifier alloc]
                                         initWithEntity:[self entity]
                                         qualifierFormat:
                                           @"dbStatus <> 'archived'"];

  [_qual conjoinWithQualifier:isArchivedQualifier];
  [isArchivedQualifier release]; isArchivedQualifier = nil;
  return _qual;
}

- (void)fetchAdditionalInfosForObjects:(NSArray *)_obj context:(id)_context {
}

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"fetchArchivedAccounts"])
    self->fetchArchivedAccounts = [_value boolValue];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"fetchArchivedAccounts"])
    return [NSNumber numberWithBool:self->fetchArchivedAccounts];

  return [super valueForKey:_key];
}

@end /* LSGetAccountsForGlobalIDsCommand */

#else

#include <LSFoundation/LSDBObjectBaseCommand.h>

/*
  This command fetches account-objects based on a list of EOGlobalIDs.
*/

@interface LSGetTeamsForGlobalIDsCommand : LSDBObjectBaseCommand
{
  NSArray  *gids;
  NSArray  *attributes;
  NSArray  *sortOrderings;
  NSString *groupBy;
  BOOL     singleFetch;
  BOOL     fetchArchivedAccounts;
}
@end

#include <LSFoundation/LSCommandKeys.h>
#import <Foundation/Foundation.h>
#import <EOControl/EOControl.h>
#import <GDLAccess/GDLAccess.h>

@implementation LSGetAccountsForGlobalIDsCommand

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    self->fetchArchivedAccounts = NO;
  }
  return self;
}

- (NSString *)entityName {
  return @"Account";
}

- (void)dealloc {
  RELEASE(self->groupBy);
  RELEASE(self->sortOrderings);
  RELEASE(self->attributes);
  RELEASE(self->gids);
  [super dealloc];
}

/* execution */

- (id)_fetchEOsInContext:(id)_context gids:(NSArray *)_gids {
  id                results;
  EODatabaseChannel *dbCh;
  unsigned gidCount, batchSize;
  unsigned i;
  
  if ((gidCount = [_gids count]) == 0)
    return [NSArray array];
  
  dbCh = [_context valueForKey:LSDatabaseChannelKey];
  [self assert:(dbCh != nil) reason:@"missing database channel"];
  
  batchSize = gidCount > 200 ? 200 : gidCount;
  
  *(&results) = [NSMutableArray arrayWithCapacity:gidCount];
  for (i = 0; i < gidCount; i += batchSize) {
    /* fetch in IN batches */
    EOSQLQualifier  *q                   = nil;
    EOSQLQualifier  *isArchivedQualifier = nil;
    NSMutableString *in                  = nil;
    unsigned        j                    = 0;
    BOOL            ok                   = NO;
    id              eo                   = nil;
    
    /* build qualifier */
    
    in = [[NSMutableString alloc] initWithCapacity:batchSize * 4];
    [in appendString:@"%@ IN ("];
    
    for (j = i; (j < (i+batchSize)) && (j < gidCount); j++) {
      EOKeyGlobalID *gid;
      
      gid = [_gids objectAtIndex:j];
      
      if (i != j)
        [in appendString:@","];
      
      [in appendString:[[gid keyValues][0] stringValue]];
    }

    [in appendString:@")"];
    isArchivedQualifier = [[EOSQLQualifier alloc]
                                           initWithEntity:[self entity]
                                           qualifierFormat:
                                           @"dbStatus <> 'archived'"];

    q = [[EOSQLQualifier alloc] initWithEntity:[self entity]
                                qualifierFormat:in,
                                  [[[self entity]
                                          primaryKeyAttributeNames]
                                          objectAtIndex:0]];
    if (self->fetchArchivedTeams == NO)
      [q conjoinWithQualifier:isArchivedQualifier];
    
    RELEASE(in); in = nil;

    /* select objects */
    
    ok = [dbCh selectObjectsDescribedByQualifier:q fetchOrder:nil];
    RELEASE(q);                   q                   = nil;
    RELEASE(isArchivedQualifier); isArchivedQualifier = nil;
    
    [self assert:ok format:@"couldn't select objects by gid"];
    
    /* fetch objects */
    
    while ((eo = [dbCh fetchWithZone:nil])) {
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
      printf("%s\n", [[localException description] cString]);
    NS_ENDHANDLER;
  }
  else {
    results = AUTORELEASE([results copy]);
  }
  
  return results;
}

- (id)_fetchAttributesInContext:(id)_context gids:(NSArray *)_gids {
  NSMutableArray   *results;
  EOAdaptorChannel *adCh;
  NSString         *pkeyAttrName;
  NSMutableArray   *attrs, *additionalKeys, *memberKeys;
  NSMutableArray   *resultGids;
  NSMutableDictionary *gidToTeam;
  EOEntity         *entity;
  unsigned gidCount, batchSize;
  unsigned i;
  BOOL     makeMutable;
  BOOL     addGids;
  
  if ((gidCount = [_gids count]) == 0)
    return [NSArray array];
  
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
    memberKeys     = nil;
    gidToTeam      = nil;
    foundGroupBy   = NO;
    makeMutable    = YES;
    
    attrs = [NSMutableArray array];
    for (i = 0, count = [self->attributes count]; i < count; i++) {
      NSString    *attrName;
      EOAttribute *attr;
      
      attrName = [self->attributes objectAtIndex:i];
      attr = [entity attributeNamed:attrName];
      
      if (attr) {
        if ((self->groupBy != nil) && !foundGroupBy)
          foundGroupBy = [self->groupBy isEqualToString:attrName];
        
        [attrs addObject:attr];
        continue;
      }
      
      if ([attrName isEqualToString:@"globalID"]) {
        if (!foundGroupBy) {
          if ([self->groupBy isEqualToString:@"globalID"])
            foundGroupBy = YES;
        }
        addGids = YES;
        makeMutable = YES;
        continue;
      }
      if ([attrName hasPrefix:@"members."]) {
        if (memberKeys == nil)
          memberKeys = [NSMutableArray arrayWithCapacity:8];
        makeMutable = YES;
        [memberKeys addObject:[attrName substringFromIndex:8]];
        gidToTeam = [NSMutableDictionary dictionaryWithCapacity:32];
        continue;
      }

      if (additionalKeys == nil)
        additionalKeys = [NSMutableArray array];
      [additionalKeys addObject:attrName];
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
  
  if (addGids) {
    /* ensure that the pkey is fetched */
    if (![self->attributes containsObject:@"companyId"])
      [attrs addObject:[entity attributeNamed:@"companyId"]];
  }

#if DEBUG
  if ([additionalKeys count] > 0)
    [self logWithFormat:@"unprocessed keys: %@", additionalKeys];
#endif
#if 0
  [self assert:([additionalKeys count] == 0)
        format:@"cannot fetch keys %@", additionalKeys];
#endif
  
  batchSize = gidCount > 200 ? 200 : gidCount;
  
  *(&results) = nil;
  resultGids  = [NSMutableArray arrayWithCapacity:gidCount];
  results     = [NSMutableArray arrayWithCapacity:gidCount];
  for (i = 0; i < gidCount; i += batchSize) {
    /* fetch in IN batches */
    EOSQLQualifier  *q                   = nil;
    EOSQLQualifier  *isArchivedQualifier = nil;    
    NSMutableString *in                  = nil;
    unsigned        j                    = 0;
    BOOL            ok                   = NO;
    NSDictionary    *row                 = nil;
    
    /* build qualifier */
    
    in = [[NSMutableString alloc] initWithCapacity:batchSize * 4];
    [in appendString:@"%@ IN ("];
    
    for (j = i; (j < (i+batchSize)) && (j < gidCount); j++) {
      EOKeyGlobalID *gid;
      
      gid = [_gids objectAtIndex:j];
      
      if (i != j)
        [in appendString:@","];
      
      [in appendString:[[gid keyValues][0] stringValue]];
    }
    
    [in appendString:@")"];

    isArchivedQualifier = [[EOSQLQualifier alloc] initWithEntity:[self entity]
                                  qualifierFormat:@"dbStatus <> 'archived'"];
    q = [[EOSQLQualifier alloc] initWithEntity:[self entity]
                                qualifierFormat:in, pkeyAttrName];
    if (self->fetchArchivedTeams == NO)
      [q conjoinWithQualifier:isArchivedQualifier];
    RELEASE(in); in = nil;
    
    /* select appointment objects */
    
    ok = [adCh selectAttributes:attrs
               describedByQualifier:q
               fetchOrder:nil
               lock:NO];
    RELEASE(q);                   q                   = nil;
    RELEASE(isArchivedQualifier); isArchivedQualifier = nil;
    
    [self assert:ok format:@"couldn't select objects by gid"];
    
    /* fetch appointment rows */
    
    while ((row = [adCh fetchAttributes:attrs withZone:nil])) {
      EOGlobalID *gid;

      gid = [entity globalIDForRow:row];
      
      if (makeMutable)
        row = [row mutableCopy];
      
      if (addGids)
        [(id)row setObject:gid forKey:@"globalID"];
      
      [resultGids addObject:gid];
      [results    addObject:row];
      
      [gidToTeam setObject:row forKey:gid];
      
      if (makeMutable)
        RELEASE(row);
    }
  }
  
  /* fetch members */
  
  if (([memberKeys count] > 0) && ([resultGids count] > 0)) {
    NSArray *memberGids;
    
    NSAssert(makeMutable, @"should be 'makeMutable' ..");
    
    memberGids = LSRunCommandV(_context, @"team", @"members",
                               @"groups", resultGids,
                               @"fetchGlobalIDs", [NSNumber numberWithBool:YES],
                               nil);
  }
  
  /* sort result */
  
  if (([self->sortOrderings count] > 0) && (self->groupBy == nil)) {
    NS_DURING {
      results = (id)
        [results sortedArrayUsingKeyOrderArray:self->sortOrderings];
    }
    NS_HANDLER
      printf("%s\n", [[localException description] cString]);
    NS_ENDHANDLER;
  }
  else {
    results = AUTORELEASE([results copy]);
  }
  
  return results;
}

- (void)_executeInContext:(id)_context {
  NSAutoreleasePool *pool;
  id results;
  
  pool = [[NSAutoreleasePool alloc] init];
  
  results = (self->attributes == nil)
    ? [self _fetchEOsInContext:_context gids:self->gids]
    : [self _fetchAttributesInContext:_context gids:self->gids];

  if (self->singleFetch)
    results = [results count] > 0 ? [results objectAtIndex:0] : nil;
  
  if (self->groupBy) {
    unsigned i, count;
    NSMutableDictionary *mapped;

    count = [results count];
    mapped = [[NSMutableDictionary alloc] initWithCapacity:count];
    for (i = 0; i < count; i++) {
      id obj;
      id key;

      obj = [results objectAtIndex:i];
      key = [obj valueForKey:self->groupBy];
      if (key == nil) key = [EONull null];
      
      [mapped setObject:obj forKey:key];
    }
    results = [mapped copy];
    RELEASE(mapped);
    AUTORELEASE(results);
  }
  
  [self setReturnValue:results];

  RELEASE(pool);
}

/* accessors */

- (void)setGlobalIDs:(NSArray *)_gids {
  if (self->gids != _gids) {
    id tmp;
    tmp = self->gids;
    if ([_gids isKindOfClass:[NSSet class]])
      self->gids = RETAIN([(NSSet *)_gids allObjects]);
    else
      self->gids = [_gids copy];
    RELEASE(tmp);
  }
}
- (NSArray *)globalIDs {
  return self->gids;
}

- (void)setGlobalID:(EOGlobalID *)_gid {
  [self setGlobalIDs:[NSArray arrayWithObject:_gid]];
  self->singleFetch = YES;
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

/* key-value coding */

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"gid"])
    [self setGlobalID:_value];
  else if ([_key isEqualToString:@"gids"])
    [self setGlobalIDs:_value];
  else if ([_key isEqualToString:@"fetchArchivedTeams"])
    self->fetchArchivedTeams = [_value boolValue];
  else if ([_key isEqualToString:@"attributes"])
    [self setAttributes:_value];
  else if ([_key isEqualToString:@"groupBy"]) {
    id tmp = self->groupBy;
    self->groupBy = [_value copy];
    RELEASE(tmp);
  }
  else if ([_key isEqualToString:@"sortOrderings"])
    [self setSortOrderings:_value];
  else if ([_key isEqualToString:@"sortOrdering"])
    [self setSortOrderings:[NSArray arrayWithObject:_value]];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  id v;
  
  if ([_key isEqualToString:@"gid"])
    v = [self globalID];
  else if ([_key isEqualToString:@"groupBy"])
    v = self->groupBy;
  else if ([_key isEqualToString:@"fetchArchivedAccounts"])
    v = [NSNumber numberWithBool:self->fetchArchivedTeams];
  else if ([_key isEqualToString:@"gids"])
    v = [self globalIDs];
  else if ([_key isEqualToString:@"attributes"])
    v = [self attributes];
  else if ([_key isEqualToString:@"sortOrderings"])
    v = [self sortOrderings];
  else if ([_key isEqualToString:@"sortOrdering"]) {
    v = [self sortOrderings];
    v = [v objectAtIndex:0];
  }
  else 
    v = [super valueForKey:_key];
  
  return v;
}

@end /* LSGetTeamsForGlobalIDsCommand */

#endif
