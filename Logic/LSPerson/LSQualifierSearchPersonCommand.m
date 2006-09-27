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

#include <LSFoundation/LSDBObjectBaseCommand.h>

/*
  person::qsearch
  
  TODO: document
*/

@class NSString, NSNumber, NSArray, NSDictionary;
@class EOQualifier;

@interface LSQualifierSearchPersonCommand : LSDBObjectBaseCommand
{
  EOQualifier *qualifier;
  BOOL        withoutAccounts;
  NSArray     *attributes;
  /* you can define groups of attributes to fetch, e.g.
       "telephones" and
       "extendedAttributes"
  */
  NSNumber    *maxSearchCount;
  BOOL        fetchGlobalIDs;

  NSString *sql;
}

- (void)setFetchGlobalIDs:(BOOL)_fetchGlobalIDs;
- (BOOL)fetchGlobalIDs;

@end

#include "common.h"
#include <LSSearch/OGoSQLGenerator.h>

@implementation LSQualifierSearchPersonCommand

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
    self->withoutAccounts = NO;
  }
  return self;
}

- (void)dealloc {
  [self->maxSearchCount release];
  [self->qualifier      release];
  [self->attributes     release];
  [self->sql            release];
  [super dealloc];
}

/* qualifier construction */

- (BOOL)excludeTemplateUsers {
  return YES;
}
- (BOOL)excludeArchivedObjects {
  return YES;
}
- (BOOL)excludeAccounts {
  return self->withoutAccounts;
}

- (void)_prepareForExecutionInContext:(id)_context {
  OGoSQLGenerator *sqlGen;
  NSMutableString *msql;
  NSMutableArray  *ands;
  NSString        *s;
  id              account;
  NSArray         *teams;

  [super _prepareForExecutionInContext:_context];
  
  account = [_context valueForKey:LSAccountKey];
#if 1
  /*
    Retrieve the teams of the login account using a separate
    command because they are already cached in the command context.
  */
  teams   = LSRunCommandV(_context, @"account", @"teams", 
			  @"fetchGlobalIDs", [NSNumber numberWithBool:YES],
			  @"account", [account valueForKey:@"globalID"], nil);
#else
  /*
    Retrieve ACL via subselects. It doesn't matter for the performance ...,
    both approaches give almost the same performance.
  */
  teams = nil;
#endif
  
  sqlGen = [[OGoSQLGenerator alloc] initWithAdaptor:[self databaseAdaptor]
				    entityName:[self entityName]];

  ands = [[NSMutableArray  alloc] initWithCapacity:4];
  msql = [[NSMutableString alloc] initWithCapacity:4096];
  
  s = [sqlGen processQualifier:self->qualifier];
  if ([s isNotEmpty]) [ands addObject:s];
  
  [msql appendString:@"SELECT DISTINCT B."];
  [msql appendString:@"company_id"];
  
  [msql appendString:@" FROM "];
  [msql appendString:[sqlGen generateTableList]];
  
  s = [sqlGen aclClauseWithOwnerAttribute:
		[[self entity] attributeNamed:@"ownerId"]
	      privateAttribute:
		[[self entity] attributeNamed:@"isPrivate"]
	      loginId:account
	      loginTeams:teams];
  if ([s isNotEmpty]) [ands addObject:s];
  
  if ([(s = [sqlGen generateJoinClause]) isNotEmpty])
    [ands addObject:s];
  
  // TODO: better use EOAttributes here (but should be ok)
  if ([self excludeTemplateUsers])
    [ands addObject:@"B.is_template_user IS NULL OR B.is_template_user = 0"];
  if ([self excludeAccounts])
    [ands addObject:@"B.is_account IS NULL OR B.is_account = 0"];
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

  if ([self->maxSearchCount isNotEmpty]) {
    [msql appendString:@" LIMIT "];
    [msql appendString:[self->maxSearchCount stringValue]];
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
  
  // [self logWithFormat:@"RUN SQL: %@", self->sql];
  
  adChannel = [[self databaseChannel] adaptorChannel];
  if ((error = [adChannel evaluateExpressionX:self->sql]) != nil) {
    [self errorWithFormat:@"could not evaluate SQL: %@", self->sql];
    [error raise];
  }
  
  result = [NSMutableArray arrayWithCapacity:16];
  if ([adChannel isFetchInProgress]) {
    NSDictionary *r;
    NSArray *attrs;
    NSString *ename;
    
    ename = [self entityName];
    attrs = [adChannel describeResults];
    while ((r = [adChannel fetchAttributes:attrs withZone:NULL]) != nil) {
      EOKeyGlobalID *gid;
      NSNumber      *pkey;

      pkey = [r valueForKey:@"companyId"];
      gid  = [EOKeyGlobalID globalIDWithEntityName:ename keys:&pkey keyCount:1
			    zone:NULL];
      [result addObject:gid];
    }
    
    [adChannel cancelFetch];
  }
  
  if (![result isNotEmpty]) {
    /* found no matches */
    [self setReturnValue:[NSArray array]];
    return;
  }
  
  /* post processing */
  
  if ([self fetchGlobalIDs]) {
    if (debugOn) 
      [self logWithFormat:@"  fetching gids/ids, no post-processing .."];
    return;
  }
  
  /* fetch person EOs, note: we already have the access check in the SQL */

  if (self->attributes != nil) {
    result = LSRunCommandV(_context, @"person", @"get-by-globalid",
			   @"gids",          result,
			   @"attributes",    self->attributes,
			   @"noAccessCheck", [NSNumber numberWithBool:YES],
			   nil);
  }
  else {
    result = LSRunCommandV(_context, @"person", @"get-by-globalid",
			   @"gids",          result,
			   @"noAccessCheck", [NSNumber numberWithBool:YES],
			   nil);
  }
  [self setReturnValue:result];
}

/* entity */

- (NSString *)entityName {
  return @"Person";
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

- (void)setWithoutAccounts:(BOOL)_b {
  self->withoutAccounts = _b;
}
- (BOOL)withoutAccounts {
  return self->withoutAccounts;
}

- (void)setFetchGlobalIDs:(BOOL)_flag {
  self->fetchGlobalIDs = _flag;
}
- (BOOL)fetchGlobalIDs {
  return self->fetchGlobalIDs;
}

- (void)setMaxSearchCount:(NSNumber *)_maxSearchCount {
  ASSIGN(self->maxSearchCount, _maxSearchCount);
}
- (NSNumber *)maxSearchCount {
  return self->maxSearchCount;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"withoutAccounts"])
    [self setWithoutAccounts:[_value boolValue]];
  else if ([_key isEqualToString:@"qualifier"])
    [self setQualifier:_value ];
  else if ([_key isEqualToString:@"attributes"])
    [self setAttributes:_value ];
  else if ([_key isEqualToString:@"maxSearchCount"])
    [self setMaxSearchCount:_value];
  else if ([_key isEqualToString:@"fetchGlobalIDs"])
    [self setFetchGlobalIDs:[_value boolValue]];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"withoutAccounts"])
    return [NSNumber numberWithBool:[self withoutAccounts]];

  if ([_key isEqualToString:@"qualifier"])
    return [self qualifier];

  if ([_key isEqualToString:@"attributes"])
    return [self attributes];
  
  if ([_key isEqualToString:@"fetchGlobalIDs"])
    return [NSNumber numberWithBool:[self fetchGlobalIDs]];
  
  return [super valueForKey:_key];
}

@end /* LSQualifierSearchPersonCommand */
