/*
  Copyright (C) 2006 Helge Hess

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

@class NSMutableArray, NSMutableDictionary;
@class EODataSource;

@interface OGoCompanyBulkOpPanel : OGoComponent
{
  EODataSource        *dataSource;
  id                  labels;
  NSMutableDictionary *accessIds;
  NSMutableArray      *categories;
  BOOL                isVisible; // out parameter to disable panel by actions

  /* transient */
  id  item;
  int category;
}

@end

#include "common.h"
#include <EOControl/EOKeyGlobalID.h>
#include <OGoContacts/SkyCompanyDocument.h>

@implementation OGoCompanyBulkOpPanel

static BOOL debugOn = NO;

+ (int)version {
  return [super version] + 0 /* v2 */;
}
+ (void)initialize {
  NSAssert2([super version] == 2,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (void)dealloc {
  [self->categories release];
  [self->accessIds  release];
  [self->item       release];
  [self->dataSource release];
  [self->labels     release];
  [super dealloc];
}

/* notifications */

- (void)sleep {
  [self->item   release]; self->item   = nil;
  [self->labels release]; self->labels = nil;
  [super sleep];
}

/* accessors */

- (void)setDataSource:(EODataSource *)_dataSource {
  ASSIGN(self->dataSource, _dataSource);
}
- (EODataSource *)dataSource {
  return self->dataSource;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (void)setLabels:(id)_labels {
  ASSIGN(self->labels, _labels);
}
- (id)labels {
  return self->labels;
}
- (id)ownLabels {
  return [super labels];
}

- (void)setAccessIds:(id)_id {
  ASSIGN(self->accessIds, _id);
}
- (id)accessIds {
  return self->accessIds;
}

- (void)setIsVisible:(BOOL)_flag {
  self->isVisible = _flag;
}
- (BOOL)isVisible {
  return self->isVisible;
}

- (void)setCategory:(int)_value {
  self->category = _value;
}
- (int)category {
  return self->category;
}

- (void)setSelectedCategory:(NSString *)_category {
  if (self->categories == nil)
    self->categories = [[NSMutableArray alloc] initWithCapacity:8];
  
  while (self->category >= [self->categories count])
    [self->categories addObject:@""];

  [self->categories replaceObjectAtIndex:self->category 
                    withObject:_category != nil ? _category : (NSString *)@""];
}
- (NSString *)selectedCategory {
  if (self->category >= [self->categories count])
    return nil;
  
  return [self->categories objectAtIndex:self->category];
}

/* process categories */

- (NSArray *)selectedCategories {
  NSMutableSet *ms;
  unsigned i;
  
  if (![self->categories isNotEmpty])
    return nil;
  
  ms = [NSMutableSet setWithCapacity:[self->categories count]];
  for (i = 0; i < [self->categories count]; i++) {
    if ([[self->categories objectAtIndex:i] isNotEmpty])
      [ms addObject:[self->categories objectAtIndex:i]];
  }
  
  return [[ms allObjects] sortedArrayUsingSelector:@selector(compare:)];
}


/* message */

- (void)reportAffected:(unsigned)_affected failed:(unsigned)_failed {
  NSString *msg;
  
  msg = [NSString stringWithFormat:
		    [[self ownLabels] valueForKey:@"bulk_resultnote_pattern"],
		    _affected, _failed];
  [[[self context] page] setErrorString:msg];
}


/* category actions */

typedef enum {
  OGoCatOpType_Add    = 0,
  OGoCatOpType_Remove = 1,
  OGoCatOpType_Set    = 2
} OGoCatOpType;

static NSString *KeywordSplitString = @", ";

- (NSString *)generateSQLForMap:(NSDictionary *)_map {
  NSMutableString *sql;
  NSEnumerator *e;
  NSString     *kw;
  
  if (![_map isNotEmpty])
    return nil;
  
  sql = [NSMutableString stringWithCapacity:4096];
  
  /* Note: joining SQL using ; is kinda PostgreSQL specific? */
  e = [_map keyEnumerator];
  while ((kw = [e nextObject]) != nil) {
    NSArray  *gids;
    unsigned i, count;
    
    /* not really subject to SQL injection because the keywords are
       specified by the admin? */
    gids = [_map objectForKey:kw];
    kw   = [kw stringByReplacingString:@"'" withString:@"''"];
    
    if ([sql isNotEmpty]) [sql appendString:@"; "];

    [sql appendString:@"UPDATE company SET keywords = '"];
    [sql appendString:kw];
    [sql appendString:@"' WHERE company_id IN ( "];

    for (i = 0, count = [gids count]; i < count; i++) {
      EOKeyGlobalID *gid;
      
      gid = (EOKeyGlobalID *)[gids objectAtIndex:i];
      if (i > 0) [sql appendString:@", "];
      [sql appendString:[[gid keyValues][0] stringValue]];
    }
    [sql appendString:@" )"];
  }
  
  return sql;
}

- (id)applyCategories:(NSArray *)_cats operation:(OGoCatOpType)_optype {
  // TODO: this really belongs into SkyCompanyDocument?
  NSMutableDictionary *kwToGIDs;
  OGoAccessManager *manager;
  NSString *keywords;
  NSArray  *docs;
  NSArray  *gids;
  unsigned i, affected, failCount;
  
  manager   = [[(OGoSession *)[self session] commandContext] accessManager];
  keywords  = [_cats componentsJoinedByString:KeywordSplitString];
  affected  = 0;
  failCount = 0;
  
  docs = [[self dataSource] fetchObjects];
  gids = [docs valueForKey:@"globalID"];
  gids = [manager objects:gids forOperation:@"w"];
  
  kwToGIDs = [NSMutableDictionary dictionaryWithCapacity:256];
  
  for (i = 0; i < [docs count]; i++) {
    SkyCompanyDocument *doc;
    NSMutableArray     *kwGIDs;
    NSString     *oldKeywords, *newKeywords;
    
    doc = [docs objectAtIndex:i];
    
    /* ensure that we have write access */
    if (![gids containsObject:[doc globalID]]) {
      failCount++;
      continue;
    }
    
    /* setup keywords */
    oldKeywords = [doc keywords];
    newKeywords = nil;
    
    switch (_optype) {
      case OGoCatOpType_Set:
	/* Note: empty new keywords are valid here! */
      
	if ([oldKeywords isEqual:keywords]) /* didn't change */
	  continue;
	
	newKeywords = keywords;
	break;

      case OGoCatOpType_Remove:
	if ([oldKeywords isNotEmpty] && [_cats isNotEmpty]) {
	  NSMutableArray *ma;
	  NSArray  *kwo;
	  
	  kwo = [oldKeywords componentsSeparatedByString:KeywordSplitString];
	  ma  = [kwo mutableCopy];
	  [ma removeObjectsInArray:_cats];
	  [ma removeObject:@" "]; /* better be sure (old Sybase thingie) */
	  [ma sortUsingSelector:@selector(compare:)];
	  
	  if ([kwo isEqualToArray:ma]) { /* nothing got removed */
	    /* Note: this (intentionally) fails on reordering due to sorting */
	    [ma release]; ma = nil;
	    continue;
	  }
	  
	  newKeywords = [ma componentsJoinedByString:KeywordSplitString];
	  [ma release]; ma = nil;
	}
	break;
	
      case OGoCatOpType_Add:
	if ([oldKeywords isNotEmpty] && [_cats isNotEmpty]) {
	  NSMutableArray *ma;
	  NSArray  *kwo;
	  unsigned j;
	  
	  kwo = [oldKeywords componentsSeparatedByString:KeywordSplitString];
	  ma  = [kwo mutableCopy];
	  
	  [ma removeObject:@" "]; /* better be sure (old Sybase thingie) */
	  for (j = 0; j < [_cats count]; j++) {
	    if ([ma containsObject:[_cats objectAtIndex:j]])
	      continue;
	    
	    [ma addObject:[_cats objectAtIndex:j]];
	  }
	  [ma sortUsingSelector:@selector(compare:)];
	  
	  if ([kwo isEqualToArray:ma]) { /* nothing got add */
	    /* Note: this (intentionally) fails on reordering due to sorting */
	    [ma release]; ma = nil;
	    continue;
	  }
	  
	  newKeywords = [ma componentsJoinedByString:KeywordSplitString];
	  [ma release]; ma = nil;
	}
	else if ([_cats isNotEmpty]) {
	  /* no categories set, add ours */
	  newKeywords = [_cats componentsJoinedByString:KeywordSplitString];
	}
	break;
    }
    if (![newKeywords isNotEmpty]) newKeywords = @"";
    
    if (debugOn) {
      [self logWithFormat:@"OLD: %@", oldKeywords];
      [self logWithFormat:@"NEW: %@", [doc keywords]];
    }

    /* add to map, prepare for UPDATE ... SET keywords = .. WHERE id IN ... */
    
    if ((kwGIDs = [kwToGIDs objectForKey:newKeywords]) == nil) {
      kwGIDs = [NSMutableArray arrayWithCapacity:64];
      [kwToGIDs setObject:kwGIDs forKey:newKeywords];
    }
    [kwGIDs addObject:[doc globalID]];

    /* also patch document so that we can see the change w/o refetch, its
       kinda hack because we don't save it */
    
    [doc setKeywords:newKeywords];
    if (debugOn) {
      [self logWithFormat:@"OLD: %@", oldKeywords];
      [self logWithFormat:@"NEW: %@", [doc keywords]];
    }

    affected++;
  }
  
  if (debugOn)
    [self logWithFormat:@"MAP: %@", kwToGIDs];
  
  if ([kwToGIDs isNotEmpty]) {
    LSCommandContext *cmdctx;
    EOAdaptorChannel *ch;
    NSException      *error;
    
    cmdctx = [(OGoSession *)[self session] commandContext];
    if (![cmdctx isTransactionInProgress])
      [cmdctx begin];
    
    ch = [[cmdctx valueForKey:LSDatabaseChannelKey] adaptorChannel];
    
    error = [ch evaluateExpressionX:[self generateSQLForMap:kwToGIDs]];
    if (error != nil) {
      [self errorWithFormat:@"could not change categories: %@", error];
      [[[self context] page]
	setErrorString:@"Category changed failed!"]; // TODO: localize
      [cmdctx rollback];
      return nil; /* stay on page */
    }
    
    if (![cmdctx commit]) {
      [self errorWithFormat:@"could not commit changed categories."];
      [[[self context] page]
	setErrorString:@"Category changed failed!"]; // TODO: localize
      [cmdctx rollback];
      return nil; /* stay on page */
    }
  }
  
  /* we are done */
  
  [self reportAffected:affected failed:failCount];
  [self setIsVisible:NO]; /* close bulk panel */
  return nil;             /* stay on page */
}

- (id)addCategories {
  return [self applyCategories:[self selectedCategories] 
	       operation:OGoCatOpType_Add];
}

- (id)removeCategories {
  return [self applyCategories:[self selectedCategories] 
	       operation:OGoCatOpType_Remove];
}

- (id)setCategories {
  return [self applyCategories:[self selectedCategories] 
	       operation:OGoCatOpType_Set];
}


/* permission actions */

- (void)postAccessHasChanged:(NSArray *)_objs {
  NSNotificationCenter *nc;
  unsigned i;
  
  nc = [NSNotificationCenter defaultCenter];
  for (i = 0; i < [_objs count]; i++) {
    [nc postNotificationName:@"SkyAccessHasChangedNotification"
	object:[_objs objectAtIndex:i] userInfo:nil];
  }
}

- (id)setPermissions {
  OGoAccessManager    *manager;
  NSMutableDictionary *acl;
  NSMutableArray      *changedGIDs;
  NSArray             *docs, *gids;
  NSDictionary        *acls;
  unsigned            i, failCount;
  
  manager = [[(OGoSession *)[self session] commandContext] accessManager];

  /* retrieve list of GIDs from the datasource */
  docs = [[self dataSource] fetchObjects];
  gids = [docs valueForKey:@"globalID"];
  
  /* Fetch the (existing) associated ACLs, the keys of the dicts are the
     GIDs fetched above and the values will be dicts where the key is the
     ACL principal and the value is the permission ('r', 'rw').
     Note that the dict does not contains flag-based permissions.
  */
  acls = [manager allowedOperationsForObjectIds:gids];
  
  if (debugOn) {
    [self logWithFormat:@"WORK ON ACLS: %@", acls];
    [self logWithFormat:@"GIDS: %@",         gids];
    [self logWithFormat:@"NEW ACL: %@",      self->accessIds];
  }
  
  failCount   = 0;
  changedGIDs = [NSMutableArray arrayWithCapacity:128];
  acl         = [NSMutableDictionary dictionaryWithCapacity:8];
  
  for (i = 0; i < [gids count]; i++) {
    EOGlobalID   *gid    = [gids objectAtIndex:i];
    NSDictionary *oldACL = [acls objectForKey:gid];

    if ([oldACL isNotEmpty]) {
      /* object has an ACL */
      NSEnumerator *e;
      NSString *s;

      [acl removeAllObjects];
      
      /* first we reset all perms of existing entries */
      
      e = [oldACL keyEnumerator];
      while ((s = [e nextObject]) != nil)
	[acl setObject:@"" /* reset */ forKey:s];
      
      /* next we add the new entries */
      
      [acl addEntriesFromDictionary:self->accessIds];
      
      /* check whether it actually changed ... */
      if ([acl isEqualToDictionary:oldACL])
	continue; /* nothing to do */
    }
    else {
      /* object had no ACL */
      if (![self->accessIds isNotEmpty]) {
	/* had no ACL and empty new ACL provided, nothin' todo */
	continue;
      }
      
      /* object had no ACL and now gets a new one */
      [acl setDictionary:self->accessIds];
    }
    
    /* perform update */
    
    if (debugOn) [self logWithFormat:@"  on %@ apply: %@", gid, acl];
    
    if (![manager setOperations:acl onObjectID:gid])
      failCount++;
    else
      [changedGIDs addObject:gid];
  }
  
  /* post change notifications */
  
  [self postAccessHasChanged:changedGIDs];
  
  /* we are done */

  [self reportAffected:[changedGIDs count] failed:failCount];
  [self setIsVisible:NO]; /* close bulk panel */
  return nil;             /* stay on page */
}

- (id)close {
  [self setIsVisible:NO]; /* close bulk panel */
  return nil;             /* stay on page */
}

@end /* OGoCompanyBulkOpPanel */
