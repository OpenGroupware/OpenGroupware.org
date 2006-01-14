/*
  Copyright (C) 2006 SKYRIX Software AG

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

#include <NGObjWeb/WODirectAction.h>

/*
  OGoFormLetterAction
  
  DirectAction which generates arbitary formletters.
  
  Form parameters:
    ds        - 'person' or 'company'
    companyId - number to generate a companyId= qualifier
    type      - 'formLetter' or 'vCard' (latter is deprecated, former is def.)
*/

@interface OGoFormLetterAction : WODirectAction
@end

#include "common.h"
#include <OGoContacts/SkyAddressConverterDataSource.h>
#include <OGoContacts/SkyPersonDataSource.h>
#include <OGoContacts/SkyEnterpriseDataSource.h>

@interface OGoFormLetterLabelHandler : NSObject
{
@public
  WOResourceManager *resourceManager;
  NSString *tableName;
  NSArray  *langs;
}

@end

@implementation OGoFormLetterAction

/* errors */

- (id<WOActionResults>)missingSessionError {
  [[[self context] response] appendContentString:@"Missing Session"];
  [[[self context] response] setStatus:403 /* Forbidden */]; // TODO: other?
  return [[self context] response];
}
- (id<WOActionResults>)invalidParameterError {
  [[[self context] response] appendContentString:@"Invalid Form Parameter"];
  [[[self context] response] setStatus:403 /* Forbidden */]; // TODO: other?
  return [[self context] response];
}

/* handling */

- (EODataSource *)sourceDataSourceInContext:(LSCommandContext *)_ctx {
  NSString *dsn;
  
  dsn = [[[self context] request] formValueForKey:@"ds"];
  
  if ([dsn isEqualToString:@"person"]) {
    return [(SkyPersonDataSource *)
	     [SkyPersonDataSource alloc] initWithContext:_ctx];
  }
  
  if ([dsn isEqualToString:@"company"]) {
    return [(SkyEnterpriseDataSource *)
	     [SkyEnterpriseDataSource alloc] initWithContext:_ctx];
  }
  
  return nil;
}

- (id)labels {
  OGoFormLetterLabelHandler *lh;
  NSString *tn;
  
  lh = [[[OGoFormLetterLabelHandler alloc] init] autorelease];
  
  lh->resourceManager =
    [[[[self context] application] resourceManager] retain];
  
  tn = [[[self context] request] formValueForKey:@"table"];
  if ([tn isNotEmpty])
    lh->tableName = [tn copy];
  else {
    NSString *dsn;
    
    dsn = [[[self context] request] formValueForKey:@"ds"];
    if ([dsn isEqualToString:@"person"])
      lh->tableName = @"PersonsUI";
    else if ([dsn isEqualToString:@"company"])
      lh->tableName = @"EnterprisesUI";
  }
  
  lh->langs = [[[self existingSession] languages] copy];
  
  return lh;
}

/* main entry */

- (id<WOActionResults>)defaultAction {
  SkyAddressConverterDataSource *ds;
  EODataSource         *sds;
  EOFetchSpecification *fs;
  NSDictionary         *hints;
  WORequest            *rq;
  NSString             *type, *kind;
  id                   result, ctx;
  id tmp;

  rq = [[self context] request];
  
  if ((ctx = [[self existingSession] commandContext]) == nil)
    return [self missingSessionError];
  
  if ((sds = [self sourceDataSourceInContext:ctx]) == nil)
    return [self invalidParameterError];
  
  ds = [[SkyAddressConverterDataSource alloc] 
	 initWithDataSource:sds
	 context:ctx
	 labels:[self labels]];
  [sds release]; sds = nil;
  
  fs    = [[EOFetchSpecification alloc] init];
  
  if ([(tmp = [rq formValueForKey:@"companyId"]) isNotEmpty]) {
    EOQualifier *qual;
    
    qual  = [EOQualifier qualifierWithQualifierFormat:
			   @"companyId = %@", 
			   [NSNumber numberWithInt:[tmp intValue]]];
    [fs setQualifier:qual];
  }
  
  type = [rq formValueForKey:@"format"];
  if (![type isNotEmpty]) type = @"formLetter";
  
  kind = [rq formValueForKey:@"kind"];
  if (![kind isNotEmpty]) 
    kind = [[[self session] userDefaults] objectForKey:@"formletter_kind"];
  
  hints = [[NSDictionary alloc] initWithObjectsAndKeys:
				  kind, @"kind", type, @"type", nil];
  [fs setHints:hints];
  [hints release]; hints = nil;
  
  [ds setFetchSpecification:fs];
  [fs release]; fs = nil;
  
  /* perform fetch */
  
  result = [[[ds fetchObjects] lastObject] retain];
  [ds release]; ds = nil;
  
  return [result autorelease];
}

- (id<WOActionResults>)downloadAction {
  return [self defaultAction];
}

@end /* OGoFormLetterAction */


@implementation OGoFormLetterLabelHandler

- (void)dealloc {
  [self->resourceManager release];
  [self->tableName       release];
  [self->langs           release];
  [super dealloc];
}

/* query */

- (id)valueForKey:(NSString *)_key {
  return [self->resourceManager
	      stringForKey:_key
	      inTableNamed:self->tableName
	      withDefaultValue:_key
	      languages:self->langs];
}

- (id)objectForKey:(id)_key {
  return [self valueForKey:_key];
}

@end /* OGoFormLetterLabelHandler */
