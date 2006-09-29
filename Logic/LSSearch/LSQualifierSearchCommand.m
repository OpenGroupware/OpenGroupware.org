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

#include "LSQualifierSearchCommand.h"
#include "common.h"
#include <LSSearch/OGoSQLGenerator.h>
#include <EOControl/EOKeyGlobalID.h>

// TODO: add support for fetch specifications?!

@implementation LSQualifierSearchCommand

static BOOL debugOn = NO;

+ (int)version {
  return [super version] /* v1 */;
}
+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSAssert2([super version] == 1,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
  
  if ((debugOn = [ud boolForKey:@"LSDebugQSearch"]))
    NSLog(@"Note: LSDebugQSearch is enabled for %@", NSStringFromClass(self));
}

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
  }
  return self;
}

- (void)dealloc {
  [self->offset         release];
  [self->maxSearchCount release];
  [self->qualifier      release];
  [self->attributes     release];
  [self->sql            release];
  [super dealloc];
}

/* subclasses */

- (NSString *)sqlSelect {
  return nil;
}

- (NSString *)aclOwnerAttributeName {
  return nil;
}
- (NSString *)aclPrivateAttributeName {
  return nil;
}

- (void)addConjoinSQLClausesToArray:(NSMutableArray *)_ands {
}

- (BOOL)fetchWithNoAccessCheck {
  return ([self aclOwnerAttributeName]   != nil ||
	  [self aclPrivateAttributeName] != nil) ? YES : NO;
}

/* qualifier construction */

- (BOOL)excludeArchivedObjects {
  return YES;
}

- (void)_prepareForExecutionInContext:(id)_context {
  OGoSQLGenerator *sqlGen;
  NSMutableString *msql;
  NSMutableArray  *ands;
  NSString        *s;

  [super _prepareForExecutionInContext:_context];

  sqlGen = [[OGoSQLGenerator alloc] initWithAdaptor:[self databaseAdaptor]
				    entityName:[self entityName]];

  ands = [[NSMutableArray  alloc] initWithCapacity:4];
  msql = [[NSMutableString alloc] initWithCapacity:4096];
  
  s = [sqlGen processQualifier:self->qualifier];
  if ([s isNotEmpty]) [ands addObject:s];
  
  [msql appendString:@"SELECT DISTINCT "];
  if (self->fetchCount)
    [msql appendString:@"COUNT(B.*)"];
  else {
    NSString *csql;
    
    if ((csql = [self sqlSelect]) != nil)
      [msql appendString:csql];
    else {
      /* per default we fetch just the primary key */
      // TODO: if we have a fetch specification, possibly use the 'attributes'
      //       from that
      EOAttribute *pkey;
      
      pkey = [[self entity] attributeNamed: [self primaryKeyName]];
      [msql appendString:@"B."];
      [msql appendString:[pkey columnName]];
    }
  }
  [msql appendString:@" FROM "];
  [msql appendString:[sqlGen generateTableList]];

  /* add ACL if configured */
  {
    NSString *o, *p;

    o = [self aclOwnerAttributeName];
    p = [self aclPrivateAttributeName];

    if (o != nil || p != nil) {
      id      account;
      NSArray *teams;
  
      account = [_context valueForKey:LSAccountKey];
#if 1
      /*
	Retrieve the teams of the login account using a separate
	command because they are already cached in the command context.
      */
      teams   = LSRunCommandV(_context, @"account", @"teams", 
			      @"fetchGlobalIDs", [NSNumber numberWithBool:YES],
			      @"account", [account valueForKey:@"globalID"],
			      nil);
#else
      /*
	Retrieve ACL via subselects. It doesn't matter for the performance ...,
	both approaches give almost the same performance.
      */
      teams = nil;
#endif
      
      s = [sqlGen aclClauseWithOwnerAttribute:
		    o != nil 
		    ? [[self entity] attributeNamed:o] : (EOAttribute *)nil
		  privateAttribute:
		    p != nil 
		    ? [[self entity] attributeNamed:p] : (EOAttribute *)nil
		  loginId:account
		  loginTeams:teams];
      if ([s isNotEmpty]) [ands addObject:s];
    }
  }
  
  if ([(s = [sqlGen generateJoinClause]) isNotEmpty])
    [ands addObject:s];

  [self addConjoinSQLClausesToArray:ands];
  
  // TODO: better use EOAttributes here (but should be ok)
  if ([self excludeArchivedObjects])
    [ands addObject:@"B.db_status <> 'archived'"];
  
  if ([ands isNotEmpty]) {
    unsigned i, count;
    
    [msql appendString:@" WHERE "];
    for (i = 0, count = [ands count]; i < count; i++) {
      if (i > 0) [msql appendString:@" AND "];
      
      [msql appendString:@"("];
      [msql appendString:[ands objectAtIndex:i]];
      [msql appendString:@")"];
    }
  }
  
  // TODO: add support for sort orderings
  
  if (!self->fetchCount) {
    if ([self->offset isNotEmpty]) {
      [msql appendString:@" OFFSET "];
      [msql appendString:[self->offset stringValue]];
    }
    if ([self->maxSearchCount isNotEmpty]) {
      [msql appendString:@" LIMIT "];
      [msql appendString:[self->maxSearchCount stringValue]];
    }
  }
  
  self->sql = [msql copy];
  [sqlGen release];
  [msql release];
}

/* command methods */

- (void)_executeInContext:(id)_context {
  // TODO: construct SQL and perform fetch
  EOAdaptorChannel *adChannel;
  NSMutableArray   *result;
  NSException      *error;
  
  if (debugOn)
    [self logWithFormat:@"qsearch SQL: %@", self->sql];
  
  adChannel = [[self databaseChannel] adaptorChannel];
  if ((error = [adChannel evaluateExpressionX:self->sql]) != nil) {
    [self errorWithFormat:@"could not evaluate SQL for qualifier %@: %@",
	    self->qualifier, self->sql];
    [error raise];
  }
  
  result = [NSMutableArray arrayWithCapacity:16];
  if ([adChannel isFetchInProgress]) {
    NSDictionary *r;
    NSArray  *attrs;
    NSString *ename;
    NSString *pkeyName;
    
    ename    = [self entityName];
    pkeyName = [self primaryKeyName];
    
    attrs = [adChannel describeResults];
    while ((r = [adChannel fetchAttributes:attrs withZone:NULL]) != nil) {
      EOKeyGlobalID *gid;
      NSNumber      *pkey;
      
      pkey = [r valueForKey:pkeyName];
      gid  = [EOKeyGlobalID globalIDWithEntityName:ename keys:&pkey keyCount:1
			    zone:NULL];
      [result addObject:gid];
    }
    
    [adChannel cancelFetch];
  }
  
  if (![result isNotEmpty]) {
    /* found no matches */
    if (debugOn) [self logWithFormat:@"found no matches."];
    [self setReturnValue:[NSArray array]];
    return;
  }
  
  /* post processing */
  
  if ([self fetchGlobalIDs]) {
    [self setReturnValue:result];
    if (debugOn) {
      [self logWithFormat:@"  fetching gids/ids, no post-processing: %d ids",
	      [result count]];
    }
    return;
  }
  
  /* fetch EOs or dicts, Note: we possibly have the access check in the SQL */

  if ([self->attributes isNotEmpty]) {
    result = LSRunCommandV(_context, [self domain], @"get-by-globalid",
			   @"gids",          result,
			   @"attributes",    self->attributes,
			   @"noAccessCheck", 
			   [NSNumber numberWithBool:
				       [self fetchWithNoAccessCheck]],
			   nil);
  }
  else {
    result = LSRunCommandV(_context, [self domain], @"get-by-globalid",
			   @"gids",          result,
			   @"noAccessCheck",
			   [NSNumber numberWithBool:
				       [self fetchWithNoAccessCheck]],
			   nil);
  }
  [self setReturnValue:result];
}

/* accessors */

- (void)setQualifier:(id)_q {
  if (![_q isNotNull])
    _q = nil;
  else if ([_q isKindOfClass:[NSString class]])
    _q = [EOQualifier qualifierWithQualifierFormat:_q];
  else if ([_q isKindOfClass:[NSDictionary class]])
    _q = [[[EOQualifier alloc] initWithDictionary:_q] autorelease];
  else if ([_q isKindOfClass:[NSArray class]])
    _q = [[[EOQualifier alloc] initWithArray:_q] autorelease];
  
  ASSIGN(self->qualifier, _q);
}
- (EOQualifier *)qualifier {
  return self->qualifier;
}

- (void)setAttributes:(NSArray *)_attributes {
  // TODO: array of XXX, what is XXX?
  ASSIGN(self->attributes, _attributes);
}
- (NSArray *)attributes {
  return self->attributes;
}

- (void)setFetchGlobalIDs:(BOOL)_flag {
  self->fetchGlobalIDs = _flag;
}
- (BOOL)fetchGlobalIDs {
  return self->fetchGlobalIDs;
}

- (void)setFetchCount:(BOOL)_flag {
  self->fetchCount = _flag;
}
- (BOOL)fetchCount {
  return self->fetchCount;
}

- (void)setMaxSearchCount:(NSNumber *)_value {
  ASSIGNCOPY(self->maxSearchCount, _value);
}
- (NSNumber *)maxSearchCount {
  return self->maxSearchCount;
}

- (void)setOffset:(NSNumber *)_value {
  ASSIGNCOPY(self->offset, _value);
}
- (NSNumber *)offset {
  return self->offset;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"qualifier"])
    [self setQualifier:_value ];
  else if ([_key isEqualToString:@"attributes"])
    [self setAttributes:_value ];
  else if ([_key isEqualToString:@"maxSearchCount"])
    [self setMaxSearchCount:_value];
  else if ([_key isEqualToString:@"offset"])
    [self setOffset:_value];
  else if ([_key isEqualToString:@"fetchGlobalIDs"])
    [self setFetchGlobalIDs:[_value boolValue]];
  else if ([_key isEqualToString:@"fetchCount"])
    [self setFetchCount:[_value boolValue]];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"qualifier"])
    return [self qualifier];

  if ([_key isEqualToString:@"attributes"])
    return [self attributes];
  
  if ([_key isEqualToString:@"fetchGlobalIDs"])
    return [NSNumber numberWithBool:[self fetchGlobalIDs]];
  
  if ([_key isEqualToString:@"fetchCount"])
    return [NSNumber numberWithBool:[self fetchCount]];

  if ([_key isEqualToString:@"maxSearchCount"])
    return [self maxSearchCount];
  if ([_key isEqualToString:@"offset"])
    return [self offset];
  
  return [super valueForKey:_key];
}

@end /* LSQualifierSearchCommand */
