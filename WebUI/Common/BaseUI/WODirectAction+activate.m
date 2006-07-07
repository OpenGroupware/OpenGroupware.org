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

#include "common.h"
#include <LSFoundation/LSFoundation.h>
#include <NGObjWeb/WODirectAction.h>
#include <OGoDocuments/SkyDocuments.h>
#include <OGoDocuments/SkyDocumentManager.h>
#include <OGoDocuments/LSCommandContext+Doc.h>

@implementation WODirectAction(DirectActivation)

- (id)retrieveObject:(id)_oid ofType:(NSString *)_entityName {
  id object = nil;
  
  if ([_entityName isEqualToString:@"Appointment"] ||
      [_entityName isEqualToString:@"Date"]) {
    object = [[self existingSession]
                    runCommand:@"appointment::get", @"dateId", _oid, nil];
  }
  else if ([_entityName isEqualToString:@"Person"]) {
    object = [[self existingSession]
                    runCommand:@"person::get", @"companyId", _oid, nil];
  }
  else if ([_entityName isEqualToString:@"Enterprise"]) {
    object = [[self existingSession]
                    runCommand:@"enterprise::get", @"companyId", _oid, nil];
  }
  
  return object;
}

- (id<WOActionResults>)activateAction {
  OGoSession *sn;
  NSString   *verb, *oid, *type;
  id         object;
  EOGlobalID *gid;
  
  if ((sn = (id)[self existingSession]) == nil) {
    WOComponent *mainPage;
    
    mainPage = [self pageWithName:@"Main"];
    [mainPage takeValue:self        forKey:@"directActionObject"];
    [mainPage takeValue:@"activate" forKey:@"directAction"];
    [self debugWithFormat:@"attaching activate-action to main page ..."];
    return mainPage;
  }
  
  if (![(verb = [[self request] formValueForKey:@"verb"]) isNotEmpty])
    verb = @"view";
  
  if ([(oid = [[self request] formValueForKey:@"oid"]) isNotEmpty]) {
    /* lookup global-id and activate */
    gid = [[[sn commandContext] typeManager] globalIDForPrimaryKey:oid];
    if (gid != nil) {
      WOComponent *page;
      
      page = [[sn navigation] activateObject:gid withVerb:verb];
      return page;
    }
    
    /* no gid could be found .. */
    
    type = [sn runCommand:@"get-object-type", @"oid", oid, nil];
    if (type == nil) {
      [self errorWithFormat:@"could not determine type of objectid: %@", oid];
      return nil;
    }
    
    if ((object = [self retrieveObject:oid ofType:type]) == nil) {
      [self errorWithFormat:
              @"could not get object with id %@ of type %@", oid, type];
      return nil;
    }
    
    return [[sn navigation] activateObject:object withVerb:verb];
  }
  
  if ([(oid = [[self request] formValueForKey:@"url"]) isNotEmpty]) {
    NSURL *url;
    
    url = [NSURL URLWithString:oid
                 relativeToURL:
                   [[[sn commandContext] documentManager] skyrixBaseURL]];
    if (url == nil) {
      [self errorWithFormat:@"could not parse activation URL: '%@'", oid];
      return nil;
    }

    oid = (id)[[[sn commandContext] documentManager] globalIDForURL:url];
    return [[sn navigation] activateObject:oid ? oid : (NSString *)url
			    withVerb:verb];
  }
  
  [self errorWithFormat:@"missing object id in activation-action."];
  return nil;
}

@end /* WODirectAction(DirectActivation) */

@implementation WOContext(DirectActivation)

- (NSString *)activationURLForGlobalID:(EOGlobalID *)_gid
  verb:(NSString *)_verb
  queryDictionary:(NSDictionary *)_queryDict
{
  NSMutableDictionary *qd;
  NSString *url, *oid;

  if (_gid == nil)
    return nil;
  
  if (![_gid isKindOfClass:[EOKeyGlobalID class]]) {
    NSLog(@"%s: unsupported gid: %@", __PRETTY_FUNCTION__, _gid);
    return nil;
  }
  
  qd = _queryDict
    ? [_queryDict mutableCopy]
    : [[NSMutableDictionary alloc] initWithCapacity:4];
  
  if (_verb)
    [qd setObject:_verb forKey:@"verb"];
  
  oid = [[(EOKeyGlobalID *)_gid keyValues][0] stringValue];
  if ([oid length] == 0) {
    NSLog(@"%s: couldn't get oid for gid %@", __PRETTY_FUNCTION__, _gid);
    return nil;
  }
  
  [qd setObject:oid              forKey:@"oid"];
  [qd setObject:[self contextID] forKey:@"cid"];
  
  if ([self hasSession]) {
    WOSession *sn;

    sn = [self session];
    
    [qd setObject:[sn sessionID] forKey:WORequestValueSessionID];

    if (![sn isDistributionEnabled]) {
      [qd setObject:[[WOApplication application] number]
          forKey:WORequestValueInstance];
    }
  }
  
  url = [self directActionURLForActionNamed:@"activate"
              queryDictionary:qd];

  [qd release]; qd = nil;
  
  return url;
}

- (NSString *)activationURLForGlobalID:(EOGlobalID *)_gid
  verb:(NSString *)_verb
{
  return [self activationURLForGlobalID:_gid
               verb:_verb
               queryDictionary:nil];
}

- (NSString *)activationURLForURL:(NSURL *)_url verb:(NSString *)_verb {
  id         ctx;
  EOGlobalID *gid;

  if (_url == nil) return nil;

  if ([_verb isEqualToString:@"view"]) {
    if ([[_url scheme] hasPrefix:@"http"])
      return [_url absoluteString];
    if ([[_url scheme] hasPrefix:@"ftp"])
      return [_url absoluteString];
  }
  
  if ((ctx = [(id)[self session] commandContext]) == nil) {
    NSLog(@"%s: missing context ..", __PRETTY_FUNCTION__);
    return nil;
  }
  
  if ((gid = [[ctx documentManager] globalIDForURL:_url]) == nil)
    return [_url absoluteString];
  
  return [self activationURLForGlobalID:gid verb:_verb];
}

@end /* WOContext(DirectActivation) */
