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

#include "DirectAction.h"
#include "common.h"
#include <EOControl/EOControl.h>
#include <NGObjWeb/WODirectAction.h>
#include <NGXmlRpc/WODirectAction+XmlRpc.h>
#include "Application.h"
#include "Session.h"
#include <OGoContacts/SkyCompanyDocument.h>

@implementation DirectAction

- (NSString *)xmlrpcComponentNamespace {
  return nil;
}

- (EODataSource *)personDataSource {
  return [(Session *)[self session] personDataSource];
}

- (EODataSource *)enterpriseDataSource {
  return [(Session *)[self session] enterpriseDataSource];
}

- (EODataSource *)accountDataSource {
  return [(Session *)[self session] accountDataSource];
}

- (EODataSource *)appointmentDataSource {
  return [(Session *)[self session] appointmentDataSource];
}

- (EODataSource *)teamDataSource {
  return [(Session *)[self session] teamDataSource];
}

- (EODataSource *)projectDataSource {
  return [(Session *)[self session] projectDataSource];
}

- (id)fileManagerForCode:(NSString *)_code {
  return [(Session *)[self session] fileManagerForCode:_code];
}

- (SkyDocument *)getDocumentByArgument:(id)_arg {
  id<SkyDocumentManager> dm;
  id tmp;

  dm  = [[self commandContext] documentManager];
  tmp = _arg;
  
  if ([tmp isKindOfClass:[NSDictionary class]])
    tmp = [tmp valueForKey:@"id"];
  
  return [dm documentForURL:tmp];
}

- (id)getDocumentById:(id)_arg
  dataSource:(EODataSource *)_dataSource
  entityName:(NSString *)_entityName
  attributes:(NSArray *)_attributes
{
  id                   gids          = nil;
  EOQualifier          *qual         = nil;
  EOFetchSpecification *fSpec        = nil;
  BOOL                 doReturnArray = NO;
  NSArray              *returnElements;
  id                   object;
  NSEnumerator         *enumerator;
  EOGlobalID           *gid;

  if (_arg == nil) return nil;

  doReturnArray = [_arg isKindOfClass:[NSArray class]];
  
  gids = (doReturnArray)
    ? _arg
    : [NSArray arrayWithObject:_arg];
  
  while ([gids containsObject:@""]) {
    gids = [[gids mutableCopy] autorelease];
    [gids removeObject:@""];
  }

  /* fetch GIDs for URLs */
  
  gids = [[[self commandContext] documentManager] globalIDsForURLs:gids];

  /* check GID validity */
  
  if ([gids count] == 0) {
    [self logWithFormat:@"Invalid URLs given, could not resolve globalIDs"];
    return nil;
  }
  if ([gids containsObject:[NSNull null]]) {
    [self logWithFormat:@"some URLs could not be resolved to globalIDs."];
    return nil;
  }
  
  gid = [gids objectAtIndex:0];
  if (![[gid entityName] isEqualToString:_entityName]) {
    [self logWithFormat:
            @"ERROR: gid entity '%@' does not match given entity '%@': %@",
            [gid entityName], _entityName, gid];
    return nil;
  }
  
  if (![gid isKindOfClass:[EOGlobalID class]]) {
    [self logWithFormat:@"Invalid URLs given, could not resolve globalIDs: %@",
	    gid];
    return nil;
  }
  
  /* setup fetch specification */

  qual  = [[EOKeyValueQualifier alloc]
                                initWithKey:@"globalID"
                                operatorSelector:EOQualifierOperatorContains
                                value:gids];
  fSpec = [EOFetchSpecification fetchSpecificationWithEntityName:_entityName
				qualifier:qual sortOrderings:nil];
  [qual release]; qual = nil;
      
  if ([_attributes isKindOfClass:[NSArray class]]) {
    NSMutableDictionary *hints;

    hints = [NSMutableDictionary dictionaryWithDictionary:[fSpec hints]];
    [hints setObject:_attributes forKey:@"attributes"];
    [fSpec setHints:hints];
  }
      
  {
    NSMutableDictionary *hints;

    hints = [[NSMutableDictionary alloc] initWithDictionary:[fSpec hints]];
    if ([hints objectForKey:@"addDocumentsAsObserver"] == nil) {
      [hints setObject:[NSNumber numberWithBool:NO]
	     forKey:@"addDocumentsAsObserver"];
      [fSpec setHints:hints];
    }
    [hints release]; hints = nil;
  }
  
  [_dataSource setFetchSpecification:fSpec];

  /* perform fetch */
  
  returnElements = [_dataSource fetchObjects];
  
  enumerator = [returnElements objectEnumerator];
  while ((object = [enumerator nextObject]) != nil) {
    NSDictionary *logEntry;

    logEntry = [[self commandContext] runCommand:
					@"object::get-current-log",
                                        @"object", [object globalID], nil];

    if ([object respondsToSelector:@selector(setExtendedAttribute:forKey:)]) {
      NSCalendarDate *creationDate;
          
      if ((creationDate = [logEntry valueForKey:@"creationDate"]) != nil) {
	[(SkyCompanyDocument *)object setExtendedAttribute:creationDate
			       forKey:@"lastChanged"];
      }
    }
  }
  
  return (doReturnArray) ? returnElements : [returnElements lastObject];
}

- (LSCommandContext *)_commandContextForAuth:(NSString *)_cred
  inContext:(WOContext *)_ctx
{
  NSAutoreleasePool *p;
  NSString *login = nil;
  NSString *pwd   = nil;
  id       lso    = nil;
  id       ctx    = nil;

  p = [[NSAutoreleasePool alloc] init];
  {
    NSRange r;
    
    r = [_cred rangeOfString:@" " options:NSBackwardsSearch];
    if (r.length == 0) {
      /* invalid _cred */
      NSLog(@"%s: invalid 'authorization' header", __PRETTY_FUNCTION__);
      [p release];
      return nil;
    }
    
    _cred = [_cred substringFromIndex:(r.location + r.length)];
    _cred = [_cred stringByDecodingBase64];
    r     = [_cred rangeOfString:@":"];
    login = [_cred substringToIndex:r.location];
    pwd   = [_cred substringFromIndex:r.location + r.length];
  }
  lso = [OGoContextManager defaultManager];
  ctx = [[LSCommandContext alloc] initWithManager:lso];
  login = [login copy];
  pwd   = [pwd   copy];
  [p release]; p = nil;
  
  if ([(LSCommandContext *)ctx login:login password:pwd] == NO) {
    NSLog(@"%s: login %@ was not authorized !", __PRETTY_FUNCTION__, login);
    [login release];
    [pwd   release];
    [ctx   release];
    return nil;
  }
  [login release];
  [pwd   release];
  return [ctx autorelease];
}

- (LSCommandContext *)commandContext {
  return [(Session *)[self session] commandContext];
}

/* actions */

- (id<WOActionResults>)_notAuthenticated {
  WOResponse *resp;
    
  resp = [(WOResponse *)[WOResponse alloc] initWithRequest:[self request]];
  [resp setStatus:401 /* unauthorized */];
  [resp setHeader:@"basic realm=\"SKYRiX\"" forKey:@"www-authenticate"];
  
  return resp;
}

- (id<WOActionResults>)_commitFailed {
  WOResponse *resp;
    
  resp = [(WOResponse *)[WOResponse alloc] initWithRequest:[self request]];
  [resp setStatus:500 /* server error */];
  [resp appendContentString:@"tx commit failed ..."];
  
  return resp;
}

- (id<WOActionResults>)RPC2Action {
  Application      *app;
  WORequest        *req;
  NSString         *cred;
  LSCommandContext *ctx     = nil;
  Session          *session = nil;
  id               result   = nil;

  app  = (Application *)[WOApplication application];
  req  = [self request];
  cred = [req headerForKey:@"authorization"];
  
  if ([cred length] == 0) return [self _notAuthenticated];
  
  [app setCredentials:cred]; // is needed for creating the session
  
  session = (Session *)[self session];
  if ((ctx = [session commandContext]) == nil) {
    ctx = [self _commandContextForAuth:cred inContext:context];
    if (ctx)
      [(Session*)session setCommandContext:ctx];
  }
  
  [app setCredentials:nil];
  
  if (ctx == nil)
    return [self _notAuthenticated];

  result = [super RPC2Action];

  if (ctx) {
    if ([ctx isTransactionInProgress]) {
      if (![ctx commit]) {
        [self logWithFormat:@"couldn't commit transaction ..."];
        return [self _commitFailed];
      }
    }
  }
  
  return result;
}

- (id)defaultAction {
  return [self RPC2Action];
}

- (NSDictionary *)_dictionaryForEOGenericRecord:(id)_record
  withKeys:(NSArray *)_keys
{
  NSMutableDictionary *result;
  NSURL *url;
  NSMutableArray *keys;

  static NSArray* docKeys = nil;
  if (docKeys == nil)
    docKeys = [[NSArray alloc] initWithObjects:@"objectVersion",nil];

  keys = [docKeys mutableCopy];
  [keys addObjectsFromArray:_keys];

  result = [[_record valuesForKeys:keys] mutableCopy];

  if ([[result valueForKey:@"objectVersion"] intValue] == 0)
    [result takeValue:[NSNumber numberWithInt:1] forKey:@"objectVersion"];
  
  url = [[[self commandContext] documentManager] urlForGlobalID:
                                                 [_record globalID]];
  [result takeValue:url forKey:@"id"];
  [keys release];
  return [result autorelease];
}

- (void)substituteIdsWithURLsInDictionary:(NSMutableDictionary *)_dict
  forKeys:(NSArray *)_keys
{
  LSCommandContext *ctx;

  if ((ctx = [self commandContext]) != nil) {
    NSString *baseUrl;
    NSEnumerator *keyEnum;
    NSString *key;
    NSNumber *tmp;

    baseUrl = [[[ctx documentManager] skyrixBaseURL] absoluteString];
    
    keyEnum = [_keys objectEnumerator];
    while ((key = [keyEnum nextObject])) {
      if ((tmp = [_dict valueForKey:key]) != nil)
        [_dict takeValue:[baseUrl stringByAppendingPathComponent:
                                    [tmp stringValue]] forKey:key];
    }
  }
}

- (BOOL)isCurrentUserRoot {
  NSNumber *login;

  login = [[[self commandContext] valueForKey:LSAccountKey]
                  valueForKey:@"companyId"];
  
  return ([login isEqualToNumber:[NSNumber numberWithInt:10000]]);
}

@end /* DirectAction */

#include <OGoContacts/SkyAddressDocument.h>
#include <OGoContacts/SkyCompanyDocument.h>
#include "NSObject+EKVC.h"

@implementation DirectAction(Addresses)
- (void)_takeValuesDict:(NSDictionary *)_from
              toAddress:(SkyAddressDocument *)_addr
{
  [_addr takeValuesFromObject:_from
         keys:@"name1",
              @"name2",
              @"name3",
              @"street",
              @"city",
              @"zip",
              @"state",
              @"country",
         nil];
}

- (void)saveAddresses:(NSDictionary *)_addrs
              company:(SkyCompanyDocument *)_company {
  EODataSource *addressDS;

  if (_addrs == nil) return;
  addressDS = [_company addressDataSource];
  if (addressDS == nil) {
    NSLog(@"Warning(%s): Couldn't find addressDataSource for company (%@)",
          __PRETTY_FUNCTION__,
          _company);
    return;
  }
  else {
    NSEnumerator *addrDocEnum = [[addressDS fetchObjects] objectEnumerator];
    id           addrDoc;

    while ((addrDoc = [addrDocEnum nextObject])) {
      NSString     *type;
      NSDictionary *addrDict;

      type = [addrDoc type];
      if (type == nil) continue;
      addrDict = [_addrs valueForKey:type];
      if (addrDict == nil) continue;
      [self _takeValuesDict:addrDict toAddress:addrDoc];
      [addressDS updateObject:addrDoc];
    }
  }
}
@end /* DirectAction(Addresses) */
